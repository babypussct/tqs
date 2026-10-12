local guilin = fk.CreateSkill{
  name = "guilin",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["guilin"] = "归林",
  [":guilin"] = "限定技，出牌阶段或当你进入濒死状态时，你可以回复体力至体力上限，然后失去〖议政〗、修改〖博玄〗"..
  "（时机改为“当你使用指定角色为目标的手牌结算完毕后”）。",

  ["#guilin"] = "归林：是否回复体力至体力上限，失去“议政”、修改“博玄”？",

  ["$guilin1"] = "倦飞知还，不如归去。",
  ["$guilin2"] = "式微，式微，胡不归？",
}

guilin:addEffect("active", {
  anim_type = "defensive",
  prompt = "#guilin",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(guilin.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    if player:isWounded() then
      room:recover{
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = guilin.name,
      }
    end
    if not player.dead then
      room:handleAddLoseSkills(player, "-yizhengx")
    end
  end,
})

guilin:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guilin.name) and player.dying and
      player:usedSkillTimes(guilin.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    Fk.skills[guilin.name]:onUse(player.room, {
      from = player,
    })
  end,
})

guilin:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return guilin
