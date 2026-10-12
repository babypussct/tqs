local dingfa = fk.CreateSkill {
  name = "mobile__dingfa",
}

Fk:loadTranslationTable{
  ["mobile__dingfa"] = "定法",
  [":mobile__dingfa"] = "弃牌阶段结束时，若本回合你失去的牌数不小于4，你可以选择一项：1.回复1点体力；2.弃置一名角色至多两张牌。",

  ["mobile__dingfa_throw"] = "弃置一名角色至多两张牌",
  ["#mobile__dingfa-choose"] = "定法：选择一名角色，弃置其至多两张牌",

  ["$mobile__dingfa1"] = "峻礼教之防，准五服以制罪。",
  ["$mobile__dingfa2"] = "礼律并重，臧善否恶，宽简弼国。",
}

dingfa:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(dingfa.name) and player.phase == Player.Discard then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                n = n + 1
              end
            end
          end
        end
      end, Player.HistoryTurn)
      if n > 3 then
        return player:isWounded() or
          table.find(player.room.alive_players, function (p)
            return not p:isNude()
          end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    if table.find(player.room.alive_players, function (p)
      return not p:isNude()
    end) then
      table.insert(choices, 1, "mobile__dingfa_throw")
    end
    if player:isWounded() then
      table.insert(choices, 1, "recover")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = dingfa.name,
      all_choices = {
        "recover",
        "mobile__dingfa_throw",
        "Cancel",
      }})
    if choice == "Cancel" then return end
    if choice == "recover" then
      event:setCostData(self, {choice = "recover"})
      return true
    else
      local targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
      if table.find(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id)
      end) then
        table.insert(targets, player)
      end
      if #targets == 0 then
        room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = dingfa.name,
          pattern = "false",
          prompt = "#mobile__dingfa-choose",
          cancelable = true,
        })
      else
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = dingfa.name,
          prompt = "#mobile__dingfa-choose",
          cancelable = true,
        })
        if #to > 0 then
          event:setCostData(self, {tos = to, choice = "discard"})
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == "recover" then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = dingfa.name,
      }
    else
      local to = event:getCostData(self).tos[1]
      if to == player then
        room:askToDiscard(player, {
          min_num = 1,
          max_num = 2,
          include_equip = true,
          skill_name = dingfa.name,
          cancelable = false,
        })
      else
        local cards = room:askToChooseCards(player, {
          min = 1,
          max = 2,
          target = to,
          flag = "he",
          skill_name = dingfa.name,
        })
        room:throwCard(cards, dingfa.name, to, player)
      end
    end
  end,
})

return dingfa
