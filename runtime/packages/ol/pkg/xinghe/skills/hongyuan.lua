local hongyuan = fk.CreateSkill{
  name = "ol__hongyuan",
}

Fk:loadTranslationTable{
  ["ol__hongyuan"] = "弘援",
  [":ol__hongyuan"] = "每阶段限一次，当你一次得到至少两张牌后，你可以依次交给至多两名其他角色各一张牌。",

  ["#ol__hongyuan-give"] = "弘援：你可以将一张牌交给一名角色",

  ["$ol__hongyuan1"] = "吾已料有所困，援兵不久必至。",
  ["$ol__hongyuan2"] = "恪守信义，方为上策。",
}

hongyuan:addEffect(fk.AfterCardsMove, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(hongyuan.name) and not player:isNude() and
      player:usedSkillTimes(hongyuan.name, Player.HistoryPhase) == 0 and
      #player.room:getOtherPlayers(player, false) > 0 then
      local phase_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
      if phase_event == nil then return end
      local x = 0
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          x = x + #move.moveInfo
        end
      end
      return x > 1
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = room:getOtherPlayers(player, false)
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = hongyuan.name,
      prompt = "#ol__hongyuan-give",
      cancelable = true,
      no_indicate = true
    })
    if #tos > 0 and #cards > 0 then
      event:setCostData(self, { tos = tos, cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards ---@type integer[]
    local tos = event:getCostData(self).tos ---@type ServerPlayer[]
    room:obtainCard(tos[1], cards, false, fk.ReasonGive, player, hongyuan.name)
    if player.dead or player:isNude() then return end
    local targets = room:getOtherPlayers(player, false)
    table.removeOne(targets, tos[1])
    if #targets == 0 then return end
    tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = hongyuan.name,
      prompt = "#ol__hongyuan-give",
      cancelable = true,
      no_indicate = true
    })
    if #tos > 0 and #cards > 0 then
      room:obtainCard(tos[1], cards, false, fk.ReasonGive, player, hongyuan.name)
    end
  end,
})

return hongyuan
