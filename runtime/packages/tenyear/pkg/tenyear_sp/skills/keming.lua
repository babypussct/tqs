
local keming = fk.CreateSkill {
  name = "keming",
}

Fk:loadTranslationTable{
  ["keming"] = "刻名",
  [":keming"] = "当你受到其他角色造成的伤害后，若其武将牌上有此时机触发的技能，则你可以触发此技能；"..
  "若没有，则你可以从“曹”姓武将中随机触发一个此时机的技能。"..
  "当你对其他角色造成伤害后，该角色下次发动准备阶段、结束阶段或出牌阶段内发动的技能后，若该角色因此技能摸牌或使用了牌，你可以摸等量同名牌（至多五张）。",

  ["#keming-invoke"] = "刻名：是否摸等量张 %dest 发动技能摸牌/使用的牌？",
  ["@@keming"] = "刻名",

  ["$keming1"] = "冠我名于九州，始知天下多好臣！",
  ["$keming2"] = "我言成诏，汝名成囚！",
}

keming:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(keming.name) and
      data.from and data.from ~= player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_skills = Fk.generals[data.from.general]:getSkillNameList(player.role == "lord")
    if data.from.deputyGeneral ~= "" then
      table.insertTableIfNeed(all_skills, Fk.generals[data.from.deputyGeneral]:getSkillNameList(player.role == "lord"))
    end
    local skills = {}
    for _, skill_name in ipairs(all_skills) do
      if not player:hasSkill(skill_name, true) then
        player:addSkill(skill_name)
        local skel = Fk.skills[skill_name]:getSkeleton()
        for _, skill in ipairs(skel.effects) do
          if skill:isInstanceOf(TriggerSkill) and skill.event == fk.Damaged and skill:triggerable(event, target, player, data) then
            table.insert(skills, skill_name)
            break
          end
        end
        player:loseSkill(skill_name)
      end
    end
    if #skills == 0 then
      all_skills = room:getBanner(keming.name)
      for _, skill_name in ipairs(all_skills) do
        if not player:hasSkill(skill_name, true) then
          player:addSkill(skill_name)
          local skel = Fk.skills[skill_name]:getSkeleton()
          for _, skill in ipairs(skel.effects) do
            if skill:isInstanceOf(TriggerSkill) and skill.event == fk.Damaged and skill:triggerable(event, target, player, data) then
              table.insert(skills, skill_name)
              break
            end
          end
          player:loseSkill(skill_name)
        end
      end
      if #skills > 0 then
        skills = room:tableRandomPick(skills, 1)
      end
    end
    if #skills == 0 then return end
    room:handleAddLoseSkills(player, skills)
    for _, skill_name in ipairs(skills) do
      local skel = Fk.skill_skels[skill_name]
      for _, skill in ipairs(skel.effects) do
        if skill:isInstanceOf(TriggerSkill) and skill.event == fk.Damaged and skill:triggerable(event, target, player, data) then
          skill:trigger(event, target, player, data)
        end
      end
    end
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"))
  end,
})

keming:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(keming.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(data.to, "@@keming", player)
  end,
})

keming:addEffect(fk.AfterSkillEffect, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    local phases = { Player.Start, Player.Finish, Player.Play }
    if player:getMark("@@keming") == 0 or not table.contains(phases, player.phase) or
      data.who ~= player or not data.skill:isPlayerSkill(player) or
      not player:hasSkill(data.skill:getSkeleton().name, true, true) then return false end
    local e = player.room.logic:getCurrentEvent().parent
    if not e or e.event ~= GameEvent.Phase then return false end
    local d = e.data
    return d.who == player and table.contains({ Player.Start, Player.Finish, Player.Play }, d.phase)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@keming", 0)
  end,
})

keming:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    local phases = { Player.Start, Player.Finish, Player.Play }
    if player == data.from and player:getMark("@@keming") ~= 0 and table.contains(phases, player.phase) then
      local room = player.room
      local e = room.logic:getCurrentEvent().parent
      if not e or e.event ~= GameEvent.SkillEffect then return false end
      local d = e.data
      if d.who ~= player or not d.skill:isPlayerSkill(player) or
        not player:hasSkill(d.skill:getSkeleton().name, true, true) then return false end
      e = e.parent
      if not e or e.event ~= GameEvent.Phase then return false end
      d = e.data
      return d.who == player and table.contains(phases, d.phase)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local players = player:getTableMark("@@keming")
    room:setPlayerMark(player, "@@keming", 0)
    room:sortByAction(players)
    local x = math.max(1, #Card:getIdList(data.card))
    local name = data.card.trueName
    for _, p in ipairs(players) do
      if not p.dead and room:askToSkillInvoke(p, {
        skill_name = keming.name,
        prompt = "#keming-invoke::"..player.id,
      }) then
        local cards = room:getCardsFromPileByRule(name, math.min(x, 5))
        if #cards < 5 then
          x = x - #cards
          if x > 0 then
            table.insertTable(cards, room:getCardsFromPileByRule(name, math.min(x, 5), "discardPile"))
          end
        end
        if #cards > 0 then
          room:moveCardTo(cards, Card.PlayerHand, p, fk.ReasonJustMove, keming.name, nil, false, p)
        end
      end
    end
  end,
})

keming:addEffect(fk.AfterCardsMove, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    local phases = { Player.Start, Player.Finish, Player.Play }
    if player:getMark("@@keming") ~= 0 and table.contains(phases, player.phase) then
      local room = player.room
      local e = room.logic:getCurrentEvent().parent
      if not e or e.event ~= GameEvent.SkillEffect then return false end
      local d = e.data
      if d.who ~= player or not d.skill:isPlayerSkill(player) or
        not player:hasSkill(d.skill:getSkeleton().name, true, true) then return false end
      e = e.parent
      if not e or e.event ~= GameEvent.Phase then return false end
      d = e.data
      if d.who ~= player or not table.contains(phases, d.phase) then return false end
      local cards = {}
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand and move.moveReason == fk.ReasonDraw then
          for _, info in ipairs(move.moveInfo) do
            table.insert(cards, info.cardId)
          end
        end
      end
      if #cards > 0 then
        event:setCostData(self, { extra_data = cards })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local players = player:getTableMark("@@keming")
    room:setPlayerMark(player, "@@keming", 0)
    local names = {}
    local nmap = {}
    local cards = event:getCostData(self).extra_data
    for _, id in ipairs(cards) do
      local name = Fk:getCardById(id, true).trueName
      table.insertIfNeed(names, name)
      nmap[name] = (nmap[name] or 0) + 1
    end
    room:sortByAction(players)
    for _, p in ipairs(players) do
      if not p.dead and room:askToSkillInvoke(p, {
        skill_name = keming.name,
        prompt = "#keming-invoke::"..player.id,
      }) then
        local toObtain = {}
        local toObtain1 = {}
        for _, name in ipairs(names) do
          local tmp_cards = {}
          local n = nmap[name] or 1
          local n1 = 5 - #toObtain
          if n1 > 0 then
            n1 = math.min(n1, n)
            tmp_cards = room:getCardsFromPileByRule(name, n1)
            if #tmp_cards > 0 then
              table.insertTable(toObtain, tmp_cards)
              if #toObtain >= 5 then break end
            end
          end
          n = math.min(5 - #toObtain1, n - #tmp_cards)
          if n > 0 then
            tmp_cards = room:getCardsFromPileByRule(name, n, "discardPile")
            if #tmp_cards > 0 then
              table.insertTable(toObtain1, tmp_cards)
              if #toObtain1 >= 5 then break end
            end
          end
        end
        table.insertTable(toObtain, toObtain1)
        if #toObtain > 0 then
          room:moveCardTo(toObtain, Card.PlayerHand, p, fk.ReasonJustMove, keming.name, nil, false, p)
        end
      end
    end
  end,
})

keming:addAcquireEffect(function(self, player, is_start, src)
  local room = player.room
  if not room:getBanner(keming.name) then
    local skills = {}
    for name, general in pairs(Fk.generals) do
      if Fk:canUseGeneral(name) then
        local general_name = Fk:translate(name, "zh_CN")
        if (general_name[1] == "曹" or (general_name:len() > 1 and general_name[2] == "曹")) and name ~= "ty__godcaopi" then
          for _, skill_name in ipairs(general:getSkillNameList(true)) do
            local skel = Fk.skills[skill_name]:getSkeleton()
            for _, skill in ipairs(skel.effects) do
              if skill:isInstanceOf(TriggerSkill) and skill.event == fk.Damaged then
                table.insert(skills, skill_name)
                break
              end
            end
          end
        end
      end
    end
    room:setBanner(keming.name, skills)
  end
end)

keming:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return keming
