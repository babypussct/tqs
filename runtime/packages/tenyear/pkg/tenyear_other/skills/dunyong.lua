local dunyong = fk.CreateSkill {
  name = "dunyong",
}

Fk:loadTranslationTable{
  ["dunyong"] = "钝勇",
  [":dunyong"] = "当你对其他角色造成伤害时，若你的体力上限不为全场唯一最低，你受到等量伤害；当一名角色进入濒死状态时，" ..
  "你摸其体力上限数量的牌，令你本回合使用牌无距离和次数限制。",

  ["$dunyong1"] = "多了不说、少了不唠，开造！",
  ["$dunyong2"] = "你不懂打人这一块，要以德服人。",
}

dunyong:addEffect(fk.DamageCaused, {
  audio_index = 2,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.to ~= player and
      player:hasSkill(dunyong.name) and
      table.find(player.room.alive_players, function(p) return p ~= player and p.maxHp <= player.maxHp end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      to = player,
      damage = data.damage,
      skillName = dunyong.name,
    }
  end,
})

dunyong:addEffect(fk.EnterDying, {
  audio_index = 1,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dunyong.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(target.maxHp, dunyong.name)
    player.room:setPlayerMark(player, "dunyong_buff-turn", 1)
  end,
})

dunyong:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and player:getMark("dunyong_buff-turn") > 0
  end,
  bypass_times = function(self, player, skill, card, to)
    return card and player:getMark("dunyong_buff-turn") > 0
  end,
})

return dunyong
