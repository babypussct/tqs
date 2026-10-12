local peaceSpellSkill = fk.CreateSkill{
  name = "#peace_spell_skill",
  tags = {Skill.Compulsory},
  attached_equip = "peace_spell",
}
local H = require "packages.hegemony.util"
peaceSpellSkill:addEffect(fk.DetermineDamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(peaceSpellSkill.name) and data.damageType ~= fk.NormalDamage
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})
peaceSpellSkill:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill("#peace_spell_skill") then
      if player.kingdom == "unknown" then
        return 1
      else
        local num = H.getSameKingdomPlayersNum(Fk:currentRoom(), player)
        return (num or 0) + #player:getPile("heavenly_army")
      end
    end
  end,
})
peaceSpellSkill:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player.dead then return end
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).name == peaceSpellSkill.attached_equip then
            return Fk.skills[peaceSpellSkill.name]:isEffectable(player)
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, peaceSpellSkill.name)
    if player.hp > 1 and player:isAlive() then
      player.room:loseHp(player, 1, peaceSpellSkill.name)
    end
  end,
})

return peaceSpellSkill
