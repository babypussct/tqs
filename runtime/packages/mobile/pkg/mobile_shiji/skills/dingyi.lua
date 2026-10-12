
local dingyi = fk.CreateSkill {
  name = "dingyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dingyi"] = "定仪",
  [":dingyi"] = "锁定技，游戏开始时，你选择一项，令任意名角色获得对应效果："..
  "1.摸牌阶段摸牌数+1；2.手牌上限+2；3.攻击范围+1；4.脱离濒死状态时回复1点体力。",

  ["#dingyi-choice"] = "定仪：选择一项对任意名角色生效",
  ["@@dingyi1"] = "额外摸牌",
  ["@@dingyi2"] = "手牌上限",
  ["@@dingyi3"] = "攻击范围",
  ["@@dingyi4"] = "额外回复",

  ["$dingyi1"] = "经国序民，还需制礼定仪。",
  ["$dingyi2"] = "无礼而治世，欲使国泰，安可得哉？",
}

dingyi:addAuxActiveSkill("#dingyi_active", {
  card_num = 0,
  min_target_num = 1,
  interaction = UI.OptionBox { options = { "@@dingyi1", "@@dingyi2", "@@dingyi3", "@@dingyi4" } },
  card_filter = Util.FalseFunc,
  target_filter = Util.TrueFunc,
})

dingyi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dingyi.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#dingyi_active",
      prompt = "#dingyi-choice",
    })
    if success and dat then
      for _, p in ipairs(dat.targets) do
        room:setPlayerMark(p, dat.interaction, 1)
      end
    end
  end,
})

dingyi:addEffect(fk.DrawNCards, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@dingyi1") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + math.floor(2 ^ player:getMark("fubi"))
  end,
})

dingyi:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:getMark("@@dingyi2") > 0 then
      return math.floor(2 * (2 ^ player:getMark("fubi")))
    end
  end,
})

dingyi:addEffect("atkrange", {
  correct_func = function(self, from, to)
    if from:getMark("@@dingyi3") > 0 then
      return math.floor(2 ^ from:getMark("fubi"))
    end
  end,
})

dingyi:addEffect(fk.AfterDying, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@dingyi4") > 0 and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = math.min(player.maxHp - player.hp, 2 ^ player:getMark("fubi")),
      recoverBy = player,
      skillName = dingyi.name,
    }
  end,
})

return dingyi
