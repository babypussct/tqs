local qiuan = fk.CreateSkill {
  name = "ld__qiuan",
  derived_piles = "ld__mengda_letter",
}

Fk:loadTranslationTable {
  ["ld__qiuan"] = "求安",
  [":ld__qiuan"] = "当你受到伤害时，若没有“函”，你可将造成此伤害的牌置于武将牌上，称为“函”，然后防止此伤害。",

  ["ld__mengda_letter"] = "函",

  ["$ld__qiuan1"] = "明公神文圣武，吾自当举城来降。",
  ["$ld__qiuan2"] = "臣心不自安，乃君之过也。",
}

qiuan:addEffect(fk.DamageInflicted, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiuan.name) and data.card
        and #player:getPile("ld__mengda_letter") == 0 and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("ld__mengda_letter", data.card, true, qiuan.name)
    if #player:getPile("ld__mengda_letter") > 0 then
      data:preventDamage()
    end
  end,
})

return qiuan
