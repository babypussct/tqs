
local qiuan = fk.CreateSkill {
  name = "ld__qiuan",
  derived_piles = "ld__mengda_letter",
}

Fk:loadTranslationTable {
  ["ld__qiuan"] = "求安",
  [":ld__qiuan"] = "当你受到伤害时，你可以将造成伤害的牌置于武将牌上，称为“函”（至多一张），然后防止此伤害。",

  ["ld__mengda_letter"] = "函",

  ["$ld__qiuan1"] = "明公神文圣武，吾自当举城来降。",
  ["$ld__qiuan2"] = "臣心不自安，乃君之过也。",
}

qiuan:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiuan.name) and
      #player:getPile("ld__mengda_letter") == 0 and
      data.card and
      table.find(Card:getIdList(data.card), function (id)
        return player.room:getCardArea(id) == Card.Processing
      end)
  end,
  on_use = function(self, event, target, player, data)
    local cards = table.filter(Card:getIdList(data.card), function (id)
      return player.room:getCardArea(id) == Card.Processing
    end)
    player:addToPile("ld__mengda_letter", cards[1], true, qiuan.name)
    data:preventDamage()
  end,
})

return qiuan
