local zhijie = fk.CreateSkill{
  name = "zhijie",
}

Fk:loadTranslationTable{
  ["zhijie"] = "智诫",
  [":zhijie"] = "每轮限一次，一名角色的出牌阶段开始时，你可以展示其一张手牌。"..
  "当其于此阶段内使用与此牌类别相同的牌后，其摸一张牌并弃置X张牌（X为此效果发动的次数-1）；"..
  "此阶段结束时，若其于此阶段内以此法摸牌的数量大于以此法弃置牌的数量，你与其各摸一张牌。",

  ["#zhijie-invoke"] = "智诫：你可以展示 %dest 的一张手牌，其本阶段使用同类别牌时将摸牌并弃牌",
  ["@zhijie-phase"] = "智诫",

  ["$zhijie1"] = "昔子罕不以玉为宝，《春秋》美之。",
  ["$zhijie2"] = "今吴、魏未灭，安以妖玩继怀？",
}

zhijie:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(zhijie.name) and target.phase == Player.Play and
      player:usedEffectTimes(zhijie.name, Player.HistoryRound) == 0 and
      not (target.dead or target:isKongcheng())
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhijie.name,
      prompt = "#zhijie-invoke::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = zhijie.name,
    })
    local type = Fk:getCardById(card):getTypeString()
    target:showCards(card)
    if not target.dead then
      room:setPlayerMark(target, "@zhijie-phase", {type.."_char", 0})
    end
  end,
})
zhijie:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player:getMark("@zhijie-phase") ~= 0 and
      data.card:getTypeString().."_char" == player:getMark("@zhijie-phase")[1]
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@zhijie-phase")
    local x = mark[2]
    mark[2] = x + 1
    room:setPlayerMark(player, "@zhijie-phase", mark)
    player:drawCards(1, zhijie.name)
    if not player.dead and x > 0 then
      local cards = room:askToDiscard(player, {
        min_num = x,
        max_num = x,
        include_equip = true,
        skill_name = zhijie.name,
        cancelable = false,
      })
      if #cards > 0 and not player.dead then
        room:addPlayerMark(player, "zhijie_discard-phase", #cards)
      end
    end
  end,
})
zhijie:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(zhijie.name) and player:usedEffectTimes(zhijie.name, Player.HistoryPhase) > 0 and
      target:getMark("@zhijie-phase") ~= 0 and target:getMark("@zhijie-phase")[2] > target:getMark("zhijie_discard-phase")
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, zhijie.name)
    if not target.dead then
      target:drawCards(1, zhijie.name)
    end
  end,
})

return zhijie
