local gonghuan = fk.CreateSkill {
  name = "os__gonghuan",
}

Fk:loadTranslationTable {
  ["os__gonghuan"] = "共患",
  [":os__gonghuan"] = "每回合限一次，当体力值不大于你且有〖共患〗的其他角色受到伤害时，你可以将此伤害转移给自己。",

  ["#os__gonghuan-ask"] = "共患：你可将 %dest 受到的 %arg 点%arg2伤害转移给自己",

  ["$os__gonghuan1"] = "同声鼓瑟，合韵鸣琴。",
  ["$os__gonghuan2"] = "与处乱世，互呴以湿。",
}

gonghuan:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gonghuan.name) and target:hasSkill(gonghuan.name, true) and target ~= player
        and target.hp <= player.hp and player:usedSkillTimes(gonghuan.name) < 1 and
        not (data.extra_data or {}).osGonghuan
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = gonghuan.name,
      prompt = "#os__gonghuan-ask::" .. target.id .. ":" .. data.damage .. ":" .. Fk:getDamageNatureName(data.damageType)
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = data.damage
    data:preventDamage()
    room:damage {
      from = data.from,
      to = player,
      damage = n,
      damageType = data.damageType,
      skillName = data.skillName,
      card = data.card,
      chain = data.chain,
      extra_data = { osGonghuan = true },
    }
  end
})

return gonghuan
