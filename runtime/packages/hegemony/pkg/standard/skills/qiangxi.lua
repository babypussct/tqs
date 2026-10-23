
local qiangxi = fk.CreateSkill{
  name = "hs__qiangxi",
}
qiangxi:addEffect("active", {
  anim_type = "offensive",
  max_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if #effect.cards > 0 then
      room:throwCard(effect.cards, self.name, player)
    else
      room:loseHp(player, 1, self.name)
    end
    if target:isAlive() then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
})

Fk:loadTranslationTable{
  ["hs__qiangxi"] = "强袭",
  [":hs__qiangxi"] = "出牌阶段限一次，你可以失去1点体力或弃置一张武器牌，并选择一名其他角色，对其造成1点伤害。",

  ["$hs__qiangxi1"] = "吃我一戟！",
  ["$hs__qiangxi2"] = "看我三步之内取你小命！",
}

-- Prefer a confirmed enemy and compare the two legal costs: one HP or one
-- weapon. Unknown seats are not attacked merely because they are selectable;
-- faction inference must provide enough evidence first.
qiangxi:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local player = ai.player
    local weapons = table.filter(ai:getEnabledCards(), function(id)
      local card = Fk:getCardById(id)
      return card and card.sub_type == Card.SubtypeWeapon and
        not player:prohibitDiscard(card)
    end)
    local best_ret, best_benefit = nil, -100000

    for _, target in ipairs(ai:getEnabledTargets()) do
      local relation = ai:getFactionRelation(target)
      local targetable = relation.state == "enemy" or
        (relation.state == "unknown" and relation.confidence >= 0.65 and relation.attitude < -0.25)
      if targetable then
        if player.hp > 1 then
          local benefit = ai:getBenefitOfEvents(function(logic)
            logic:loseHp(player, 1, self.skill_name)
            logic:damage({ from = player, to = target, damage = 1, skillName = self.skill_name })
          end)
          if benefit > best_benefit then
            best_ret, best_benefit = { {}, { target } }, benefit
          end
        end

        for _, id in ipairs(weapons) do
          local benefit = ai:getBenefitOfEvents(function(logic)
            logic:throwCard({ id }, self.skill_name, player, player)
            logic:damage({ from = player, to = target, damage = 1, skillName = self.skill_name })
          end)
          if benefit > best_benefit then
            best_ret, best_benefit = { { id }, { target } }, benefit
          end
        end
      end
    end

    if best_ret and best_benefit > 0 then
      return best_ret, best_benefit
    end
  end,
})

return qiangxi
