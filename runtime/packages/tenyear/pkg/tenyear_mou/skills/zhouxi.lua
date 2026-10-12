local zhouxi = fk.CreateSkill {
  name = "ty__zhouxi",
}

Fk:loadTranslationTable{
  ["ty__zhouxi"] = "骤袭",
  [":ty__zhouxi"] = "出牌阶段限一次，你弃置所有当前无法指定其他角色目标的手牌，根据弃牌数依次选择等量项："..
    "1.本回合与其他角色距离-X；2.视为对至多X名角色使用【顺手牵羊】；3.视为对至多X名角色使用【杀】。"..
    "若你执行了所有选项此技能视为未使用过（X为该项被选择的次序）。",

  ["#ty__zhouxi"] = "骤袭：弃置所有当前无法指定其他角色目标的手牌",
  ["ty__zhouxi_distance"] = "本回合与其他角色距离-%arg",
  ["ty__zhouxi_snatch"] = "视为对至多%arg名角色使用【顺手牵羊】",
  ["ty__zhouxi_slash"] = "视为对至多%arg名角色使用【杀】",
  ["@ty__zhouxi-turn"] = "骤袭",
  ["#ty__zhouxi-use"] = "骤袭：你可以视为使用【%arg】，选择%arg2名目标角色",

  ["$ty__zhouxi1"] = "不战胜，毋宁死！",
  ["$ty__zhouxi2"] = "疾风卷赤帜，山雨摧危楼！",
}

zhouxi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty__zhouxi",
  can_use = function(self, player)
    return player:usedSkillTimes(zhouxi.name, Player.HistoryPhase) == 0 and
      table.find(player:getCardIds("h"), function(id)
        if player:prohibitDiscard(id) then return false end
        return table.every(Fk:getCardById(id):getAvailableTargets(player), function(p) return p == player end)
      end)
  end,
  target_num = 0,
  card_num = 0,
  card_filter = Util.FalseFunc,
  visible_pile = function(self, player)
    return table.filter(player:getCardIds("h"), function(id)
      if player:prohibitDiscard(id) then return false end
      return table.every(Fk:getCardById(id):getAvailableTargets(player), function(p) return p == player end)
    end)
  end,
  on_use = function(self, room, effect)
    local skillName = zhouxi.name
    local player = effect.from
    local cards = table.filter(player:getCardIds("h"), function(id)
      if player:prohibitDiscard(id) then return false end
      return table.every(Fk:getCardById(id):getAvailableTargets(player), function(p) return p == player end)
    end)
    if #cards == 0 then return end
    room:throwCard(cards, skillName, player, player)
    local choices = {"ty__zhouxi_distance", "ty__zhouxi_snatch", "ty__zhouxi_slash"}
    local effects = {}
    local times = {0, 0, 0}
    for i = 1, math.min(#cards, 3), 1 do
      local _choices = {}
      local all_choices = {}
      for j = 1, 3, 1 do
        local k = times[j]
        if k == 0 then
          table.insert(_choices, choices[j] .. ":::" .. i)
          table.insert(all_choices, choices[j] .. ":::" .. i)
        else
          table.insert(all_choices, choices[j] .. ":::" .. k)
        end
      end
      local choice = room:askToChoice(player, {
        choices = _choices,
        skill_name = skillName,
        all_choices = all_choices,
      })
      if choice:startsWith("ty__zhouxi_distance") then
        times[1] = i
        table.insert(effects, "distance")
      elseif choice:startsWith("ty__zhouxi_snatch") then
        times[2] = i
        table.insert(effects, "snatch")
      else
        times[3] = i
        table.insert(effects, "slash")
      end
    end
    for i, choice in ipairs(effects) do
      if choice == "distance" then
        room:addPlayerMark(player, "@ty__zhouxi-turn", i)
      else
        local card = Fk:cloneCard(choice)
        card.skillName = skillName
        local targets  = table.filter(room.alive_players, function(p)
          return player:canUseTo(card, p, { bypass_times = true })
        end)
        if #targets > 0 then
          targets = room:askToChoosePlayers(player, {
            targets = targets,
            min_num = 1,
            max_num = i,
            prompt = "#ty__zhouxi-use:::" .. choice .. ":" .. i,
            skill_name = skillName,
            cancelable = false
          })
          room:useCard({
            from = player,
            tos = targets,
            card = card,
            extraUse = true
          })
        end
      end
      if player.dead then return end
    end
    if #effects == 3 then
      player:setSkillUseHistory(skillName, 0, Player.HistoryPhase)
    end
  end,
})

zhouxi:addEffect("distance", {
  correct_func = function(self, from, to)
    return -from:getMark("@ty__zhouxi-turn")
  end,
})

return zhouxi
