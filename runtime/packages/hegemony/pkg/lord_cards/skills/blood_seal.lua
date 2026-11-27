
local skill = fk.CreateSkill{
  name = "#blood_seal_skill",
  attached_equip = "blood_seal",
}

local H = require "packages.hegemony.util"

skill:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(skill.name) and target.phase == Player.Play and
      H.getGeneralsRevealedNum(target) == 0 and not target.dead and
      target:canUseTo(Fk:cloneCard("known_both", nil, nil, skill.name), player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = skill.name,
      prompt = "#blood_seal-invoke:"..player.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("known_both", nil, target, player, "blood_seal")
  end,
})

skill:addEffect(fk.DrawNCards, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
})
return skill
