local rouge_xvlijian__archery_attack_skill = fk.CreateSkill {
  name = "rouge_xvlijian__archery_attack_skill",
}
local RougeUtil = require "packages.ol.pkg.ol_gamemode.rougelike1v1.util"
local U = require "packages.utility.utility"
local hasTalent = RougeUtil.hasTalent
local hasTalentStart = function(...)
  return #RougeUtil.hasTalentStart(...) > 0
end
local sendTalentLog = RougeUtil.sendTalentLog

RougeUtil:addBuffTalent { 1, "rouge_xvlijian" }
Fk:loadTranslationTable {
  ["rouge_xvlijian"] = "蓄力箭",
  [":rouge_xvlijian"] = "你使用的【万箭齐发】其他角色需要使用2张【闪】来响应",
  ["rouge_xvlijian__archery_attack_skill"] = "蓄力箭",
  ["#rouge_xvlijian__archery_attack_skill"] = "蓄力箭:你使用的【万箭齐发】其他角色需要使用2张【闪】来响应",
  ["#rougelike1v1_PreCardEffect_rouge_xvlijian"] = "蓄力箭",
}

rouge_xvlijian__archery_attack_skill:addEffect("cardskill", {
  name = "rouge_xvlijian__archery_attack_skill",
  mute = true,
  prompt = "#rouge_xvlijian__archery_attack_skill",
  can_use = Util.AoeCanUse,
  mod_target_filter = function(self, player, to_select, selected, card, distance_limited)
    return to_select ~= player
  end,
  on_use = function(self, room, cardUseEvent)
    return Util.AoeCardOnUse(self, cardUseEvent.from, cardUseEvent, false)
  end,
  on_effect = function(self, room, effect)
    local loopTimes = 2
    local respond
    for i = 1, loopTimes do
      local params = { ---@type AskToUseCardParams
        skill_name = 'jink',
        pattern = 'jink',
        cancelable = true,
        event_data = effect
      }
      respond = room:askToResponse(effect.to, params)
      if respond then
        room:responseCard(respond)
      else
        room:damage({
          from = effect.from,
          to = effect.to,
          card = effect.card,
          damage = 1,
          damageType = fk.NormalDamage,
          skillName = "rouge_xvlijian__archery_attack_skill",
        })
      end
      if effect.to.dead then break end
    end
  end
})

return rouge_xvlijian__archery_attack_skill
