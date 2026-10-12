
local wumou = fk.CreateSkill {
  name = "mobile__wumou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__wumou"] = "无谋",
  [":mobile__wumou"] = "锁定技，你的普通锦囊牌只能当普通【杀】使用或打出，此【杀】的目标改为原锦囊的目标。",

  ["#mobile__wumou__slash_skill"] = "选择原锦囊的目标角色，对其造成1点伤害",

  ["$mobile__wumou1"] = "哪个说我有勇无谋？",
  ["$mobile__wumou2"] = "无谋，又待如何！",
}

wumou:addEffect("filter", {
  anim_type = "offensive",
  card_filter = function(self, card, player)
    return player:hasSkill(wumou.name) and card:isCommonTrick() and
      table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = wumou.name
    return c
  end,
})

wumou:addEffect("filter", {
  card_skill_filter = function (self, card, player)
    if table.contains(card.skillNames, wumou.name) then
      return "#mobile__wumou__slash_skill"
    end
  end,
})

return wumou
