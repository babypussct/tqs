
local caiyun = fk.CreateSkill{
  name = "caiyun",
}

Fk:loadTranslationTable{
  ["caiyun"] = "才韵",
  [":caiyun"] = "出牌阶段限一次，你可以选择一名其他角色并与其各从牌堆随机获得一张指定类型的牌，然后直到你的下个回合开始，"..
  "你与其使用该类型的牌时，从牌堆随机获得两张与使用的牌类型不同的牌（每人至多两次）。",

  ["#caiyun"] = "才韵：与一名角色各从牌堆获得一张你指定类型的牌",

  ["$caiyun1"] = "",
  ["$caiyun2"] = "",
}

caiyun:addEffect("active", {
  anim_type = "support",
  prompt = "#caiyun",
  card_num = 0,
  target_num = 1,
  interaction = UI.ComboBox { choices = { "basic", "trick", "equip" } },
  can_use = function(self, player)
    return player:usedSkillTimes(caiyun.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    for _, p in ipairs({ player, target }) do
      local card = room:getCardsFromPileByRule(".|.|.|.|.|"..self.interaction.data)
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonJustMove, caiyun.name, nil, false, p)
      end
    end
    if not player.dead then
      room:addTableMark(player, caiyun.name, { self.interaction.data, { player, player, target, target } })
    end
  end,
})

caiyun:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(caiyun.name) and not target.dead then
      for _, dat in ipairs(player:getTableMark(caiyun.name)) do
        if data.card:getTypeString() == dat[1] and table.contains(dat[2], target) then
          return true
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark(caiyun.name)
    for i = 1, #mark do
      local dat = mark[i]
      if data.card:getTypeString() == dat[1] and table.removeOne(dat[2], target) then
        mark[i] = dat
        room:setPlayerMark(player, caiyun.name, mark)
        local cards = {}
        for _, id in ipairs(room.draw_pile) do
          local str = Fk:getCardById(id):getTypeString()
          if str ~= dat[1] then
            cards[str] = cards[str] or {}
            table.insert(cards[str], id)
          end
        end
        if next(cards) then
          local ids = {}
          for _, v in pairs(cards) do
            table.insert(ids, room:tableRandomPick(v))
          end
          room:moveCardTo(ids, Card.PlayerHand, target, fk.ReasonJustMove, caiyun.name, nil, false, target)
          if not player:hasSkill(caiyun.name) then return end
        end
      end
    end
  end,
})

caiyun:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, caiyun.name, 0)
  end,
})

return caiyun
