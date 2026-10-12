local moucheng = fk.CreateSkill{
  name = "mobile__moucheng",
  tags = { Skill.Wake },
  related_skills = { "mobile__jingong" },
}

Fk:loadTranslationTable{
  ["mobile__moucheng"] = "谋逞",
  [":mobile__moucheng"] = "觉醒技，当一名角色造成伤害后，若你的“连计”标记大于2，你加1点体力上限，回复1点体力，失去〖连计〗，获得〖矜功〗。",

  ["$mobile__moucheng1"] = "董贼伏诛，天下当感恩吾功。",
  ["$mobile__moucheng2"] = "董贼即死，李郭等人亦要清算。",
}

moucheng:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(moucheng.name) and target and
      player:usedSkillTimes(moucheng.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@mobile__lianji") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = moucheng.name,
      }
      if player.dead then return end
    end
    player.room:handleAddLoseSkills(player, "-mobile__lianji|mobile__jingong")
  end,
})

return moucheng
