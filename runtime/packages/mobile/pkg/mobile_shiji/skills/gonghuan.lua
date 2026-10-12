local gonghuan = fk.CreateSkill {
  name = "gonghuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["gonghuan"] = "共患",
  [":gonghuan"] = "锁定技，每回合限一次，当另一名拥有“姻”的角色受到伤害时，若其体力值小于你，将此伤害转移给你；然后移除双方的“姻”标记。",

  ["$gonghuan1"] = "曹魏势大，吴蜀当共拒之。",
  ["$gonghuan2"] = "两国得此联姻，邦交更当稳固。",
}

gonghuan:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gonghuan.name) and target ~= player and target:getMark("@@luanchou") > 0 and not data.gonghuan and
      target.hp < player.hp and player:usedSkillTimes(gonghuan.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = data.damage
    room:doIndicate(player, {target})
    data:preventDamage()
    room:damage{
      from = data.from,
      to = player,
      damage = n,
      damageType = data.damageType,
      skillName = data.skillName,
      card = data.card,
      chain = data.chain,
      gonghuan = true,
    }
    room:setPlayerMark(player, "@@luanchou", 0)
    room:handleAddLoseSkills(player, "-gonghuan")
    room:setPlayerMark(target, "@@luanchou", 0)
    room:handleAddLoseSkills(target, "-gonghuan")
  end,
})

return gonghuan
