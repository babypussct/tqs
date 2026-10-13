local desc_1v2 = [[
  # 欢乐斗地主模式简介

  ___

  总体规则类似身份局。游戏由三人进行，一人扮演地主（主公），其他两人扮演农民（反贼）。

  地主选将框+2，增加1点体力上限和体力，且拥有以下额外技能：

  - **飞扬**：判定阶段开始时，你可以弃置两张手牌并弃置自己判定区内的一张牌。

  - **跋扈**：锁定技，准备阶段，你摸一张牌；出牌阶段，你可以多使用一张【杀】。

  当农民被击杀后，另一名农民可以选择：摸两张牌，或者回复1点体力。

  *击杀农民的人没有摸三张牌的奖励。*

  胜利规则与身份局一致。
]]

-- Because packages are loaded before gamelogic.lua loaded
-- so we can not directly create subclass of gamelogic in the top of lua
local m_1v2_getLogic = function()
  local m_1v2_logic = GameLogic:subclass("m_1v2_logic")

  function m_1v2_logic:initialize(room)
    GameLogic.initialize(self, room)
    self.role_table = {nil, nil, {"lord", "rebel", "rebel"}}
  end

  function m_1v2_logic:chooseGenerals()
    local room = self.room ---@type Room
    local generalNum = room:getSettings('generalNum')
    for _, p in ipairs(room.players) do
      room:setPlayerProperty(p, "role_shown", true)
      room:broadcastProperty(p, "role")
    end

    local lord = room:getLord() --[[@as ServerPlayer]]
    room:setCurrent(lord)
    local players = room.players
    -- 地主多发俩武将
    local generals = room:getNGenerals(#players * generalNum + 2)
    local req = Request:new(players, "AskForGeneral")
    req.timeout = self.room:getSettings('generalTimeout')
    for i, p in ipairs(players) do
      local arg = table.slice(generals, (i - 1) * generalNum + 1, i * generalNum + 1)
      if p.role == "lord" then
        local count = #generals
        table.insert(arg, generals[count])
        table.insert(arg, generals[count - 1])
      end
      req:setData(p, { arg, 1 })
      req:setDefaultReply(p, { arg[1] })
    end
    req:ask()
    local selected = {}
    for _, p in ipairs(players) do
      local general_ret
      general_ret = req:getResult(p)[1]
      room:setPlayerGeneral(p, general_ret, true, true)
      table.insertIfNeed(selected, general_ret)
    end
    generals = table.filter(generals, function(g) return not table.contains(selected, g) end)
    room:returnToGeneralPile(generals)
    for _, g in ipairs(selected) do
      room:findGeneral(g)
    end
    room:askToChooseKingdom(players)

    for _, p in ipairs(players) do
      room:broadcastProperty(p, "general")
    end

    if room:getSettings("buddyRebel") then
      room.players[2]:addBuddy(room.players[3])
      room.players[3]:addBuddy(room.players[2])
    end
  end


  function m_1v2_logic:attachSkillToPlayers()
    local room = self.room

    local addRoleModSkills = function(player, skillName)
      local skill = Fk.skills[skillName]
      if not skill then
        fk.qCritical("Skill: "..skillName.." doesn't exist!")
        return
      end
      if skill:hasTag(Skill.Lord) then
        return
      end
      if skill:hasTag(Skill.AttachedKingdom) and not table.contains(skill:getSkeleton().attached_kingdom, player.kingdom) then
        return
      end
      room:handleAddLoseSkills(player, skillName, nil, false)
    end
    for _, p in ipairs(room.alive_players) do
      for _, s in ipairs(Fk.generals[p.general]:getSkillNameList(false)) do
        addRoleModSkills(p, s)
      end
      if p.role == "lord" then
        local skills = {}
        if room:getSettings("enableOLFeiyang") then
          table.insert(skills, "ol_feiyang")
        else
          table.insert(skills, "m_feiyang")
        end
        table.insert(skills, "m_bahu")
        if room:getSettings("enableQiangyi") then
          table.insert(skills, "m_qiangyi")
        end
        if room:getSettings("enableShiqiang") then
          table.insert(skills, "m_shiqiang")
        end
        room:handleAddLoseSkills(p, skills, nil, false)
      end
    end
  end

  return m_1v2_logic
end

local m_1v2_mode = fk.CreateGameMode{
  name = "m_1v2_mode",
  minPlayer = 3,
  maxPlayer = 3,
  main_mode = "1v2_mode",
  logic = m_1v2_getLogic,
  surrender_func = function(self, playedTime, player)
    local surrenderJudge = { { text = "time limitation: 1 min", passed = playedTime >= 60 } }
    if player.role ~= "lord" then
      table.insert(surrenderJudge, {
        text = "1v2: left you alive",
        passed = not table.every(Fk:currentRoom().players, function(p)
          return p.rest > 0 or not p.dead
        end)
      })
    end
    return surrenderJudge
  end,
  get_adjusted = function (self, player)
    if player.role == "lord" then
      return {hp = player.hp + 1, maxHp = player.maxHp + 1}
    end
    return {}
  end,
  reward_punish = function (self, victim, killer)
    local room = victim.room
    if victim.role == "rebel" and not room:getSettings("noRebelReward") then
      for _, p in ipairs(room:getOtherPlayers(victim)) do
        if p.role == "rebel" then
          local choices = {"draw2", "Cancel"}
          if p:isWounded() then
            table.insert(choices, 2, "recover")
          end
          local choice = room:askToChoice(p, {
            choices = choices,
            skill_name = "PickLegacy",
          })
          if choice == "draw2" then
            p:drawCards(2, "game_rule")
          elseif choice == "recover" then
            room:recover{
              who = p,
              num = 1,
              recoverBy = p,
              skillName = "game_rule",
            }
          end
        end
      end
    end
  end,
}

local W = require "ui_emu.preferences"
m_1v2_mode.ui_settings = {
  W.PreferenceGroup {
    title = "m_1v2_enhance_lord",

    W.SwitchRow {
      _settingsKey = "enableOLFeiyang",
      title = "m_1v2_lord_olfeiyang",
    },

    W.SwitchRow {
      _settingsKey = "enableQiangyi",
      title = "m_1v2_lord_getqiangyi",
    },

    W.SwitchRow {
      _settingsKey = "enableShiqiang",
      title = "m_1v2_lord_getshiqiang",
    },

    W.SwitchRow {
      _settingsKey = "noRebelReward",
      title = "m_1v2_no_reward",
    },
  },

  W.PreferenceGroup {
    title = "m_1v2_enhance_rebel",

    W.SwitchRow {
      _settingsKey = "buddyRebel",
      title = "m_1v2_rebel_buddy",
    },
  },
}

Fk:loadTranslationTable{
  ["m_1v2_mode"] = "欢乐斗地主",
  [":m_1v2_mode"] = desc_1v2,

  ["PickLegacy"] = "挑选遗产",

  ["time limitation: 1 min"] = "游戏时长达到1分钟",
  ["1v2: left you alive"] = "仅剩你和地主存活",

  ["m_1v2_enhance_lord"] = "地主增强",
  ["m_1v2_lord_olfeiyang"] = "地主专属技能〖飞扬〗",
  ["help: m_1v2_lord_olfeiyang"] = "(OL) 弃置两张牌，弃置判定区所有牌(而非仅弃置一张)",
  ["m_1v2_lord_getqiangyi"] = "地主专属技能〖强易〗",
  ["help: m_1v2_lord_getqiangyi"] = "(比赛服) 每人限一次，获得其一张手牌并交还一张",
  ["m_1v2_lord_getshiqiang"] = "地主专属技能〖恃强〗",
  ["help: m_1v2_lord_getshiqiang"] = "(手杀巅峰赛) 可印杀并摸一，未杀中则自己减上限",
  ["m_1v2_no_reward"] = "农民无队友阵亡补偿",
  ["help: m_1v2_no_reward"] = "(新服) 农民阵亡后，存活角色没有回血或摸牌的补偿",

  ["m_1v2_enhance_rebel"] = "农民增强",
  ["m_1v2_rebel_buddy"] = "农民卡牌互通",
  ["help: m_1v2_rebel_buddy"] = "(OL, 新服) 农民可以看到彼此的手牌",
}

return m_1v2_mode
