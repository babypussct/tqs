local skill = fk.CreateSkill{
  name = "befriend_attacking_skill",
}

local H = require "packages.hegemony.util"

skill:addEffect("cardskill", {
  prompt = "#befriend_attacking_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected)
    return player ~= to_select and H.compareKingdomWith(to_select, player, true)
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    if target.dead then return end
    target:drawCards(1, skill.name)
    if player.dead then return end
    player:drawCards(3, skill.name)
  end
})

skill:addAI(Fk.Ltk.AI.newCardSkillStrategy {
  keep_value = 3.92,
  use_value = 11,
  use_priority = 9.28,

  on_effect = function(self, logic, effect)
    logic:drawCards(effect.to, 1, skill.name)
    logic:drawCards(effect.from, 3, skill.name)
  end,
})

Fk:loadTranslationTable{
  ["befriend_attacking"] = "远交近攻",
  ["befriend_attacking_skill"] = "远交近攻",
  [":befriend_attacking"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：有明置武将且势力与你不同的一名角色<br/>"..
  "<b>效果</b>：目标角色摸一张牌，然后你摸三张牌。",
  ["#befriend_attacking_skill"] = "选择势力与你不同的一名角色，其摸一张牌，你摸三张牌",
}

return skill
