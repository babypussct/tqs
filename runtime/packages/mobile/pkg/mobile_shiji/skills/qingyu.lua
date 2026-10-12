local qingyu = fk.CreateSkill {
  name = "qingyu",
  tags = { Skill.Quest },
  related_skills = { "xuancun" },
}

Fk:loadTranslationTable{
  ["qingyu"] = "清玉",
  [":qingyu"] = "使命技，当你受到伤害时，你需弃置两张手牌并防止此伤害。<br>"..
  "⬤　成功：准备阶段，若你未受伤且没有手牌，你获得技能〖悬存〗。<br>"..
  "⬤　失败：当你进入濒死状态时，你减1点体力上限且使命失败。",

  ["#qingyu-invoke"] = "清玉：你需弃置两张手牌，防止你受到的伤害",

  ["$qingyu1"] = "大家之韵，不可失之。",
  ["$qingyu2"] = "朱沉玉没，桂殒兰凋。",
  ["$qingyu3"] = "冰清玉粹，岂可有污！",
}

qingyu:addEffect(fk.DetermineDamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingyu.name) and
      player:getHandcardNum() > 1 and not player:getQuestSkillState(qingyu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(qingyu.name, 3)
    room:notifySkillInvoked(player, qingyu.name, "defensive")
    local ids = table.filter(player:getCardIds("he"), function (id)
      return not player:prohibitDiscard(id)
    end)
    if #ids > 1 then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = qingyu.name,
        cancelable = false,
      })
      data.prevented = true
    end
  end,
})
qingyu:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qingyu.name) and
      player.phase == Player.Start and not player:isWounded() and player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(qingyu.name, 1)
    room:notifySkillInvoked(player, qingyu.name, "special")
    room:handleAddLoseSkills(player, "xuancun")
    room:updateQuestSkillState(player, qingyu.name, false)
    room:invalidateSkill(player, qingyu.name)
  end,
})
qingyu:addEffect(fk.EnterDying, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qingyu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(qingyu.name, 2)
    room:notifySkillInvoked(player, qingyu.name, "negative")
    room:updateQuestSkillState(player, qingyu.name, true)
    room:invalidateSkill(player, qingyu.name)
    room:changeMaxHp(player, -1)
  end,
})

return qingyu
