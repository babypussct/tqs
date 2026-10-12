local jianan = fk.CreateSkill {
  name = "jianan",
  tags = { Skill.Compulsory },
  related_skills = { "jianan__ld__jieyue", "jianan__ex__tuxi", "jianan__qiaobian", "jianan__hs__duanliang", "jianan__hs__xiaoguo" },
}

Fk:loadTranslationTable {
  ["jianan"] = "建安",
  [":jianan"] = "<b><font color='goldenrod'>君主技</font></b>，你拥有“五子良将纛”。<br>" ..
      "#<b>五子良将纛</b>：魏势力角色的准备阶段，其可弃置一张牌并选择一张暗置的武将牌或暗置两张已明置武将牌中的其中一张，" ..
      "若如此做，其获得〖节钺〗〖突袭〗〖巧变〗〖骁果〗〖断粮〗中一个场上没有的技能，" ..
      "且不能明置以此法选择或暗置的武将牌，直至你回合开始。",

  ["#jianan-ask"] = "五子良将纛：你可弃置一张牌，暗置一张武将牌，选择获得〖节钺〗〖突袭〗〖巧变〗〖骁果〗〖断粮〗",
  ["#jianan-choice"] = "五子良将纛：获得以下一个技能",

  ["@jianan_skills"] = "良将纛",

  ["$jianan1"] = "设使天下无孤，不知几人称帝，几人称王。",
  ["$jianan2"] = "行为军锋，还为后拒！",
  ["$jianan3"] = "国之良将，五子为先！",
}

local H = require "packages.hegemony.util"
local U = require "packages.utility.utility"

jianan:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not (target == player and not target:isNude() and target.phase == Player.Start) then return end
    local lord = H.getHegLord(player.room, player)
    if lord and lord:hasSkill(jianan.name) then return true end
  end,
  on_cost = function(self, event, target, player, data)
    if #player.room:askToDiscard(target, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = jianan.name,
          prompt = "#jianan-ask",
          cancelable = true,
        }) > 0 then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local isDeputy = false
    if H.getGeneralsRevealedNum(target) == 1 then
      if target.general ~= "anjiang" and not target.general:startsWith("blank_") then
        isDeputy = true
      elseif target.deputyGeneral ~= "anjiang" and not target.deputyGeneral:startsWith("blank_") then
        isDeputy = false
      end
    elseif H.getGeneralsRevealedNum(target) == 2 then
      isDeputy = H.doHideGeneral(room, target, target, jianan.name)
    end
    local record = target:getTableMark(MarkEnum.RevealProhibited)
    table.insert(record, isDeputy and "d" or "m")
    room:setPlayerMark(target, MarkEnum.RevealProhibited, record)

    local all_choices = { "jianan__ld__jieyue", "jianan__ex__tuxi", "jianan__qiaobian", "jianan__hs__duanliang", "jianan__hs__xiaoguo" }
    local choices = {}
    local skills = {}
    for _, p in ipairs(room.alive_players) do
      for _, s in ipairs(p.player_skills) do
        table.insert(skills, s.name)
      end
    end
    for _, skill in ipairs(all_choices) do
      local skillNames = { skill, skill:sub(9) }
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
    local choice = U.askToChooseSkills(target, {
      skill_name = jianan.name,
      skills = choices,
      prompt = "#jianan-choice",
    })[1]
    room:handleAddLoseSkills(target, choice, nil)
    record = target:getTableMark("@jianan_skills")
    table.insert(record, choice)
    room:setPlayerMark(target, "@jianan_skills", record)
  end,
})

local jianan_spec = {
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      local _skills = p:getMark("@jianan_skills")
      if _skills ~= 0 then
        local skills = "-" .. table.concat(_skills, "|-")
        room:handleAddLoseSkills(p, skills, nil)
        room:setPlayerMark(p, "@jianan_skills", 0)
      end
      room:setPlayerMark(p, MarkEnum.RevealProhibited, 0)
    end
  end,
}

jianan:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianan.name)
  end,
  on_refresh = jianan_spec.on_refresh,
})

jianan:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(jianan.name, false, true) and target == player
  end,
  on_refresh = jianan_spec.on_refresh,
})

return jianan
