local dianchi = fk.CreateSkill {
  name = "peixiu_dianchi",
}

Fk:loadTranslationTable {
  ["peixiu_dianchi"] = "滇池",
  [":peixiu_dianchi"] = "一名角色受到火焰伤害后，你可以令其失去1点体力（每回合限一次）。",

  ["#peixiu_dianchi-invoke"] = "滇池：是否令 %dest 失去1点体力？",
}

dianchi:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dianchi.name) and
      not target.dead and data.damageType == fk.FireDamage and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = dianchi.name,
      prompt = "#peixiu_dianchi-invoke::"..target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(target, 1, dianchi.name, player)
  end,
})

return dianchi
