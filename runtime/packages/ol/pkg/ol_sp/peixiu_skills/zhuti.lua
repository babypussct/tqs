local zhuti = fk.CreateSkill {
  name = "peixiu_zhuti",
  max_turn_use_time = 1,
}

Fk:loadTranslationTable {
  ["peixiu_zhuti"] = "朱提",
  [":peixiu_zhuti"] = "你受到属性伤害改为回复等量体力（每回合限一次）。",
}

zhuti:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuti.name) and
      data.damageType ~= fk.NormalDamage and player:usedSkillTimes(zhuti.name, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local damage = data.damage
    data:preventDamage()
    room:recover{
      who = player,
      num = damage,
      recoverBy = player,
      skillName = zhuti.name,
    }
  end,
})

return zhuti
