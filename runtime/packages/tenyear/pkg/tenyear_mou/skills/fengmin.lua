local fengmin = fk.CreateSkill {
  name = "fengmin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fengmin"] = "丰愍",
  [":fengmin"] = "锁定技，每回合限一次，当一名角色失去其装备区里的牌后，你摸其装备区空位数的牌。",

  ["$fengmin1"] = "今至绝地，何存偷生之心。",
  ["$fengmin2"] = "我曹子脩，岂是贪生怕死之人！",
}

fengmin:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  times = function (_, player)
    return 1 - player:usedSkillTimes(fengmin.name, Player.HistoryTurn)
  end,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fengmin.name) and player:usedSkillTimes(fengmin.name) == 0 then
      for _, move in ipairs(data) do
        if move.from then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and move.from:hasEmptyEquipSlot() then
              event:setCostData(self, { from = move.from })
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local from = event:getCostData(self).from
    local n = 0
    for _, sub_type in ipairs({ 3, 4, 5, 6, 7 }) do
      n = n + #from:getAvailableEquipSlots(sub_type) - #from:getEquipments(sub_type)
    end
    player:drawCards(n, fengmin.name)
  end,
})

return fengmin
