local chunqiu = fk.CreateSkill {
  name = "#kq__chunqiu",
}

Fk:loadTranslationTable{
  ["#kq__chunqiu"] = "吕氏春秋",
  [":#kq__chunqiu"] = "所有男性角色的额定摸牌数+1；若场上有吕不韦，当吕不韦摸牌时，摸牌数+1。",
}

chunqiu:addEffect(fk.DrawNCards, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:isMale()
  end,
  on_refresh = function (self, event, target, player, data)
    data.n = data.n + 1
  end,
})

chunqiu:addEffect(fk.BeforeDrawCard, {
  can_refresh = function (self, event, target, player, data)
    return target == player and
      (Fk.generals[player.general].trueName == "lvbuwei" or (Fk.generals[player.deputyGeneral] or {}).trueName == "lvbuwei")
  end,
  on_refresh = function (self, event, target, player, data)
    player:broadcastSkillInvoke("qin__chunqiu")
    player:chat("$qin__chunqiu")
    data.num = data.num + 1
  end,
})

return chunqiu
