local rouge_xvyan__fireAttackSkill = fk.CreateSkill {
  name = "rouge_xvyan__fire_attack_skill",
}
local RougeUtil = require "packages.ol.pkg.ol_gamemode.rougelike1v1.util"
local U = require "packages.utility.utility"
local hasTalent = RougeUtil.hasTalent
local hasTalentStart = function(...)
  return #RougeUtil.hasTalentStart(...) > 0
end
local sendTalentLog = RougeUtil.sendTalentLog
RougeUtil:addBuffTalent { 1, "rouge_xvyan" }
Fk:loadTranslationTable {
  ["rouge_xvyan"] = "虚焰",
  [":rouge_xvyan"] = "【火攻】弃置改为展示",
  ["rouge_xvyan__fire_attack_skill"] = "虚焰",
  ["#rouge_xvyan__fire_attack_skill"] = "虚焰:你使用【火攻】的弃置牌改为展示牌",
  ["#rouge_xvyan__fire_attack_skill-show1"] = "虚焰：你需要对【%src】展示一张火攻牌。",
  ["#rouge_xvyan__fire_attack_skill-show2"] = "虚焰：你可以展示一张与展示牌相同花色的牌，然后对其造成1点火焰伤害。",
}
rouge_xvyan__fireAttackSkill:addEffect("cardskill", {
  name = "rouge_xvyan__fire_attack_skill",
  prompt = "#rouge_xvyan__fire_attack_skill",
  target_num = 1,
  mute = true,
  mod_target_filter = function(self, _, to_select, _, _, _)
    return not to_select:isKongcheng()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, cardEffectEvent)
    local from = cardEffectEvent.from
    local to = cardEffectEvent.to
    if to:isKongcheng() then return end

    local params = { ---@type AskToCardsParams
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = "rouge_xvyan__fire_attack_skill",
      cancelable = false,
      pattern = ".|.|.|hand",
      prompt = "#fire_attack-show:" .. from.id
    }
    local showCard = room:askToCards(to, params)[1]
    to:showCards(showCard)

    local showCard = Fk:getCardById(showCard)
    local color_string = "."
    if showCard.color == Card.Red then
      color_string = "heart,diamond"
    elseif showCard.color == Card.Black then
      color_string = "spade,club"
    end
    local cards = room:askToCards(from, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = "rouge_xvyan__fire_attack_skill",
      cancelable = false,
      pattern = ".|.|" .. color_string,
      prompt = "#rouge_xvyan__fire_attack_skill-show2"
    })
    if #cards > 0 then
      sendTalentLog(from, "rouge_xvyan")
      from:showCards(cards)
      room:damage({
        from = from,
        to = to,
        card = cardEffectEvent.card,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = "rouge_xvyan__fire_attack_skill",
      })
    end
  end,

})

return rouge_xvyan__fireAttackSkill
