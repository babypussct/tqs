
local wuqian = fk.CreateSkill {
  name = "mobile__wuqian",
  related_skills = { "wushuang" },
}

Fk:loadTranslationTable{
  ["mobile__wuqian"] = "无前",
  [":mobile__wuqian"] = "出牌阶段，你可以移除2个“暴怒”，令一名角色防具牌失效且你获得〖无双〗，直至你下次使用伤害牌但未造成伤害。"..
  "你的出牌阶段使用【杀】次数+X（X为当前被“无前”的角色数）；结束阶段，你随机获得伤害牌，直至手牌中伤害牌数为X。",

  ["@@mobile__wuqian"] = "无前",
  ["#mobile__wuqian"] = "无前：移除2枚暴怒，令一名角色的防具无效，且你获得“无双”",

  ["$mobile__wuqian1"] = "天王老子也保不住你啦！",
  ["$mobile__wuqian2"] = "看我神威，无坚不摧！",
}

wuqian:addEffect("active", {
  anim_type = "offensive",
  prompt = "#wuqian",
  can_use = function(self, player)
    return player:getMark("@baonu") > 1
  end,
  card_num = 0,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected < 1 and to_select ~= player and to_select:getMark("@@mobile__wuqian") == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:removePlayerMark(player, "@baonu", 2)
    room:addPlayerMark(target, "@@mobile__wuqian")
    room:handleAddLoseSkills(player, "wushuang")
    room:addPlayerMark(target, MarkEnum.MarkArmorNullified)
    room:addTableMark(player, wuqian.name, target)
  end
})

wuqian:addEffect("targetmod", {
  residue_func = function (self, player, skill, scope, card, to)
    if player:hasSkill(wuqian.name) and card and card.trueName == "slash" then
      return #table.filter(Fk:currentRoom().alive_players, function (p)
        return p:getMark("@@mobile__wuqian") > 0
      end)
    end
  end,
})

wuqian:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(wuqian.name) and player.phase == Player.Finish and
      #table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).is_damage_card
      end) <
      #table.filter(player.room.alive_players, function (p)
        return p:getMark("@@mobile__wuqian") > 0
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = #table.filter(room.alive_players, function (p)
        return p:getMark("@@mobile__wuqian") > 0
      end) -
      #table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).is_damage_card
      end)
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      if Fk:getCardById(id).is_damage_card then
        table.insert(cards, id)
        if #cards == n then
          break
        end
      end
    end
    if #cards < n then
      for _, id in ipairs(room.discard_pile) do
        if Fk:getCardById(id).is_damage_card then
          table.insert(cards, id)
          if #cards == n then
            break
          end
        end
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, wuqian.name, nil, false, player)
    end
  end,
})

wuqian:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(wuqian.name) ~= 0 and
      data.card.is_damage_card and not data.damageDealt
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-wushuang")
    for _, p in ipairs(player:getTableMark(wuqian.name)) do
      if p:getMark("@@mobile__wuqian") > 0 then
        room:removePlayerMark(p, "@@mobile__wuqian")
        room:removePlayerMark(p, MarkEnum.MarkArmorNullified)
      end
    end
  end,
})

return wuqian
