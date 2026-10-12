local hengye = fk.CreateSkill {
  name = "hengye",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["hengye"] = "横野",
  [":hengye"] = "锁定技，当你造成伤害后，你令你本局游戏以下每个数值各+1（至多+3）：<br>"..
  "1.摸牌阶段摸牌数；2.出牌阶段使用【杀】次数；3.攻击范围；4.手牌上限。<br>"..
  "达到+3后，你每回合开始时回复1点体力。当你杀死一名角色后，重置此技能。",

  ["@hengye"] = "横野",

  ["$hengye1"] = "负剑觅烽火，狼烟既起战不休！",
  ["$hengye2"] = "吴戈漫野，饮马处岂唯长江！",
}

hengye:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hengye.name) and
      player:getMark("@hengye") < 3
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@hengye", 1)
  end,
})

hengye:addEffect(fk.TurnStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hengye.name) and player:getMark("@hengye") == 3
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = hengye.name,
    }
  end,
})

hengye:addEffect(fk.DrawNCards, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@hengye") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@hengye")
  end,
})

hengye:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card, to)
    if card and card.trueName == "slash" then
      return player:getMark("@hengye")
    end
  end,
})

hengye:addEffect("atkrange", {
  correct_func = function(self, player)
    return player:getMark("@hengye")
  end,
})

hengye:addEffect("maxcards", {
  correct_func = function(self, player)
    return player:getMark("@hengye")
  end,
})

hengye:addEffect(fk.Deathed, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return data.killer == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@hengye", 0)
  end,
})

return hengye
