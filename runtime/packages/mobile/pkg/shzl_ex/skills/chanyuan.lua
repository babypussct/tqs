local chanyuan = fk.CreateSkill{
  name = "chanyuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chanyuan"] = "缠怨",
  [":chanyuan"] = "锁定技，你不能质疑〖蛊惑〗；若你的体力值为1，你的其他技能失效。",

  ["@@chanyuan"] = "缠怨",

  ["$chanyuan1"] = "不识天数，在劫难逃。",
  ["$chanyuan2"] = "凡人仇怨，皆由心生。",
}

chanyuan:addEffect("invalidity", {
  recheck_invalidity = true,
  invalidity_func = function(self, from, skill)
    return from:hasSkill(chanyuan.name) and from.hp == 1 and skill:isPlayerSkill(from) and skill.name ~= chanyuan.name
  end,
})

local spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(chanyuan.name) and player.hp == 1
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, chanyuan.name, "negative")
    player:broadcastSkillInvoke(chanyuan.name)
  end,
}

chanyuan:addEffect(fk.HpChanged, spec)
chanyuan:addEffect(fk.MaxHpChanged, spec)

chanyuan:addAcquireEffect(function (self, player, is_start)
  player.room:setPlayerMark(player, "@@chanyuan", 1)
end)

chanyuan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@@chanyuan", 0)
end)

return chanyuan
