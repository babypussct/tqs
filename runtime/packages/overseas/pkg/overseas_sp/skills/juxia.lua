local juxia = fk.CreateSkill {
  name = "os_js__juxia",
}

Fk:loadTranslationTable{
  ["os_js__juxia"] = "居下",
  [":os_js__juxia"] = "每回合限一次，当其他角色使用牌指定你为目标后，若其技能数大于你，你可以令此牌对你无效，然后摸一张牌。" ..
    "准备阶段，若你没有〖观火〗，你可以获得之。",

  ["#os_js__juxia-invoke"] = "居下：你可以令%arg对你无效并令其摸一张牌",
  ["#os_js__juxia-add"] = "居下：你可以获得〖观火〗",

  ["$os_js__juxia1"] = "昔与明公俱为鸿鹄，不意明公今为凤皇尔！",
  ["$os_js__juxia2"] = "天下事在公，义真何敢多言。",
}

juxia:addEffect(fk.TargetSpecified, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      target:isAlive() and
      data.to == player and
      player:hasSkill(juxia.name) and
      #table.filter(
        target:getSkillNameList(),
        function(skill)
          return Fk.skills[skill] and Fk.skills[skill]:isPlayerSkill(target)
        end
      ) > #table.filter(
        player:getSkillNameList(),
        function(skill)
          return Fk.skills[skill] and Fk.skills[skill]:isPlayerSkill(player)
        end
      ) and
      player:usedSkillTimes(juxia.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = juxia.name,
      prompt = "#os_js__juxia-invoke:::"..data.card:toLogString()
    }) then
      room:doIndicate(player, { target })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    table.insertIfNeed(data.use.nullifiedTargets, player)
    player:drawCards(1, juxia.name)
  end,
})

juxia:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(juxia.name) and player.phase == Player.Start and
      not player:hasSkill("os_js__guanhuo", true)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = juxia.name, prompt = "#os_js__juxia-add" })
  end,
  on_use = function (self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "os_js__guanhuo")
  end
})

return juxia
