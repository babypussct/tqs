
local fanhuo = fk.CreateSkill {
  name = "fanhuo",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["fanhuo"] = "泛祸",
  [":fanhuo"] = "限定技，出牌阶段，你可以令〖兴邦〗改为“出牌阶段限三次”直到回合结束，然后你于此回合结束时失去3点体力。",

  ["#fanhuo"] = "泛祸：令“兴邦”本回合改为出牌阶段限三次，回合结束时失去3点体力",
  ["@@fanhuo-turn"] = "泛祸",

  ["$fanhuo1"] = "",
  ["$fanhuo2"] = "",
}

fanhuo:addEffect("active", {
  anim_type = "control",
  prompt = "#fanhuo",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(fanhuo.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    room:setPlayerMark(effect.from, "@@fanhuo-turn", 1)
  end,
})

fanhuo:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@fanhuo-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, 3, fanhuo.name)
  end,
})

return fanhuo
