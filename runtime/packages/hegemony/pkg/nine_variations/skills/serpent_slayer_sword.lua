
local skill = fk.CreateSkill{
  name = "#serpent_slayer_sword_skill",
  attached_equip = "serpent_slayer_sword",
}

skill:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) and player.room.logic:damageByCardEffect() and
      data.card and data.card.trueName == "slash" then
      if player:isWounded() then
        return true
      elseif not data.to.dead then
        if data.to.kingdom == "wild" then
          return true
        end
        if Fk.generals[data.to.general].trueName:startsWith("lord") then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = skill.name,
    }
    if data.to.dead then return end
    if data.to.kingdom == "wild" or Fk.generals[data.to.general].trueName:startsWith("lord") then
      room:killPlayer{ who = data.to }
    end
  end,
})

return skill
