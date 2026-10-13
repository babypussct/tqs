local desc_brawl = [[
  # 1v2大乱斗模式简介

  ___

  本模式为**斗地主模式的变种模式**，玩家需要自己搭配技能以取得游戏的胜利。游戏由三人进行，一人扮演地主（主公），其他两人扮演农民（反贼）。

  （暂无）<s>游戏开始后，**每位玩家会随机到10个待选技能**，玩家需要根据这些技能，依次叫价1遍，**价高者为地主，额外抽取5个技能**</s>。

  （暂行）随机一名玩家成为**地主**，随机抽取**X*1.5**（向下取整）个技能；2名**农民**各随机抽取**X**个技能。（X为本房间的“选将数目”）

  **地主从中挑选3个作为本局的技能；农民从中挑选2个作为本局的技能**。

  地主5点体力上限，农民4点体力上限。

  地主拥有以下额外技能：

  - **飞扬**：判定阶段开始时，你可以弃置两张手牌并弃置自己判定区内的一张牌。

  - **跋扈**：锁定技，准备阶段，你摸一张牌；出牌阶段，你可以多使用一张杀。

  当农民被击杀后，另一名农民可以选择：摸两张牌，或者回复一点体力。

  *击杀农民的人没有摸三张牌的奖励。*

  胜利规则与身份局一致。

  *禁包、禁将之后其技能不会在技能池中出现。*
]]

-- 排除部分技能
local ban_skills = {
  "fenyong", "danggu", "liuhe" -- 弱智技能
}

local U = require "packages.utility.utility"

local brawl_getLogic = function()
  local brawl_logic = GameLogic:subclass("brawl_logic")

  function brawl_logic:initialize(room)
    GameLogic.initialize(self, room)
    self.role_table = {nil, nil, {"lord", "rebel", "rebel"}}
  end

  function brawl_logic:chooseGenerals()
    local room = self.room
    room:doBroadcastNotify("ShowToast", Fk:translate("#BrawlInitialNotice"))
    for _, p in ipairs(room.players) do
      room:setPlayerProperty(p, "role_shown", true)
      room:broadcastProperty(p, "role")
    end

    local lord = room:getLord() --[[@as ServerPlayer]]
    room:setCurrent(lord)
    local players = room.players
    local skill_num = room:getSettings('generalNum') -- 技能池数量由选将数决定，农民等于，地主1.5倍（向下取整）
    local total = math.floor(skill_num * 3.5)
    local skill_pool, general_pool = {}, {}
    local all_generals = Fk:getAllGenerals() -- 允许同名武将
    local i = 0
    for _ = 1, 999 do
      local general = room:tableRandomPick(all_generals)
      local skills = general:getSkillNameList()
      local skill = room:tableRandomPick(skills) ---@type string
      local des = Fk:translate(":" .. skill, "zh_CN")
      if not table.contains(ban_skills, skill) and not table.contains(skill_pool, skill) and
        -- 排除与势力技、性别（女性、男性、同性、异性）、武将牌上的技能有关的技能
        -- FIXME: "势力[^武]"无法使用
        not (des:find("势力技") or des:find("[^属]性") or des:find("武将牌上的.?.?.?.?.?.?技能")) then
        i = i + 1
        table.insert(skill_pool, skill)
        table.insert(general_pool, general.name)
        if i == total then break end
      end
    end
    if i < total then
      room:gameOver("")
    end

    local special_generals = { "mouxusheng", "hiddenone", "anjiang" } -- 特殊武将列表
    local skillsMap, generalsMap, minNumMap, maxNumMap, promptMap = {}, {}, {}, {}, {}
    for k, p in ipairs(players) do
      local avatar = p._splayer:getAvatar()
      if table.contains(special_generals, avatar) then
        room:doBroadcastNotify("ShowToast", Fk:translate("#BrawlBanSpecialGeneral"))
        avatar = room:tableRandomPick{ "blank_shibing", "blank_nvshibing" }
      end
      local avatar_general = Fk.generals[avatar] or Fk.generals["sunce"] or Fk.generals["diaochan"]
      room:setPlayerGeneral(p, avatar_general.name, true)
      room:broadcastProperty(p, "general")
      room:setPlayerProperty(p, "shield", 0)
      room:setPlayerProperty(p, "maxHp", p.role == "lord" and 5 or 4)
      room:setPlayerProperty(p, "hp", p.role == "lord" and 5 or 4)

      k = 4 - p.seat
      local skills, generals
      if k == 3 then
        skills = table.slice(skill_pool, skill_num * 2 + 1, total + 1)
        generals = table.slice(general_pool, skill_num * 2 + 1, total + 1)
      else
        skills = table.slice(skill_pool, skill_num * (k - 1) + 1 , skill_num * k + 1)
        generals = table.slice(general_pool, skill_num * (k - 1) + 1 , skill_num * k + 1)
      end
      table.insert(skillsMap, skills)
      table.insert(generalsMap, generals)
      local num = p.role == "lord" and 3 or 2
      table.insert(minNumMap, num)
      table.insert(maxNumMap, num)
      table.insert(promptMap, "#brawl-choose:::" .. tostring(num))
    end

    local result = U.askToJointSkills(players[1], {
      timeout = self.room:getSettings('generalTimeout'),
      players = players,
      skill_name = "AskForGeneral",
      skills = skillsMap,
      generals = generalsMap,
      min_num = minNumMap,
      max_num = maxNumMap,
      prompt = promptMap,
    })

    for _, p in ipairs(players) do
      local choice = result[p]
      room:setPlayerMark(p, "_brawl_skills", choice)
      choice = table.map(choice, Util.TranslateMapper)
      room:setPlayerMark(p, "@brawl_skills", "<font color='burlywood'>" .. table.concat(choice, " ") .. "</font>")
    end

  end

  function brawl_logic:broadcastGeneral()
  end

  function brawl_logic:attachSkillToPlayers()
    local room = self.room
    room:doBroadcastNotify("ShowToast", Fk:translate("#BrawlInitialNotice"))
    for _, p in ipairs(room.alive_players) do
      local skills = table.concat(p:getMark("_brawl_skills"), "|")
      if p.role == "lord" and room:getSettings("addLordSkill") then
        skills = skills .."|m_feiyang|m_bahu"
      end
      room:handleAddLoseSkills(p, skills, nil, true)
    end
  end

  return brawl_logic
end

local W = require "ui_emu.preferences"

local settings = {
  W.PreferenceGroup {
    title = "brawl_additional_rule",

    W.SwitchRow {
      _settingsKey = "addLordSkill",
      title = "brawl_add_lord_skill",
    },

  },
}

local brawl_mode = fk.CreateGameMode{
  name = "brawl_mode",
  minPlayer = 3,
  maxPlayer = 3,
  main_mode = "1v2_mode",
  rule = "#1v2_brawl&",
  logic = brawl_getLogic,
  ui_settings = settings,
  surrender_func = function(self, playedTime, player)
    local surrenderJudge = { { text = "time limitation: 2 min", passed = playedTime >= 120 } }
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
  reward_punish = function (self, victim, killer)
    local room = victim.room
    if victim.role == "rebel" then
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
          else
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

Fk:loadTranslationTable{
  ["brawl_mode"] = "1v2大乱斗",
  [":brawl_mode"] = desc_brawl,

  ["#brawl_rule"] = "1v2大乱斗",
  ["#brawl-choose"] = "请选择%arg个技能出战",
  ["@brawl_skills"] = "",

  ["#BrawlInitialNotice"] = "农民抽取技能数为房间“<b>可选武将数</b>”，地主多拿一半（向下取整）<br>地主技能用<b>创房模式设置</b>开关控制，默认关闭",
  ["#BrawlBanSpecialGeneral"] = "特殊武将被强制替换",

  ["brawl_additional_rule"] = "1v2大乱斗附加规则",
  ["brawl_add_lord_skill"] = "地主拥有〖飞扬〗、〖跋扈〗",
}

return brawl_mode
