local burningCampsSkill = fk.CreateSkill{
  name = "burning_camps_skill",
}

local H = require "packages.hegemony.util"

burningCampsSkill:addEffect("cardskill", {
  prompt = "#burning_camps_skill",
  can_use = Util.CanUseFixedTarget,
  mod_target_filter = function(self, player, to_select, selected, card, distance_limited)
    local prev = player:getNextAlive()
    return prev ~= player and (to_select == prev or H.inFormationRelation(prev, to_select))
  end,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    room:damage({
      from = player,
      to = target,
      card = effect.card,
      damage = 1,
      damageType = fk.FireDamage,
      skillName = self.name
    })
  end,
})

Fk:loadTranslationTable{
  ["burning_camps"] = "火烧连营",
  [":burning_camps"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：你的下家和除其外与其处于同一<a href='heg_formation_href'>队列</a>的所有角色<br/>"..
  "<b>效果</b>：目标角色受到你造成的1点火焰伤害。",

  ["#burning_camps_skill"] = "对你的下家和其同队列的所有角色各造成1点火焰伤害",
}

return burningCampsSkill
