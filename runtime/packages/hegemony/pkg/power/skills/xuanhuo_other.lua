local xuanhuo_other = fk.CreateSkill {
  name = "ld__xuanhuo_other&",
}

local H = require "packages.hegemony.util"

xuanhuo_other:addEffect("active", {
  prompt = "#xuanhuo-other",
  can_use = function(self, player)
    return player:usedSkillTimes(xuanhuo_other.name, Player.HistoryPhase) == 0 and
    table.find(Fk:currentRoom().alive_players, function(p)
      return p:hasSkill("ld__xuanhuo") and H.compareKingdomWith(p, player) and p ~= player
    end)
  end,
  card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.filter(room:getOtherPlayers(player, false),
      function(p) return p:hasShownSkill("ld__xuanhuo") and H.compareKingdomWith(p, player) end)
    if #targets == 0 then return false end
    local to
    if #targets == 1 then
      to = targets[1]
    else
      to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        skill_name = xuanhuo_other.name,
        cancelable = false,
      })[1]
    end
    room:doIndicate(player.id, { to.id })
    to:broadcastSkillInvoke("ld__xuanhuo")
    room:moveCardTo(effect.cards, Player.Hand, to, fk.ReasonGive, xuanhuo_other.name, nil, false, to)
    if player:isNude() or not room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = xuanhuo_other.name,
          cancelable = false,
          prompt = "#ld__xuanhuo-ask",
        }) then
      return false
    end
    if player.dead then return false end
    local all_choices = { "xuanhuo__hs__wusheng", "xuanhuo__hs__paoxiao", "xuanhuo__hs__longdan", "xuanhuo__hs__tieqi",
      "xuanhuo__hs__liegong", "xuanhuo__hs__kuanggu" }
    local choices = {}
    local skills = {}
    for _, p in ipairs(room.alive_players) do
      for _, s in ipairs(p.player_skills) do
        table.insert(skills, s.name)
      end
    end
    for _, skill in ipairs(all_choices) do
      local skillNames = { skill, skill:sub(10) }
      local can_choose = true
      for _, sname in ipairs(skills) do
        if table.contains(skillNames, sname) then
          can_choose = false
          break
        end
      end
      if can_choose then table.insert(choices, skill) end
    end
    if #choices == 0 then return false end

    local choice = room:askToChoice(player,
      { choices = choices, skill_name = xuanhuo_other.name, prompt = "#ld__xuanhuo-choice", detailed = true, all_choices =
      all_choices })
    room:handleAddLoseSkills(player, choice, nil)
    room:addTableMark(player, "@ld__xuanhuo_skills-turn", choice)
  end,
})

xuanhuo_other:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    if type(player:getMark("@ld__xuanhuo_skills-turn")) ~= "table" then return false end
    return target == player and player.phase == Player.Finish
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local _skills = player:getMark("@ld__xuanhuo_skills-turn")
    local skills = "-" .. table.concat(_skills, "|-")
    room:handleAddLoseSkills(player, skills, nil)
    room:setPlayerMark(player, "@ld__xuanhuo_skills-turn", 0)
  end,
})

xuanhuo_other:addEffect(fk.GeneralRevealed, {
  can_refresh = function(self, event, target, player, data)
    if type(player:getMark("@ld__xuanhuo_skills-turn")) ~= "table" then return false end
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = {}
    table.forEach(room.alive_players, function(p) table.insertTable(skills, p.player_skills) end)
    local xuanhuoSkills = player:getMark("@ld__xuanhuo_skills-turn")
    if type(xuanhuoSkills) == "table" then
      local detachList = {}
      for _, skill in ipairs(skills) do
        local skillName = "xuanhuo__" .. skill.name
        if (table.contains(xuanhuoSkills, skillName)) then
          table.removeOne(xuanhuoSkills, skillName)
          table.insert("-" .. skillName)
        end
      end
      if #detachList > 0 then
        room:handleAddLoseSkills(player, table.concat(detachList, "|"), nil)
        room:setPlayerMark(player, "@ld__xuanhuo_skills-turn", #xuanhuoSkills > 0 and xuanhuoSkills or 0)
      end
    end
  end,
})

Fk:loadTranslationTable {
  ["ld__xuanhuo_other&"] = "眩惑",
  [":ld__xuanhuo_other&"] = "你可交给法正一张手牌，然后弃置一张牌，选择下列技能中的一个：〖武圣〗〖咆哮〗〖龙胆〗〖铁骑〗〖烈弓〗〖狂骨〗（场上已有的技能无法选择）。你于此回合内或明置有以此法选择的技能的武将牌之前拥有以此法选择的技能。",
  ["#xuanhuo-other"] = "眩惑：你可交给法正一张手牌，然后弃置一张牌",
  ["#ld__xuanhuo-ask"] = "眩惑：弃置一张牌",
  ["@ld__xuanhuo_skills-turn"] = "眩惑",
  ["#ld__xuanhuo-choice"] = "眩惑：选择一个技能获得",
}

return xuanhuo_other
