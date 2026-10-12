
local qianxun = fk.CreateSkill{
  name = "m_heg__qianxun",
  tags = { Skill.Compulsory },
  derived_piles = "$m_heg__qianxun",
}

Fk:loadTranslationTable{
  ["m_heg__qianxun"] = "谦逊",
  [":m_heg__qianxun"] = "锁定技，当你成为其他角色使用的锦囊牌的唯一目标时，若你的“节”数小于3，你取消之并将此牌置于你的武将牌上，称为“节”。",

  ["$m_heg__qianxun"] = "节",

  ["$m_heg__qianxun1"] = "满招损，谦受益。",
  ["$m_heg__qianxun2"] = "谦谦君子，温润如玉。",
}

qianxun:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qianxun.name) and
      data.from ~= player and data.card.type == Card.TypeTrick and
      data:isOnlyTarget(player) and #player:getPile("$m_heg__qianxun") < 3
  end,
  on_use = function(self, event, target, player, data)
    data:cancelTarget(player)
    if player.room:getCardArea(data.card) == Card.Processing then
      player:addToPile("$m_heg__qianxun", data.card, false, qianxun.name)
    end
  end,
})

return qianxun
