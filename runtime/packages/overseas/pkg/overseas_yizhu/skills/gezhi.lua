local osGezhi = fk.CreateSkill {
  name = "os__gezhi"
}

Fk:loadTranslationTable{
  ["os__gezhi"] = "革制",
  [":os__gezhi"] = "当你于你的出牌阶段使用牌时，若为你此阶段首次使用此类型的牌，你可以重铸一张手牌。" ..
  "出牌阶段结束时，若本阶段你以此法重铸了至少两张牌，你可以令一名角色选择一项：1.攻击范围+2；2.手牌上限+2；3.体力上限+1。（每名角色每项限一次）",

  ["#os__gezhi-ask"] = "革制：你可以重铸一张手牌",
  ["#os__gezhi-target"] = "革制：你可以选择一名角色，令其选择一项",
  ["os__gezhi_ar"] = "攻击范围+2",
  ["os__gezhi_maxcard"] = "手牌上限+2",
  ["os__gezhi_maxhp"] = "体力上限+1",
  ["os__gezhi_lordskill"] = "获得你武将牌上的主公技",
  ["@@os__gezhi_ar"] = "攻击范围+2",

  ["$os__gezhi1"] = "改革旧制，保我汉室长存！",
  ["$os__gezhi2"] = "革除旧弊，方乃中兴！",
}

osGezhi:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(osGezhi.name) or player.phase ~= Player.Play then
      return false
    end

    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      return use.from == player and use.card.type == data.card.type
    end, Player.HistoryTurn)
    return #events == 1 and events[1].id == player.room.logic:getCurrentEvent().id
  end,
  on_cost = function(self, event, target, player, data)
    local id = player.room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        skill_name = osGezhi.name,
        prompt = "#os__gezhi-ask",
      }
    )
    if #id > 0 then
      event:setCostData(self, id[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recastCard(event:getCostData(self), player, osGezhi.name)
  end,
})

osGezhi:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if
      not player:hasSkill(osGezhi.name) or
      player.phase ~= Player.Play or
      player:usedSkillTimes(osGezhi.name, Player.HistoryPhase) < 2
    then
      return false
    end

    for _, p in ipairs(player.room.alive_players) do
      if p:getMark("_os__gezhi") == 0 then return true end
      local num = 3
      if player:hasSkill("os__fengqil") then
        for _, skill_name in ipairs(Fk.generals[p.general]:getSkillNameList(true)) do
          if Fk.skills[skill_name]:hasTag(Skill.Lord) and not p:hasSkill(skill_name, true) then
            num = 4
            break
          end
        end
        if target.deputyGeneral and target.deputyGeneral ~= "" then
          for _, skill_name in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList(true)) do
            if Fk.skills[skill_name]:hasTag(Skill.Lord) and not p:hasSkill(skill_name, true) then
              num = 4
              break
            end
          end
        end
      end
      return #p:getMark("_os__gezhi") < num
    end
  end,
  on_cost = function(self, event, target, player, data)
    local availableTargets = {}
    for _, p in ipairs(player.room.alive_players) do
      if p:getMark("_os__gezhi") == 0 then
        table.insert(availableTargets, p)
      elseif #p:getMark("_os__gezhi") < 3 then
        table.insert(availableTargets, p)
      elseif #p:getMark("_os__gezhi") == 3 then
        if player:hasSkill("os__fengqil") then
          for _, skill_name in ipairs(Fk.generals[p.general]:getSkillNameList(true)) do
            if Fk.skills[skill_name]:hasTag(Skill.Lord) and not p:hasSkill(skill_name, true) then
              table.insert(availableTargets, p)
              break
            end
          end
          if target.deputyGeneral and target.deputyGeneral ~= "" then
            for _, skill_name in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList(true)) do
              if Fk.skills[skill_name]:hasTag(Skill.Lord) and not p:hasSkill(skill_name, true) then
                table.insertIfNeed(availableTargets, p)
                break
              end
            end
          end
        end
      end
    end
    if #availableTargets == 0 then
      return false
    end

    local tos = player.room:askToChoosePlayers(
      player,
      {
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__gezhi-target",
        skill_name = osGezhi.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targetPlayer = event:getCostData(self).tos[1]
    local allChoices = { "os__gezhi_ar", "os__gezhi_maxcard", "os__gezhi_maxhp" }
    if player:hasSkill("os__fengqil") then
      for _, skill_name in ipairs(Fk.generals[targetPlayer.general]:getSkillNameList(true)) do
        if Fk.skills[skill_name]:hasTag(Skill.Lord) and not targetPlayer:hasSkill(skill_name, true) then
          table.insert(allChoices, "os__gezhi_lordskill")
          break
        end
      end
      if targetPlayer.deputyGeneral and targetPlayer.deputyGeneral ~= "" then
        for _, skill_name in ipairs(Fk.generals[targetPlayer.deputyGeneral]:getSkillNameList(true)) do
          if Fk.skills[skill_name]:hasTag(Skill.Lord) and not targetPlayer:hasSkill(skill_name, true) then
            table.insertIfNeed(allChoices, "os__gezhi_lordskill")
            break
          end
        end
      end
    end
    local choices = {}
    if targetPlayer:getMark("_os__gezhi") ~= 0 then
      for i = 1, #allChoices do
        if not table.contains(targetPlayer:getMark("_os__gezhi"), i) then
          table.insert(choices, allChoices[i])
        end
      end
    else
      choices = allChoices
    end
    local record = targetPlayer:getTableMark("_os__gezhi")
    local choice = room:askToChoice(
      targetPlayer,
      {
        choices = choices,
        skill_name = osGezhi.name,
      }
    )

    if choice == "os__gezhi_lordskill" then
      local skills = {}
      for _, skill_name in ipairs(Fk.generals[targetPlayer.general]:getSkillNameList(true)) do
        if Fk.skills[skill_name]:hasTag(Skill.Lord) and not targetPlayer:hasSkill(skill_name, true) then
          table.insertIfNeed(skills, skill_name)
        end
      end
      if targetPlayer.deputyGeneral and targetPlayer.deputyGeneral ~= "" then
        for _, skill_name in ipairs(Fk.generals[targetPlayer.deputyGeneral]:getSkillNameList(true)) do
          if Fk.skills[skill_name]:hasTag(Skill.Lord) and not targetPlayer:hasSkill(skill_name, true) then
            table.insertIfNeed(skills, skill_name)
          end
        end
      end
      if #skills > 0 then
        room:handleAddLoseSkills(targetPlayer, table.concat(skills, "|"), nil, true, false)
      end
      table.insert(record, 4)
    elseif choice == "os__gezhi_ar" then
      room:addPlayerMark(targetPlayer, "@@os__gezhi_ar")
      table.insert(record, 1)
    elseif choice == "os__gezhi_maxcard" then
      room:addPlayerMark(targetPlayer, MarkEnum.AddMaxCards, 2)
      table.insert(record, 2)
    else
      room:changeMaxHp(targetPlayer, 1)
      table.insert(record, 3)
    end
    room:setPlayerMark(targetPlayer, "_os__gezhi", record)
  end,
})

osGezhi:addEffect("atkrange", {
  correct_func = function(self, from, to)
    return from:getMark("@@os__gezhi_ar") ~= 0 and from:getMark("@@os__gezhi_ar") * 2 or 0
  end,
})

return osGezhi
