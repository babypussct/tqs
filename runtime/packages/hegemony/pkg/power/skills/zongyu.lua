local zongyu = fk.CreateSkill {
  name = "zongyu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["zongyu"] = "总御",
  [":zongyu"] = "锁定技，①当你使用坐骑牌时，若其他角色的装备区内或弃牌堆内有【六龙骖驾】，你将原坐骑牌置入弃牌堆，将【六龙骖驾】置入你的装备区内；" ..
      "②当【六龙骖驾】移动至其他角色的装备区内后，你可交换你与其装备区内的防御坐骑牌。",

  ["#zongyu-ask"] = "总御：是否交换你与其装备区内的所有防御坐骑牌",

  ["$zongyu1"] = "驾六龙，乘风而行。行四海，路下之八邦。",
  ["$zongyu2"] = "齐桓之功，为霸之首，九合诸侯，一匡天下。",
}

zongyu:addEffect(fk.CardUsing, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(zongyu.name) then return false end
    if (data.card.sub_type == Card.SubtypeOffensiveRide or data.card.sub_type == Card.SubtypeDefensiveRide) and data.card.name ~= "liulongcanjia" and target == player then
      if #player.room:getCardsFromPileByRule("liulongcanjia", 1, "discardPile") > 0 then return true end
      return table.find(Fk:currentRoom().alive_players, function(p)
        return not not (p ~= player and table.find(p:getEquipments(Card.SubtypeDefensiveRide), function(cid) return
          Fk:getCardById(cid).name == "liulongcanjia" end))
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to_throw = { data.card.id }
    if player:getEquipment(Card.SubtypeDefensiveRide) then
      table.insert(to_throw, player:getEquipment(Card.SubtypeDefensiveRide))
    end
    if player:getEquipment(Card.SubtypeOffensiveRide) then
      table.insert(to_throw, player:getEquipment(Card.SubtypeOffensiveRide))
    end
    room:moveCardTo(to_throw, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, zongyu.name, nil, true, player)
    local card = room:getCardsFromPileByRule("liulongcanjia", 1, "discardPile")
    if #card == 0 then
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        for _, cid in ipairs(p:getEquipments(Card.SubtypeDefensiveRide)) do
          if Fk:getCardById(cid).name == "liulongcanjia" then
            card = { cid }
            break
          end
        end
        if #card > 0 then break end
      end
    end
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerEquip, player, fk.ReasonJustMove, zongyu.name)
    end
  end,
})

zongyu:addEffect(fk.AfterCardsMove, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(zongyu.name) then return false end
    for _, move in ipairs(data) do
      if move.to ~= player and move.toArea == Card.PlayerEquip then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "liulongcanjia" then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = zongyu.name, prompt = "#zongyu-ask" })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to ~= player and move.toArea == Card.PlayerEquip then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "liulongcanjia" then
            local cards1 = { player:getEquipment(Fk:getCardById(info.cardId).sub_type) }
            local cards2 = { info.cardId }
            local move1 = {
              from = player,
              ids = cards1,
              toArea = Card.Processing,
              moveReason = fk.ReasonJustMove,
              proposer = player,
              skillName = zongyu.name,
            }
            local move2 = {
              from = move.to,
              ids = cards2,
              toArea = Card.Processing,
              moveReason = fk.ReasonJustMove,
              proposer = player,
              skillName = zongyu.name,
            }
            room:moveCards(move1, move2)
            local move3 = {
              ids = table.filter(cards1, function(id) return room:getCardArea(id) == Card.Processing end),
              fromArea = Card.Processing,
              to = move.to,
              toArea = Card.PlayerEquip,
              moveReason = fk.ReasonJustMove,
              proposer = player,
              skillName = zongyu.name,
            }
            local move4 = {
              ids = table.filter(cards2, function(id) return room:getCardArea(id) == Card.Processing end),
              fromArea = Card.Processing,
              to = player,
              toArea = Card.PlayerEquip,
              moveReason = fk.ReasonJustMove,
              proposer = player,
              skillName = zongyu.name,
            }
            room:moveCards(move3, move4)
            break
          end
        end
      end
    end
  end,
})

return zongyu
