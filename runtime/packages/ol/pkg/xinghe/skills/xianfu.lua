local xianfu = fk.CreateSkill{
  name = "xianfu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xianfu"] = "先辅",
  [":xianfu"] = "锁定技，游戏开始时，你选择一名其他角色，当其受到伤害后，若其存活，你受到等量的伤害；当其回复体力后，你回复等量的体力。",

  ["@[chara]xianfu"] = "先辅",
  ["#xianfu-choose"] = "先辅：请选择要先辅的角色",

  ["$xianfu1"] = "辅佐明君，从一而终。",
  ["$xianfu2"] = "吾于此生，竭尽所能。",
  ["$xianfu3"] = "春蚕至死，蜡炬成灰！",
  ["$xianfu4"] = "愿为主公，尽我所能。",
  ["$xianfu5"] = "赠人玫瑰，手有余香。",
  ["$xianfu6"] = "主公之幸，我之幸也。",
}

xianfu:addEffect(fk.GameStart, {
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xianfu.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = xianfu.name,
      prompt = "#xianfu-choose",
      cancelable = false,
      no_indicate = true,
    })[1]
    room:setPlayerMark(player, xianfu.name, to)
  end,
})

xianfu:addEffect(fk.Damaged, {
  anim_type = "negative",
  audio_index = { 3, 4 },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xianfu.name) and
      player:getMark(xianfu.name) == target and target:isAlive()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@[chara]xianfu", target.id)
    room:damage{
      to = player,
      damage = data.damage,
      skillName = xianfu.name,
    }
  end,
})

xianfu:addEffect(fk.HpRecover, {
  anim_type = "support",
  audio_index = { 5, 6 },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xianfu.name) and
      player:getMark(xianfu.name) == target and player:isWounded()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@[chara]xianfu", target.id)
    room:recover{
      who = player,
      num = data.num,
      recoverBy = player,
      skillName = xianfu.name,
    }
  end,
})

xianfu:addEffect(fk.Death, {
  can_refresh = function (self, event, target, player, data)
    return player:getMark(xianfu.name) == target
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@[chara]xianfu", 0)
    room:setPlayerMark(player, xianfu.name, 0)
  end,
})

xianfu:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    local ret = ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 1,
      max_num = 1,
      skill_name = self.skill_name,
      benefit_func = function (logic, p)
        logic.benefit = ai:needHelp(p)
      end,
    })
    return ret
  end,
})

return xianfu
