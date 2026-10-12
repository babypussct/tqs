local qingyu = fk.CreateSkill {
  name = "os__qingyu",
  tags = { Skill.Quest, Skill.Compulsory },
  related_skills = { "os__xuancun", "os__yongjue" },
}

Fk:loadTranslationTable{
  ["os__qingyu"] = "清玉",
  [":os__qingyu"] = "使命技，锁定技，当你受到伤害时，你需弃置两张牌并防止之。<br>"..
  "⬤　成功：准备阶段，若你未受伤且轮数大于你的手牌数，你获得技能〖悬存〗。<br>"..
  "⬤　失败：当你进入濒死状态时，你减1点体力上限且使命失败，然后你令一名其他角色获得技能〖勇决〗。",

  ["#os__qingyu-invoke"] = "清玉：你需弃置两张手牌，防止你受到的伤害",
  ["#os__qingyu-choose"] = "清玉：令一名角色获得技能“勇决”",

  ["$os__qingyu1"] = "大家之韵，不可失之。",
  ["$os__qingyu2"] = "朱沉玉没，桂殒兰凋。",
  ["$os__qingyu3"] = "冰清玉粹，岂可有污！",
}

qingyu:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  audio_index = { 3 },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingyu.name) and
      #player:getCardIds("he") > 1 and not player:getQuestSkillState(qingyu.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
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
      data:preventDamage()
    end
  end,
})

qingyu:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  audio_index = { 1 },
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qingyu.name) and
      player.phase == Player.Start and not player:isWounded() and player.room:getBanner("RoundCount") > player:getHandcardNum()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "os__xuancun")
    room:updateQuestSkillState(player, qingyu.name, false)
    room:invalidateSkill(player, qingyu.name)
  end,
})

qingyu:addEffect(fk.EnterDying, {
  anim_type = "negative",
  audio_index = { 2 },
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qingyu.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:updateQuestSkillState(player, qingyu.name, true)
    room:invalidateSkill(player, qingyu.name)
    room:changeMaxHp(player, -1)
    if not player.dead and #room:getOtherPlayers(player, false) > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(player, false),
        skill_name = qingyu.name,
        prompt = "#os__qingyu-choose",
        cancelable = false,
      })[1]
      room:handleAddLoseSkills(to, "os__yongjue")
    end
  end,
})

return qingyu
