local desc_2v2 = [[
  # 2v2简介

  游戏由两名忠臣和两名反贼进行，胜利目标为击杀所有敌人。

  座位排列固定是忠-反-反-忠。

  一名角色死亡后，其队友会摸一张牌。

  第一回合角色摸牌阶段少摸一张牌。四号位多摸一张初始手牌。

  队友手牌可见。
]]

---@param room Room
local function summonBots(room)
  local lord = room.players[1]
  local nonlord = room.players[2]
  local p1 = room:summonPlayer(lord, nonlord, {
    skip_preparation = true, send_log = false,
  })
  ---@cast p1 -nil
  local p2 = room:summonPlayer(nonlord, nonlord, {
    skip_preparation = true, send_log = false,
  })
  ---@cast p2 -nil

  room:swapSeat(nonlord, p1, false)
end

-- 禁将BP状态机：轮询顺序 3、1、4、2 号位，每支队伍禁将 banNum 次后结束
local function m_2v2_bpTeamOfSeat(seat)
  return (seat == 1 or seat == 4) and "loyalist" or "rebel"
end

-- 一控多时同一个控制器对应多个角色，小游戏只向每个控制器发一份请求。
local function m_2v2_controlPlayers(room)
  local ret = {}
  for _, p in ipairs(room.players) do
    if not table.find(ret, function(other) return other.serverplayer == p.serverplayer end) then
      table.insert(ret, p)
    end
  end
  return ret
end

local function m_2v2_controlledIds(room, player)
  return table.map(table.filter(room.players, function(p)
    return p.serverplayer == player.serverplayer
  end), function(p)
    return p.id
  end)
end

local function m_2v2_controlsPlayer(room, player, playerId)
  local target = room:getPlayerById(playerId)
  return target ~= nil and target.serverplayer == player.serverplayer
end

-- 当前控制视角有时仍以被控制角色的 ID 上报；让同一控制器名下的角色都能路由小游戏事件。
local function m_2v2_askMiniGame(room, players, params)
  for _, p in ipairs(room.players) do
    local controller = table.find(players, function(candidate)
      return candidate.serverplayer == p.serverplayer
    end)
    if controller then
      p.mini_game_data = {
        type = params.game_type,
        data = params.data_table[controller.id],
      }
    end
  end

  room:askToMiniGame(players, params)

  for _, p in ipairs(room.players) do
    p.mini_game_data = nil
  end
end

--- 从 st.curPos 起寻找下一个仍需禁将的座位
---@return integer? playerId, integer? newPos
local function m_2v2_bpNextTurn(st)
  local n = #st.seatOrder
  for i = 0, n - 1 do
    local pos = ((st.curPos - 1 + i) % n) + 1
    local seat = st.seatOrder[pos]
    if st.teamDone[m_2v2_bpTeamOfSeat(seat)] < st.banNum then
      return st.playerBySeat[seat], (pos % n) + 1
    end
  end
end

local function m_2v2_bpBroadcast(room, st)
  local banned = {}
  for _, b in ipairs(st.bans) do
    table.insert(banned, b.general)
  end
  local data = { "state", {
    generals = st.generals,
    banned = banned,
    turnId = st.turnId,
    autoTurn = st.autoTurn,
  } }
  for _, p in ipairs(m_2v2_controlPlayers(room)) do
    p:doNotify("UpdateMiniGame", data)
  end
end

--- 玩家是否在线（仅在线玩家能通过客户端交互推进轮次）
local function m_2v2_bpIsOnline(room, playerId)
  local p = room:getPlayerById(playerId)
  return p ~= nil and p.serverplayer:getState() == fk.Player_Online
end

--- 房间内是否有在线玩家
local function m_2v2_bpHasOnline(room)
  for _, p in ipairs(room.players) do
    if m_2v2_bpIsOnline(room, p.id) then return true end
  end
  return false
end

--- 为当前禁将者自动随机禁将一个武将
local function m_2v2_bpAutoBan(room, st)
  local banned = {}
  for _, b in ipairs(st.bans) do
    table.insert(banned, b.general)
  end
  local avail = table.filter(st.generals, function(g)
    return not table.find(banned, function(b) return b == g end)
  end)
  local pick = room:tableRandomPick(avail, 1)[1]
  if pick then
    table.insert(st.bans, { player = st.turnId, general = pick })
    local seat = room:getPlayerById(st.turnId).seat
    st.teamDone[m_2v2_bpTeamOfSeat(seat)] = st.teamDone[m_2v2_bpTeamOfSeat(seat)] + 1
  end
end

--- 推进到下一轮（可能为机器人/离线；其回合由客户端 2 秒倒计时发 timeout 后自动禁将）
---@return boolean 是否还有轮次
local function m_2v2_bpNextTurnState(room, st)
  local nextId, newPos = m_2v2_bpNextTurn(st)
  if not nextId then
    st.turnId = -1
    st.autoTurn = false
    return false
  end
  st.turnId = nextId
  st.curPos = newPos
  st.autoTurn = not m_2v2_bpIsOnline(room, nextId)
  st.recommend = nil
  return true
end

--- 推进到下一个禁将轮次；全部队伍禁完则广播 finished
local function m_2v2_bpAdvance(room, st)
  if not m_2v2_bpNextTurnState(room, st) then
    st.turnId = -1
    st.autoTurn = false
    room:setBanner("2v2_bp_state", st)
    room:doBroadcastNotify("UpdateMiniGame", { "finished" })
    return
  end
  room:setBanner("2v2_bp_state", st)
  m_2v2_bpBroadcast(room, st)
end

-- 选将备将：轮询顺序 2、1、3、4 号位循环，生成每笔选将数量
-- 完整轮次：2号位选1、1/3/4号位选2；最后一笔按奇偶补足配额
--（奇数：二三队最后一笔选2、一四队选1；偶数：二三队最后一笔选1、一四队选2）
local function m_2v2_reserveBuildTurns(reserveNum)
  local order = { 2, 1, 3, 4 }
  local base = { [2] = 1, [1] = 2, [3] = 2, [4] = 2 }
  local lastRebel = (reserveNum % 2 == 1) and 2 or 1
  local lastLoyal = (reserveNum % 2 == 1) and 1 or 2
  local k = math.floor(reserveNum / 4)
  local turns = {}
  for _ = 1, k do
    for _, seat in ipairs(order) do
      table.insert(turns, { seat = seat, count = base[seat] })
    end
  end
  -- 收尾：补齐两队剩余配额，最后一笔按奇偶规则
  local function tailOf(rem, last, m1, m2)
    if rem <= 0 then return {} end
    if rem == last then return { { m1, last } } end
    return { { m1, rem - last }, { m2, last } }
  end
  local rebelRem = reserveNum - 3 * k
  local loyalRem = reserveNum - 4 * k
  local rebelTail = tailOf(rebelRem, lastRebel, 2, 3)
  local loyalTail = tailOf(loyalRem, lastLoyal, 1, 4)
  local rIdx, lIdx = 1, 1
  local pos = 1
  while rIdx <= #rebelTail or lIdx <= #loyalTail do
    local seat = order[((pos - 1) % 4) + 1]
    if seat == 2 or seat == 3 then
      if rIdx <= #rebelTail then
        table.insert(turns, { seat = rebelTail[rIdx][1], count = rebelTail[rIdx][2] })
        rIdx = rIdx + 1
      end
    else
      if lIdx <= #loyalTail then
        table.insert(turns, { seat = loyalTail[lIdx][1], count = loyalTail[lIdx][2] })
        lIdx = lIdx + 1
      end
    end
    pos = pos + 1
  end
  return turns
end

local function m_2v2_reserveTeamOfSeat(seat)
  return (seat == 1 or seat == 4) and "loyalReserve" or "rebelReserve"
end

--- 将当前轮 count 个武将随机放入当前轮玩家的队伍备选池
local function m_2v2_reserveRandomFill(room, st)
  local team = m_2v2_reserveTeamOfSeat(room:getPlayerById(st.turnId).seat)
  local picks = room:tableRandomPick(st.pool, math.min(st.count, #st.pool))
  for _, name in ipairs(picks) do
    table.removeOne(st.pool, name)
    table.insert(st[team], name)
  end
end

local function m_2v2_reserveBroadcast(room, st)
  -- 展示完整将池 + 已备选名单，客户端原地留空，不刷新网格位置
  local reserved = {}
  for _, n in ipairs(st.rebelReserve) do table.insert(reserved, n) end
  for _, n in ipairs(st.loyalReserve) do table.insert(reserved, n) end
  local data = { "state", {
    generals = st.generals,
    reserved = reserved,
    turnId = st.turnId,
    count = st.count,
    rebelBanned = st.rebelBanned,
    rebelReserve = st.rebelReserve,
    loyalBanned = st.loyalBanned,
    loyalReserve = st.loyalReserve,
    reserveNum = st.reserveNum,
    turnRole = st.turnRole,
    autoTurn = st.autoTurn,
  } }
  for _, p in ipairs(m_2v2_controlPlayers(room)) do
    p:doNotify("UpdateMiniGame", data)
  end
end

--- 初始化第一轮（不广播），供 askToMiniGame 初始数据使用
--- 有在线玩家时设为轮询第一位（可能为机器人，其回合由客户端2秒倒计时驱动）；
--- 全机器人房间自动随机补完
local function m_2v2_reserveFirstTurn(room, st)
  if not m_2v2_bpHasOnline(room) then
    while st.turnIdx <= #st.turns do
      local t = st.turns[st.turnIdx]
      st.turnId = st.playerBySeat[t.seat]
      st.count = t.count
      st.turnRole = m_2v2_bpTeamOfSeat(t.seat)
      m_2v2_reserveRandomFill(room, st)
      st.turnIdx = st.turnIdx + 1
    end
    st.turnId = -1
    st.count = 0
    st.turnRole = "loyalist"
    return
  end
  while st.turnIdx <= #st.turns do
    local t = st.turns[st.turnIdx]
    st.turnId = st.playerBySeat[t.seat]
    st.count = t.count
    st.turnRole = m_2v2_bpTeamOfSeat(t.seat)
    st.recommend = nil
    if st.count > #st.pool then
      -- 将池不足：随机补入并继续下一轮
      m_2v2_reserveRandomFill(room, st)
      st.turnIdx = st.turnIdx + 1
    else
      st.autoTurn = not m_2v2_bpIsOnline(room, st.turnId)
      return
    end
  end
  st.turnId = -1
  st.count = 0
  st.turnRole = "loyalist"
end

--- 推进到下一轮；全部轮次完成则广播 finished
local function m_2v2_reserveAdvance(room, st)
  st.turnIdx = st.turnIdx + 1
  while st.turnIdx <= #st.turns do
    local t = st.turns[st.turnIdx]
    st.turnId = st.playerBySeat[t.seat]
    st.count = t.count
    st.turnRole = m_2v2_bpTeamOfSeat(t.seat)
    st.recommend = nil
    if st.count > #st.pool then
      m_2v2_reserveRandomFill(room, st)
      st.turnIdx = st.turnIdx + 1
    else
      st.autoTurn = not m_2v2_bpIsOnline(room, st.turnId)
      room:setBanner("2v2_reserve_state", st)
      m_2v2_reserveBroadcast(room, st)
      return
    end
  end
  st.turnId = -1
  st.count = 0
  st.turnRole = "loyalist"
  room:setBanner("2v2_reserve_state", st)
  room:doBroadcastNotify("UpdateMiniGame", { "finished" })
end

local m_2v2_getLogic = function()
  ---@class m2v2Logic: GameLogic
  local m_2v2_logic = GameLogic:subclass("m_2v2_logic")

  function m_2v2_logic:assignRoles()
    ---@return ServerPlayer[]
    local function getOtherPlayers(room, p)
      local ret = table.simpleClone(room.players)
      table.removeOne(ret, p)
      return ret
    end

    local function getPlayerByScreenName(room, name)
      return table.find(room.players, function(p)
        return p._splayer:getScreenName() == name
      end)
    end

    local room = self.room

    if #room.players == 2 then
      room:setBanner("is_2v2_duel", true)
      -- 因为一控多不支持刷卡，所以ban手气卡
      room.settings._game.luckTime = 0
      summonBots(room)
    end

    local croom = room.room
    local cowner = croom:getOwner()
    local owner = getPlayerByScreenName(room, cowner:getScreenName())
    local buddy
    if not room:getBanner("is_2v2_duel") then
      buddy = room:askToChoosePlayers(owner, {
        min_num = 1,
        max_num = 1,
        targets = getOtherPlayers(room, owner),
        skill_name = "game_rule",
        prompt = "#m_2v2_choose_buddy",
        cancelable = true,
        no_indicate = true,
      })[1]
    else
      buddy = table.find(getOtherPlayers(room, owner), function(p)
        return p.id < 0 and p.serverplayer == cowner
      end)
    end

    if buddy then
      local buddy_table = { 4, 3, 2, 1 }
      local owner_seat = math.random(1, 4)
      local buddy_seat = buddy_table[owner_seat]
      local others = getOtherPlayers(room, owner)
      table.removeOne(others, buddy)
      table.shuffle(others)
      local players = {}
      players[owner_seat] = owner
      players[buddy_seat] = buddy
      if owner_seat == 1 or owner_seat == 4 then
        players[2] = others[1]
        players[3] = others[2]
      else
        players[1] = others[1]
        players[4] = others[2]
      end
      room.players = players
    else
      table.shuffle(room.players)
    end

    local n = #room.players

    local roles = { "loyalist", "rebel", "rebel", "loyalist" }

    for i = 1, n do
      local p = room.players[i]
      p.role = roles[i]
    end

    ---[[
    room.players[1]:addBuddy(room.players[4])
    room.players[4]:addBuddy(room.players[1])
    room.players[2]:addBuddy(room.players[3])
    room.players[3]:addBuddy(room.players[2])
    --]]
    --
    self.start_role = roles[1]
    -- for adjustSeats
    room.players[1].role = "lord"
  end

  function m_2v2_logic:chooseGenerals()
    local room = self.room
    local generalNum = math.min(room:getSettings('generalNum'), 9)

    local lord = room:getLord() ---@cast lord -nil
    room:setCurrent(lord)
    lord.role = self.start_role
    for _, p in ipairs(room.players) do
      room:setPlayerProperty(p, "role_shown", true)
      room:broadcastProperty(p, "role")
    end

    -- 十周年禁将BP：分配座次后、选将前，按轮询顺序进行禁将
    local bpReserveState
    if room:getSettings("enable2v2BP") then
      local bpPoolNum = math.max(12, math.min(room:getSettings("bpGeneralNum") or 24, 40))
      local bpBanNum = math.max(1, math.min(room:getSettings("bpBanNum") or 2, math.floor(bpPoolNum / 4)))
      local bpReserveNum = math.max(2, math.min(room:getSettings("bpReserveNum") or 5, 10))
      local bpTimeout = math.max(15,
        math.min(room:getSettings("bpTimeout") or room:getSettings('generalTimeout') or room.timeout, 60))
      local bpGenerals = table.map(Fk:getGeneralsRandomly(bpPoolNum), Util.NameMapper)

      local st = {
        generals = bpGenerals,
        bans = {},
        turnId = -1,
        curPos = 1,
        autoTurn = false,
        banNum = bpBanNum,
        teamDone = { loyalist = 0, rebel = 0 },
        seatOrder = { 3, 1, 4, 2 },
        playerBySeat = {},
      }
      for _, p in ipairs(room.players) do
        st.playerBySeat[p.seat] = p.id
      end
      if m_2v2_bpHasOnline(room) then
        -- 有在线玩家：第一轮按轮询顺序（可能为机器人，客户端用2秒倒计时驱动其自动禁将）
        m_2v2_bpNextTurnState(room, st)
        room:setBanner("2v2_bp_state", st)

        local bpData = {}
        for _, p in ipairs(m_2v2_controlPlayers(room)) do
          bpData[p.id] = {
            generals = bpGenerals,
            banned = {},
            turnId = st.turnId,
            autoTurn = st.autoTurn,
            banNum = bpBanNum,
            reserveNum = bpReserveNum,
            timeout = bpTimeout,
            myRole = p.role,
            selfId = p.id,
            controlledIds = m_2v2_controlledIds(room, p),
          }
        end
        m_2v2_askMiniGame(room, m_2v2_controlPlayers(room), {
          skill_name = "2v2_bp",
          game_type = "2v2_bp",
          data_table = bpData,
          timeout = bpBanNum * 2 * bpTimeout + 120,
        })
      else
        -- 全机器人房间：直接自动完成全部禁将
        while true do
          local nextId, newPos = m_2v2_bpNextTurn(st)
          if not nextId then break end
          st.turnId = nextId
          st.curPos = newPos
          m_2v2_bpAutoBan(room, st)
        end
        st.turnId = -1
        room:setBanner("2v2_bp_state", st)
      end

      -- 禁将结束，进入选将备将阶段
      local bpst = room:getBanner("2v2_bp_state")
      local rebelBanned, loyalBanned = {}, {}
      local bpGenerals = bpst and bpst.generals or {}
      if bpst then
        for _, b in ipairs(bpst.bans) do
          local seat = room:getPlayerById(b.player).seat
          if seat == 1 or seat == 4 then
            table.insert(loyalBanned, b.general)
          else
            table.insert(rebelBanned, b.general)
          end
        end
      end
      -- 剩余将池（剔除两队禁将）
      local rpool = {}
      for _, g in ipairs(bpGenerals) do
        if not table.find(rebelBanned, function(n) return n == g end) and
            not table.find(loyalBanned, function(n) return n == g end) then
          table.insert(rpool, g)
        end
      end
      local rst = {
        pool = rpool,
        generals = rpool,
        turns = m_2v2_reserveBuildTurns(bpReserveNum),
        turnIdx = 1,
        turnId = -1,
        count = 0,
        turnRole = "loyalist",
        autoTurn = false,
        reserveNum = bpReserveNum,
        rebelReserve = {},
        loyalReserve = {},
        rebelBanned = rebelBanned,
        loyalBanned = loyalBanned,
        playerBySeat = {},
      }
      for _, p in ipairs(room.players) do
        rst.playerBySeat[p.seat] = p.id
      end
      m_2v2_reserveFirstTurn(room, rst)
      bpReserveState = rst
      room:setBanner("2v2_reserve_state", rst)

      if rst.turnId ~= -1 then
        local rData = {}
        for _, p in ipairs(m_2v2_controlPlayers(room)) do
          rData[p.id] = {
            generals = rpool,
            reserved = {},
            turnId = rst.turnId,
            count = rst.count,
            turnRole = rst.turnRole,
            autoTurn = rst.autoTurn,
            rebelBanned = rebelBanned,
            rebelReserve = {},
            loyalBanned = loyalBanned,
            loyalReserve = {},
            reserveNum = bpReserveNum,
            timeout = bpTimeout,
            myRole = p.role,
            selfId = p.id,
            controlledIds = m_2v2_controlledIds(room, p),
          }
        end
        m_2v2_askMiniGame(room, m_2v2_controlPlayers(room), {
          skill_name = "2v2_reserve",
          game_type = "2v2_reserve",
          data_table = rData,
          timeout = #rst.turns * bpTimeout + 120,
        })
      end
      -- 备选结果保留在 banner 中，供后续 2v2 选将环节使用
      room:setBanner("2v2_bp_state", nil)
    end

    local nonlord = room.players
    local generals = table.map(Fk:getGeneralsRandomly(#nonlord * generalNum), Util.NameMapper)
    table.shuffle(generals)
    local t1 = table.slice(generals, 1, generalNum + 1)
    local t2 = table.slice(generals, generalNum + 1, generalNum * 2 + 1)
    local t3 = table.slice(generals, generalNum * 2 + 1, generalNum * 3 + 1)
    local t4 = table.slice(generals, generalNum * 3 + 1, generalNum * 4 + 1)
    if room:getBanner("is_2v2_duel") then
      local cool_marshal = room.players[1]
      local warm_marshal = room.players[2]
      local req = Request:new({ cool_marshal, warm_marshal }, "AskForGeneral")
      req.timeout = self.room:getSettings('generalTimeout')
      -- 统率二军由每名玩家一次选择本队两个角色；开启 BP 时从本队备选池中选择。
      local rsv = bpReserveState
      local cool_generals = rsv and rsv.loyalReserve or table.connect(t1, t4)
      local cool_data = { cool_generals, 2 }
      if rsv then
        cool_data = { cool_generals, 2, false, false, "askForGeneralsChosen", "",
          { n = 2, seatNumbers = { 1, 4 } } }
      end
      req:setData(cool_marshal, cool_data)
      req:setDefaultReply(cool_marshal, room:tableRandomPick(cool_generals, 2))
      local warm_generals = rsv and rsv.rebelReserve or table.connect(t2, t3)
      local warm_data = { warm_generals, 2 }
      if rsv then
        warm_data = { warm_generals, 2, false, false, "askForGeneralsChosen", "",
          { n = 2, seatNumbers = { 2, 3 } } }
      end
      req:setData(warm_marshal, warm_data)
      req:setDefaultReply(warm_marshal, room:tableRandomPick(warm_generals, 2))

      room:doBroadcastNotify("ShowToast",
        Fk:translate("2v2_duel_choose_general"),
        { cool_marshal, warm_marshal })
      req:ask()

      local glist = {}
      table.insert(glist, req:getResult(cool_marshal)[1])
      table.insertTable(glist, req:getResult(warm_marshal))
      table.insert(glist, req:getResult(cool_marshal)[2])

      for i = 1, 4, 1 do
        local p = room.players[i]
        room:setPlayerGeneral(p, glist[i], true, true)
        room:findGeneral(glist[i])
      end
    else
      -- 十周年禁将BP开启时：选将将池来自队伍备选池（同队共用一份、实时同步、确认后锁定）
      local rsv = bpReserveState or room:getBanner("2v2_reserve_state")
      local t1, t2, t3, t4
      if rsv then
        t1 = rsv.loyalReserve
        t2 = rsv.rebelReserve
        t3 = rsv.rebelReserve
        t4 = rsv.loyalReserve
      else
        t1 = table.slice(generals, 1, generalNum + 1)
        t2 = table.slice(generals, generalNum + 1, generalNum * 2 + 1)
        t3 = table.slice(generals, generalNum * 2 + 1, generalNum * 3 + 1)
        t4 = table.slice(generals, generalNum * 3 + 1, generalNum * 4 + 1)
      end
      local req = room:askToMiniGame(nonlord, {
        skill_name = "AskForGeneral",
        game_type = "2v2_sel",
        data_table = {
          [nonlord[1].id] = {
            friend_id = nonlord[4].id,
            me = t1,
            friend = t4,
            shared = rsv and true or nil,
          },
          [nonlord[2].id] = {
            friend_id = nonlord[3].id,
            me = t2,
            friend = t3,
            shared = rsv and true or nil,
          },
          [nonlord[3].id] = {
            friend_id = nonlord[2].id,
            me = t3,
            friend = t2,
            shared = rsv and true or nil,
          },
          [nonlord[4].id] = {
            friend_id = nonlord[1].id,
            me = t4,
            friend = t1,
            shared = rsv and true or nil,
          },
        },
        timeout = self.room:getSettings('generalTimeout'),
      })
      if rsv then
        -- 同队共用将池：处理超时/选重，保证同队两人所选武将不重复
        local takenLoyal, takenRebel = {}, {}
        for _, p in ipairs(nonlord) do
          local isLoyal = (p.seat == 1 or p.seat == 4)
          local pool = isLoyal and rsv.loyalReserve or rsv.rebelReserve
          local taken = isLoyal and takenLoyal or takenRebel
          local general = req:getResult(p)
          if general == "" or taken[general] then
            local avail = table.filter(pool, function(g) return not taken[g] end)
            if #avail > 0 then
              general = room:tableRandomPick(avail, 1)[1]
            end
          end
          taken[general] = true
          room:setPlayerGeneral(p, general, true, true)
          room:findGeneral(general)
        end
      else
        for _, p in ipairs(nonlord) do
          local general = req:getResult(p)
          room:setPlayerGeneral(p, general, true, true)
          room:findGeneral(general)
        end
      end
      room:setBanner("2v2_reserve_state", nil)
    end

    room:askToChooseKingdom(nonlord)
  end

  function m_2v2_logic:attachSkillToPlayers()
    GameLogic.attachSkillToPlayers(self)

    local room = self.room
    if room:getSettings("enableLimitFeiyang") then
      room:handleAddLoseSkills(room.players[4], "m_2v2_feiyang", nil, false)
    end
  end

  return m_2v2_logic
end

local m_2v2_mode = fk.CreateGameMode {
  name = "m_2v2_mode",
  playerNums = { 2, 4 },
  feasible = function(self, settings)
    local commander = (settings._mode or {}).enable2v2Duel == true
    return table.contains(self.playerNums, settings.playerNum) and
      settings.playerNum == (commander and 2 or 4)
  end,
  rule = "#m_2v2_rule&",
  logic = m_2v2_getLogic,
  main_mode = "2v2_mode",
  surrender_func = function(self, playedTime, player)
    -- 若为统率 沿用1v1投降
    if Fk:currentRoom():getBanner("is_2v2_duel") then
      return { { text = "time limitation: 1 min", passed = playedTime >= 60 } }
    end
    local surrenderJudge = { { text = "time limitation: 1 min", passed = playedTime >= 60 },
      {
        text = "2v2: left you alive",
        passed = table.find(Fk:currentRoom().players, function(p)
          return p.role == player.role and p.dead and p.rest == 0
        end) and true
      } }
    return surrenderJudge
  end,
  winner_getter = function(self, victim)
    -- 若为统率 直接结束游戏
    if victim.surrendered and Fk:currentRoom():getBanner("is_2v2_duel") then
      return victim:getEnemies(true)
    end
    if not victim.surrendered and victim.rest > 0 then
      return ""
    end

    local room = victim.room
    local alive = table.filter(room.players, function(p) ---@type Player[]
      return not p.surrendered and not (p.dead and p.rest == 0)
    end)
    local winner = alive[1].role
    for _, p in ipairs(alive) do
      if p.role ~= winner then
        return ""
      end
    end
    return alive[1]:getFriends(true, true)
  end,
  reward_punish = function(self, victim, killer)
    local room = victim.room
    for _, p in ipairs(room.alive_players) do
      if p.role == victim.role and not p.dead then
        p:drawCards(1, "game_rule")
      end
    end
  end,
}

local W = require "ui_emu.preferences"
m_2v2_mode.ui_settings = {
  W.PreferenceGroup {
    title = "Game Rule",

    W.SwitchRow {
      _settingsKey = "enableLimitFeiyang",
      title = "m_2v2_limit_feiyang",
    },

    W.SwitchRow {
      _settingsKey = "enable2v2Duel",
      title = "2v2_2player",
    },

    W.SwitchRow {
      _settingsKey = "enable2v2BP",
      title = "m_2v2_bp",
    },

    W.SpinRow {
      _settingsKey = "bpTimeout",
      title = "m_2v2_bp_timeout",
      from = 15,
      to = 60,
      editable = true,
      value = function(settings)
        if settings._mode["bpTimeout"] then return settings._mode["bpTimeout"] end
        if settings._game["timeoutAsGeneralTimeout"] then return settings.timeout end
        return settings._game["generalTimeout"] or settings.timeout or 30
      end,
      visible = function(settings)
        return settings._mode["enable2v2BP"] or false
      end,
    },

    W.SpinRow {
      _settingsKey = "bpGeneralNum",
      title = "m_2v2_bp_pool",
      from = 12,
      to = 40,
      editable = true,
      value = function(settings)
        return settings._mode["bpGeneralNum"] or 24
      end,
      visible = function(settings)
        return settings._mode["enable2v2BP"] or false
      end,
    },

    W.SpinRow {
      _settingsKey = "bpBanNum",
      title = "m_2v2_bp_ban",
      from = 1,
      to = function(settings)
        return math.max(1, math.floor((settings._mode["bpGeneralNum"] or 24) / 4))
      end,
      editable = true,
      value = function(settings)
        return settings._mode["bpBanNum"] or 2
      end,
      visible = function(settings)
        return settings._mode["enable2v2BP"] or false
      end,
    },

    W.SpinRow {
      _settingsKey = "bpReserveNum",
      title = "m_2v2_bp_reserve",
      from = function(settings)
        return settings._game["enableDeputy"] and 4 or 2
      end,
      to = 10,
      editable = true,
      value = function(settings)
        return settings._mode["bpReserveNum"] or 5
      end,
      visible = function(settings)
        return settings._mode["enable2v2BP"] or false
      end,
    },
  },

}

Fk:loadTranslationTable {
  ["m_2v2_mode"] = "2v2",
  [":m_2v2_mode"] = desc_2v2,

  ["#m_2v2_choose_buddy"] = "请房主选择自己的队友",

  ["time limitation: 1 min"] = "游戏时长达到1分钟",
  ["2v2: left you alive"] = "你所处队伍仅剩你存活",

  ["m_2v2_limit_feiyang"] = "四号位获得〖飞扬〗",
  ["help: m_2v2_limit_feiyang"] = "(OL) 四号位增加需弃两张手牌的、限定技版的〖飞扬〗",
  ["#m_2v2_feiyang-invoke"] = "飞扬：你可以弃置两张手牌，弃置自己判定区的一张牌",

  ["m_2v2_bp"] = "十周年禁将BP",
  ["help: m_2v2_bp"] = "开启后启用十周年禁将BP规则，可设置待选将池数量、每支队伍禁将数量与备选数量。若要在2人房间使用，需另行开启“统率二军”设置",
  ["m_2v2_bp_timeout"] = "禁将时间",
  ["help: m_2v2_bp_timeout"] = "每轮禁将的倒计时时间，不得低于15秒，不得超过60秒，默认与选将时间一致",
  ["m_2v2_bp_pool"] = "所有玩家待选将池数量",
  ["help: m_2v2_bp_pool"] = "所有玩家待选将池的数量，不得低于12",
  ["m_2v2_bp_ban"] = "每支队伍禁将数量",
  ["help: m_2v2_bp_ban"] = "每支队伍可以禁用的武将数量，不得高于所有玩家待选将池数量的1/4",
  ["m_2v2_bp_reserve"] = "每支队伍的所有备选数量",
  ["help: m_2v2_bp_reserve"] = "每支队伍的所有备选武将数量，不得低于2（开启副将时不得低于4）",

  ["2v2_2player"] = "“统率二军”",
  ["help: 2v2_2player"] = "允许房间人数设为2，此时两名玩家各控制两个角色；若同时开启十周年禁将BP，将在统率二军流程中完成禁将与备选",

  ["2v2_duel_choose_general"] = "请为本方阵营选择选择武将，从左至右为一四（或二三）",

  ["2v2_bp"] = "十周年禁将BP",
  ["2v2_bp_title"] = "十周年禁将BP",
  ["2v2_bp_banning"] = "禁将中",

  ["2v2_reserve_prepick"] = "预选%1将",
  ["2v2_reserve_confirm"] = "确认",
}

Fk:addMiniGame {
  name = "2v2_sel",
  qml_path = "packages/gamemode/qml/2v2",
  default_choice = function(player, data)
    return data.me[1]
  end,
  update_func = function(player, data)
    local room = player.room
    local d = player.mini_game_data.data
    local friend = room:getPlayerById(d.friend_id)
    friend:doNotify("UpdateMiniGame", data)
  end,
}

Fk:addMiniGame {
  name = "2v2_bp",
  qml_path = "packages/gamemode/qml/2v2_bp",
  default_choice = function(player, data)
    return ""
  end,
  update_func = function(player, data)
    local room = player.room
    local st = room:getBanner("2v2_bp_state")
    if not st then return end
    local typ = data[1]
    if typ == "ban" and m_2v2_controlsPlayer(room, player, st.turnId) and
        (not data[3] or tostring(data[3]) == tostring(st.turnId)) then
      local name = data[2]
      -- 校验：武将必须在展示将池中且未被禁
      if table.find(st.generals, function(g) return g == name end) and
          not table.find(st.bans, function(b) return b.general == name end) then
        table.insert(st.bans, { player = st.turnId, general = name })
        local seat = room:getPlayerById(st.turnId).seat
        st.teamDone[m_2v2_bpTeamOfSeat(seat)] = st.teamDone[m_2v2_bpTeamOfSeat(seat)] + 1
        m_2v2_bpAdvance(room, st)
      end
    elseif typ == "timeout" then
      -- 当前轮为机器人/离线时，任一在线玩家可触发其自动禁将；
      -- 否则仅当前轮玩家本人超时跳过
      local isAuto = st.autoTurn
      local staleTurn = data[2] and tostring(data[2]) ~= tostring(st.turnId)
      if not staleTurn and (m_2v2_controlsPlayer(room, player, st.turnId) or isAuto) then
        if isAuto then
          m_2v2_bpAutoBan(room, st)
        end
        m_2v2_bpAdvance(room, st)
      end
    elseif typ == "recommend" then
      -- 同队队友向当前禁将者推荐武将（转发给当前轮玩家与推荐者本人）；
      -- 再次点击同一武将则取消推荐
      local name = data[2]
      if not m_2v2_controlsPlayer(room, player, st.turnId) then
        local active = room:getPlayerById(st.turnId)
        if active and
            m_2v2_bpTeamOfSeat(room:getPlayerById(player.id).seat) ==
            m_2v2_bpTeamOfSeat(active.seat) and
            table.find(st.generals, function(g) return g == name end) and
            not table.find(st.bans, function(b) return b.general == name end) then
          if st.recommend and st.recommend.fromId == player.id and st.recommend.general == name then
            st.recommend = nil
            local notify = { "recommend", { general = "", fromId = player.id } }
            active:doNotify("UpdateMiniGame", notify)
            player:doNotify("UpdateMiniGame", notify)
          else
            st.recommend = { fromId = player.id, general = name }
            local notify = { "recommend", { general = name, fromId = player.id } }
            active:doNotify("UpdateMiniGame", notify)
            player:doNotify("UpdateMiniGame", notify)
          end
        end
      end
    end
  end,
}

Fk:addMiniGame {
  name = "2v2_reserve",
  qml_path = "packages/gamemode/qml/2v2_reserve",
  default_choice = function(player, data)
    return ""
  end,
  update_func = function(player, data)
    local room = player.room
    local st = room:getBanner("2v2_reserve_state")
    if not st then return end
    local typ = data[1]
    if typ == "select" and m_2v2_controlsPlayer(room, player, st.turnId) and
        (not data[2] or tostring(data[2]) == tostring(st.turnId)) then
      -- 校验选将数量与合法性（去重、必须在剩余将池中）
      local picks = {}
      for i = data[2] and 3 or 2, #data do
        local name = data[i]
        if table.find(st.pool, function(g) return g == name end) and
            not table.find(picks, function(g) return g == name end) then
          table.insert(picks, name)
        end
      end
      if #picks == st.count then
        local team = m_2v2_reserveTeamOfSeat(room:getPlayerById(st.turnId).seat)
        for _, name in ipairs(picks) do
          table.removeOne(st.pool, name)
          table.insert(st[team], name)
        end
        m_2v2_reserveAdvance(room, st)
      end
    elseif typ == "timeout" then
      -- 当前轮为机器人/离线时，任一在线玩家可触发其随机补入备选；
      -- 否则仅当前轮玩家本人超时跳过
      local isAuto = st.autoTurn
      local staleTurn = data[2] and tostring(data[2]) ~= tostring(st.turnId)
      if not staleTurn and (m_2v2_controlsPlayer(room, player, st.turnId) or isAuto) then
        if isAuto then
          m_2v2_reserveRandomFill(room, st)
        end
        m_2v2_reserveAdvance(room, st)
      end
    elseif typ == "recommend" then
      -- 同队队友向当前备选玩家推荐武将（转发给当前轮玩家与推荐者本人）；
      -- 再次点击同一武将则取消推荐
      local name = data[2]
      if not m_2v2_controlsPlayer(room, player, st.turnId) then
        local active = room:getPlayerById(st.turnId)
        if active and
            m_2v2_bpTeamOfSeat(room:getPlayerById(player.id).seat) ==
            m_2v2_bpTeamOfSeat(active.seat) and
            table.find(st.pool, function(g) return g == name end) then
          if st.recommend and st.recommend.fromId == player.id and st.recommend.general == name then
            st.recommend = nil
            local notify = { "recommend", { general = "", fromId = player.id } }
            active:doNotify("UpdateMiniGame", notify)
            player:doNotify("UpdateMiniGame", notify)
          else
            st.recommend = { fromId = player.id, general = name }
            local notify = { "recommend", { general = name, fromId = player.id } }
            active:doNotify("UpdateMiniGame", notify)
            player:doNotify("UpdateMiniGame", notify)
          end
        end
      end
    end
  end,
}

return m_2v2_mode
