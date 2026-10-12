local shujuan = fk.CreateSkill {
  name = "heg__shujuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["heg__shujuan"] = "舒卷",
  [":heg__shujuan"] = "锁定技，当每回合【戢鳞潜翼】首次置入弃牌堆或其他角色装备区后，你获得并使用之。",

  ["$heg__shujuan1"] = "戢鳞潜翼，蓄志待时。",
  ["$heg__shujuan2"] = "坐观潮起潮落，笑谈云卷云舒。",
}

shujuan:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(shujuan.name) or player:usedSkillTimes(shujuan.name, Player.HistoryTurn) > 0 then return false end
    for _, move in ipairs(data) do
      if move.to ~= player and (move.toArea == Card.PlayerEquip or move.toArea == Card.DiscardPile) then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "scaly_wings" then
          return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.to ~= player and (move.toArea == Card.PlayerEquip or move.toArea == Card.DiscardPile) then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "scaly_wings" then
            table.insert(ids, info.cardId)
          end
        end
      end
    end
    player.room:obtainCard(player, ids, true, fk.ReasonPrey)
    local cards = table.filter(player:getCardIds("h"), function(id)
      return not player:prohibitUse(Fk:getCardById(id)) and Fk:getCardById(id).name == "scaly_wings"
    end)
    if #cards == 0 or player.dead then return end
    player.room:useCard {
      from = player,
      tos = { player },
      card = Fk:getCardById(cards[1]),
    }
  end,
})

return shujuan
