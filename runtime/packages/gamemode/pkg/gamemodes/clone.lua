local m_clone_desc = [[

# 克隆大作战模式简介

  <font color="red">本模式选将框数被强制锁定在4-8之间。</font>

  若干名玩家结成两个阵营、使用相同武将牌进行对战的竞技模式。

  ___

  ## 阵营/座次分布

  分为龙军和虎军两个阵营，以龙-虎-龙-虎-……的顺序交替排列座次。

  ___

  ## 胜利条件

  消灭敌方阵营的所有人。

  ___

  ## 选将流程

  游戏开始前，双方各展示4张武将牌，交由阵营内玩家进行限时投票。

  计时结束后，从票数最多的武将牌中选择作为本方阵营共用的武将。

  亮出武将牌后，游戏开始。

  ___

  ## 击杀奖惩

  一名角色死亡后，同势力角色各摸一张牌。

  ---

  ## 特殊禁将

  以下武将被禁止使用：

  - 刘禅 秦始皇
]]

local m_clone_getLogic = function()
  local m_clone_logic = GameLogic:subclass("m_clone_logic")

  function m_clone_logic:initialize(room)
    GameLogic.initialize(self, room)
  end

  function m_clone_logic:assignRoles()
    -- 由于需要调整座位， 所以在这里不分配身份
  end

  function m_clone_logic:adjustSeats()
    local room = self.room

    local player_clone = table.simpleClone(room.players)
    local true_players = table.filter(room.players, function(p)
      return p.id > 0
    end)
    room:shuffleTable(player_clone)
    if #true_players < #player_clone then -- 有人机时方便调试
      table.removeOne(player_clone, true_players[1])
      table.insert(player_clone, 1, true_players[1])
      if true_players[2] then
        table.removeOne(player_clone, true_players[2])
        table.insert(player_clone, 3, true_players[2])
      end
    end

    room:arrangeSeats(player_clone)
    local player_length = #room.players

    for i = 1, player_length do
      local p = room.players[i]
      if i % 2 == 1 then
        p.role = "loyalist"
      else
        p.role = "rebel"
      end
      room:setPlayerProperty(p, "role_shown", true)
      room:broadcastProperty(p, "role")
    end
    if not room:getSettings("m_clone_blockViews") then
      for i, p in ipairs(room.players) do
        for j = 1, player_length / 2 do
            p:addBuddy(room.players[(i + j * 2 - 1) % player_length + 1])
        end
      end
    end
    room:setCurrent(room.players[1])
  end

  --- 真人测试用
  --[[ function m_clone_logic:adjustSeats()
    local room = self.room
    local true_players = table.filter(room.players, function(p)
      return p.id > 0
    end)
    local player_clone = table.simpleClone(room.players)
    for _, p in ipairs(true_players) do
      table.removeOne(player_clone, p)
    end
    table.insert(player_clone, 1, true_players[1])
    if true_players[2] then
      table.insert(player_clone, 3, true_players[2])
    end

    room:arrangeSeats(player_clone)

    for i = 1, #room.players do
      local p = room.players[i]
      p.role = self.role_table[1][i]
      room:setPlayerProperty(p, "role_shown", true)
      room:broadcastProperty(p, "role")
    end
  end ]]

  function m_clone_logic:chooseGenerals()
    local room = self.room
    local generalNum = math.min(math.max(room:getSettings("generalNum"), 4), 8)

    local blacklist = { "liushan", "ofl__yingzheng" }
    local allSame = self.room:getSettings("m_clone_allOnes")

    local players = room.players
    local a2 = (allSame and 1 or 2) * generalNum
    local generals = table.map(table.filter(Fk:getGeneralsRandomly(
      a2, nil, nil, nil, room:getSettings("disableSameConvert")
    ), function(g)
      return not table.contains(blacklist, g.trueName)
    end), Util.NameMapper)
    local a1 = #Fk:getAllGenerals(blacklist)
    if a1 < a2 then
      room:sendLog{
        type = "#NoEnoughGeneralDraw",
        arg = a1,
        arg2 = a2,
        toast = true,
      }
      room:gameOver("")
    end
    room:shuffleTable(generals)
    local t1 = table.slice(generals, 1, generalNum + 1)
    local t2 = allSame and table.simpleClone(t1) or table.slice(generals, generalNum + 1, generalNum * 2 + 1)

    local data_table = {}
    local player_length = #players
    local timeout = self.room:getSettings("generalTimeout")
    for index, to in ipairs(players) do
      local friend_ids = {}
      if allSame then
        friend_ids = table.map(table.filter(players, function(p)
        return p ~= to
      end), Util.IdMapper)
      else
        for j = 1, player_length / 2 do
          table.insert(friend_ids, players[(index + j * 2 - 1) % player_length + 1].id)
        end
      end
      data_table[to.id] = {
        pool = allSame and t1 or (index % 2 == 0 and t2 or t1),
        prop = {
          friends = friend_ids,
          timeout = timeout
        }
      }
    end

    local req = room:askToMiniGame(players, {
      skill_name = "AskForGeneral",
      game_type = "clone_sel",
      data_table = data_table,
      timeout = timeout + 5 -- 缓冲时间
    })
    local pool1, pool2 = {}, {}
    for _, p in ipairs(players) do
      local target_pool = allSame and pool1 or (p.role == "loyalist" and pool1 or pool2)
      if p.id > 0 then
        -- 人机投票不计入
        local general = req:getResult(p)[1] or (p.role == "loyalist" and t1 or t2)[1]
        target_pool[general] = (target_pool[general] or 0) + 1
      end
    end
    --- 实际武将赋值
    local pool_max, max = {}, 0
    local max_general
    for general, count in pairs(pool1) do
      if count > max then
        max = count
        pool_max = { general }
      elseif count == max then
        table.insert(pool_max, general)
      end
    end
    max_general = pool_max[1] and room:tableRandomPick(pool_max) or t1[1]
    room:findGeneral(max_general)
    if allSame then
      for i = 1, player_length do
        room:setPlayerGeneral(players[i], max_general, true, true)
      end
    else
      for i = 1, player_length, 2 do
        room:setPlayerGeneral(players[i], max_general, true, true)
      end
      pool_max, max = {}, 1
      for general, count in pairs(pool2) do
        if count > max then
          max = count
          pool_max = { general }
        elseif count == max then
          table.insert(pool_max, general)
        end
      end
      max_general = pool_max[1] and room:tableRandomPick(pool_max) or t2[1]
      room:findGeneral(max_general)
      for i = 2, player_length, 2 do
        room:setPlayerGeneral(players[i], max_general, true, true)
      end
    end

    room:askToChooseKingdom(players)
  end

  return m_clone_logic
end

local m_clone_mode = fk.CreateGameMode {
  name = "m_clone_mode",
  playerNums = {4, 6, 8},
  logic = m_clone_getLogic,
  rule = "#m_clone_rule&",
  surrender_func = function(self, playedTime, player)
    local surrenderJudge = { { text = "clone: left you alive", passed = table.every(Fk:currentRoom().players, function(p)
      return p.role ~= player.role or (p == player or (p.dead and p.rest == 0))
    end) and true } }
    return surrenderJudge
  end,
  reward_punish = function (self, victim, killer)
    local room = victim.room
    for _, p in ipairs(room.alive_players) do
      if p.role == victim.role and not p.dead then
        p:drawCards(1, "game_rule")
      end
    end
  end,
}

local W = require "ui_emu.preferences"
m_clone_mode.ui_settings = {
  W.PreferenceGroup {
    title = "Game Rule",
    W.SwitchRow {
      _settingsKey = "m_clone_blockViews",
      title = "m_clone_block_views",
    },
    W.SwitchRow {
      _settingsKey = "m_clone_allOnes",
      title = "m_clone_all_ones",
      subTitle = ":m_clone_all_ones",
    }
  }
}

Fk:loadTranslationTable {
  ["m_clone_mode"] = "克隆大作战",
  [":m_clone_mode"] = m_clone_desc,

  ["time limitation: 1 min"] = "游戏时长达到1分钟",
  ["clone: left you alive"] = "你所处队伍仅剩你存活",

  ["m_clone_block_views"] = "队友手牌不可见",
  ["#m_clone_block_views"] = "队友手牌不可见",

  ["m_clone_all_ones"] = "全同模式",
  [":m_clone_all_ones"] = "所有玩家一起投票，票数最多的武将作为双方阵营共用武将",
  ["#m_clone_all_ones"] = "所有玩家共用武将",

  ["#CloneVote"] = "请为你心怡的武将投下一票！",
}

Fk:addMiniGame {
  name = "clone_sel",
  qml_path = "packages/gamemode/qml/clone",
  default_choice = function(player, data)
    return { data.pool[1] }
  end,
  update_func = function(player, data)
    local room = player.room
    local d = player.mini_game_data.data.prop
    for _, friend_id in ipairs(d.friends) do
      room:getPlayerById(friend_id):doNotify("UpdateMiniGame", data)
    end
  end,
  model = function(player, data)
    return {
      uri = "LunarLtk.Models.Popups",
      name = "ChooseGeneralModel",
      prop = {
        prompt = "#CloneVote",
        generals = data.pool,
      },
    }
  end,
}

return m_clone_mode
