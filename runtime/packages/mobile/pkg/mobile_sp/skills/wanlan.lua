local wanlan = fk.CreateSkill {
  name = "wanlan",
}

Fk:loadTranslationTable{
  ["wanlan"] = "挽澜",
  [":wanlan"] = "当一名角色受到致命伤害时，你可弃置装备区中所有牌（至少一张），防止此伤害。",

  ["#wanlan-invoke"] = "挽澜：你可以弃置所有装备，防止 %dest 受到的致命伤害！",

  ["$wanlan1"] = "石亭既败，断不可再失大司马！",
  ["$wanlan2"] = "大司马怀托孤之重，岂容半点有失？",
}

wanlan:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(wanlan.name) and
      data.damage >= target.hp and
      #player:getCardIds("e") > 0 and
      table.find(player:getCardIds("e"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = wanlan.name, prompt = "#wanlan-invoke::" .. target.id })
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player, { target.id })
    player:throwAllCards("e")
    data:preventDamage()
  end,
})

return wanlan
