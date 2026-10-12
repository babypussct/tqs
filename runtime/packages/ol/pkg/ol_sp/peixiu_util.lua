local M = {}

Fk:loadTranslationTable {
  -- 十六州地图名称
  ["map_sizhou"] = "司州",
  ["map_yanzhou"] = "兖州",
  ["map_qingzhou"] = "青州",
  ["map_jizhou"] = "冀州",
  ["map_yuzhou"] = "豫州",
  ["map_xuzhou"] = "徐州",
  ["map_jingzhou"] = "荆州",
  ["map_yangzhou"] = "扬州",
  ["map_qinzhou"] = "秦州",
  ["map_yizhou"] = "益州",
  ["map_liangzhou"] = "梁州",
  ["map_yongzhou"] = "雍州",
  ["map_youzhou"] = "幽州",
  ["map_bingzhou"] = "并州",
  ["map_liangzhou2"] = "凉州",
  ["map_ningzhou"] = "宁州",

  ["map_directionU"] = "北",
  ["map_directionD"] = "南",
  ["map_directionL"] = "西",
  ["map_directionR"] = "东",
}

-- ====== 十六州地图 ======
-- 数据来源：https://peixiu.hmty.top/

-- 格式说明
-- "#": 不可走之地
-- ".": 空格子
-- "+n": 摸n张牌
-- "Hn": 回复n体力
-- "Un", "Dn", "Ln", "Rn": 向上/下/左/右移动n格
-- "P": 玩家棋子在此处
-- ":" + 技能名：城池技能

-- 1. 司州
local map_sizhou = {
  { "#", "D1:peixiu_wenxi",  "#", ".", "+2:peixiu_handan" },
  { "#",  ".",  "P",  ".", "#" },
  { ".", "+1:peixiu_hongnong",  ".",  "#", "#" },
  { ".",  ".", "L1:peixiu_wenxian",  "#", "#" },
}

-- 2. 兖州
local map_yanzhou = {
  {  "#",  "#",  "#", "D3:peixiu_taishan" },
  {  "#", "+2:peixiu_juancheng",  ".",  "." },
  {  ".",  ".",  "P",  "." },
  { "R1:peixiu_chenliu",  ".", "H1:peixiu_rencheng",  "." },
}

-- 3. 青州
local map_qingzhou = {
  {  "#",  "#", "#", ".", "#" },
  { "+2:peixiu_lean",  ".", "#", "+2:peixiu_donglai", "." },
  {  ".", "+1:peixiu_linzi", ".", ".", "#" },
  {  "#", "P", "U1:peixiu_beihai", "#", "#" },
  {  "#", ".", "#", "#", "#" },
}

-- 4. 冀州
local map_jizhou = {
  { "#", ".", ".", "+2:peixiu_bohai", "#" },
  { "+1:peixiu_changshan", ".", "P", ".", "#" },
  { "#", "U1:peixiu_julu", ".", "H1:peixiu_pingyuan", "." },
  { "#", "#", ".", "#", "#" },
}

-- 5. 豫州
local map_yuzhou = {
  { "R1:peixiu_xuchang", ".", "+1:peixiu_peixian", ".", "#" },
  { ".", ".", "P", "+2:peixiu_qiaoxian", "." },
  { "#", "U3:peixiu_runan", ".", "#", "#" },
  { "#", ".", "#", "#", "#" },
}

-- 6. 徐州
local map_xuzhou = {
  { "#", "#", ".", "#", "#" },
  { "#", "#", "+1:peixiu_langya", "#", "#" },
  { "+2:peixiu_pengcheng", ".", "P", "#", "#" },
  { "#", ".", ".", "H1:peixiu_donghai", "#" },
  { "#", ".", "R1:peixiu_guangling", ".", "." },
}

-- 7. 荆州
local map_jingzhou = {
  { ".", ".", ".", "H1:peixiu_nanyang", "#" },
  { "+2:peixiu_shangyong", ".", "P", ".", "#" },
  { "#", "U1:peixiu_xiangyang", ".", ".", "+1:peixiu_jiangxia" },
}

-- 8. 扬州
local map_yangzhou = {
  { "#", "H1:peixiu_shouchun", ".", "#" },
  { ".", ".", "P", "." },
  { ".", "+4:peixiu_hefei", ".", "L1:peixiu_juchao" },
  { "U1:peixiu_lujiang", ".", "#", "#" },
}

-- 9. 秦州
local map_qinzhou = {
  { ".", "#", "#", "#" },
  { ".", ".", "#", "#" },
  { "R1:peixiu_longxi", "P", "+1:peixiu_tianshui", "." },
  { "#", ".", ".", "H1:peixiu_wudu" },
  { "+2:peixiu_yinping", ".", "#", "#" },
}

-- 10. 益州
local map_yizhou = {
  { "#", ".", "#", "#" },
  { "#", "D2:peixiu_chengdu", "#", "#" },
  { ".", ".", "P", "#" },
  { "H2:peixiu_linqiong", ".", ".", "+1:peixiu_zangke" },
  { "#", "+1:peixiu_zhuti", ".", "." },
}

-- 11. 梁州
local map_liangzhou = {
  { "#", ".", "D3:peixiu_hanzhong", "#" },
  { ".", "+1:peixiu_baxi", ".", "#" },
  { "H1:peixiu_mianzhu", "P", ".", "#" },
  { "#", ".", ".", "+2:peixiu_fuling" },
  { "#", "#", ".", "#" },
}

-- 12. 雍州
local map_yongzhou = {
  { ".", "#", "#", "#", "#" },
  { ".", "H1:peixiu_anding", "#", "#", "#" },
  { "#", ".", "#", ".", "+2:peixiu_pingyi" },
  { "#", "+1:peixiu_fufeng", "P", ".", "#" },
  { "#", ".", ".", "L2:peixiu_jingzhao", "#" },
}

-- 13. 幽州
local map_youzhou = {
  { "#", "#", "#", "+1:peixiu_xuantu", "#" },
  { "#", "#", "#", ".", "#" },
  { "#", "+1:peixiu_beiping", ".", ".", "#" },
  { ".", ".", "#", ".", "." },
  { "P", "+1:peixiu_fanyang", "#", "#", "+2:peixiu_daifang" },
}

-- 14. 并州
local map_bingzhou = {
  { "#", "#", "D2:peixiu_yanmen", "#" },
  { "#", ".", ".", "." },
  { ".", "+1:peixiu_jiuyuan", ".", "#" },
  { "+1:peixiu_qixian", ".", ".", "+1:peixiu_wuxiang" },
  { "#", "#", "P", "#" },
}

-- 15. 凉州
local map_liangzhou2 = {
  { ".", ".", "L1:peixiu_juyan", "#", "#" },
  { "+3:peixiu_dunhuang", ".", "#", "#", "#" },
  { "#", "U2:peixiu_yumen", ".", "+2:peixiu_wuwei", "#" },
  { "#", ".", "#", ".", "." },
  { "#", ".", "#", "#", "P" },
}

-- 16. 宁州
local map_ningzhou = {
  { "P", "#", "#", "#", "#" },
  { ".", ".", "H1:peixiu_dianchi", "#", "#" },
  { "+3:peixiu_ailao", ".", ".", "L2:peixiu_gouding", "." },
  { "#", "H1:peixiu_nanfu", ".", ".", "#" },
}

local map_pool = {
  "map_sizhou", "map_yanzhou", "map_qingzhou", "map_jizhou",
  "map_yuzhou", "map_xuzhou", "map_jingzhou", "map_yangzhou",
  "map_qinzhou", "map_yizhou", "map_liangzhou", "map_yongzhou",
  "map_youzhou", "map_bingzhou", "map_liangzhou2", "map_ningzhou",
}

local map_table = {
  map_sizhou = map_sizhou,
  map_yanzhou = map_yanzhou,
  map_qingzhou = map_qingzhou,
  map_jizhou = map_jizhou,
  map_yuzhou = map_yuzhou,
  map_xuzhou = map_xuzhou,
  map_jingzhou = map_jingzhou,
  map_yangzhou = map_yangzhou,
  map_qinzhou = map_qinzhou,
  map_yizhou = map_yizhou,
  map_liangzhou = map_liangzhou,
  map_yongzhou = map_yongzhou,
  map_youzhou = map_youzhou,
  map_bingzhou = map_bingzhou,
  map_liangzhou2 = map_liangzhou2,
  map_ningzhou = map_ningzhou,
}

-- 地图技能池子
local map_skills = {
  map_sizhou = "peixiu_sizhou",
  map_yanzhou = "peixiu_yanzhou",
  map_qingzhou = "peixiu_qingzhou",
  map_jizhou = "peixiu_jizhou",
  map_yuzhou = "peixiu_yuzhou",
  map_xuzhou = "peixiu_xuzhou",
  map_jingzhou = "peixiu_jingzhou",
  map_yangzhou = "peixiu_yangzhou",
  map_qinzhou = "peixiu_qinzhou",
  map_yizhou = "peixiu_yizhou",
  map_liangzhou = "peixiu_liangzhou",
  map_yongzhou = "peixiu_yongzhou",
  map_youzhou = "peixiu_youzhou",
  map_bingzhou = "peixiu_bingzhou",
  map_liangzhou2 = "peixiu_liangzhou2",
  map_ningzhou = "peixiu_ningzhou",
}

local function findPlayerInMap(map)
  local py, px = nil, nil
  for i = 1, #map do
    for j = 1, #map[i] do
      if map[i][j] == "P" then
        py, px = i, j
        break
      end
    end
    if py then break end
  end
  return py, px
end

-- 从map中找到棋子位置后，向对应方向移动一格
-- 若目标位置是效果，则return该效果；棋子走过的地方变成空地
---@param direction "U"|"D"|"L"|"R"
---@param py integer? 棋子的y坐标 传入后可避免重复查找
---@param px integer? 棋子的x坐标 传入后可避免重复查找
---@return string?, integer?, integer?
local function walk1StepInMap(map, direction, py, px)
  -- 如果没有传入棋子坐标，则查找
  if not py or not px then
    py, px = findPlayerInMap(map)
  end
  if not py or not px then
    return nil  -- 没有找到玩家棋子
  end

  -- 计算目标位置
  -- px是列(x坐标), py是行(y坐标)
  local nx, ny = px, py
  if direction == "U" then
    ny = py - 1
  elseif direction == "D" then
    ny = py + 1
  elseif direction == "L" then
    nx = px - 1
  elseif direction == "R" then
    nx = px + 1
  else
    return nil, py, px  -- 无效方向
  end

  -- 边界检查: ny是行, nx是列
  if ny < 1 or ny > #map or nx < 1 or nx > #map[ny] then
    return nil, py, px
  end

  local target = map[ny][nx]

  -- 墙壁不可走
  if target == "#" then
    return nil, py, px
  end

  -- 棋子走过的地方变成空地
  map[py][px] = "."

  -- 移动棋子
  map[ny][nx] = "P"

  return target, ny, nx
end

--- 不断向对应方向移动到不能再移动为止。
--- 若遇到立即移动效果块（U/D/L/R），则该函数的返回条件改为执行完效果块所说的移动
--- 若为其他效果块（+n, Hn等），则保存在返回值数组中
--- 当撞墙或执行完毕移动效果块后返回。
---@param direction "U"|"D"|"L"|"R"
---@return string[]
function M.walkDirection(map, direction)
  local effects = {}
  local py, px = findPlayerInMap(map)
  if not py or not px then
    return effects
  end

  while true do
    local target, cur_py, cur_px = walk1StepInMap(map, direction, py, px)
    if target == nil then
      -- 撞墙或无效移动，停止
      break
    end

    -- 更新当前位置
    py, px = cur_py, cur_px

    -- 解析效果
    local effect_type = target:sub(1, 1)
    if effect_type == "U" or effect_type == "D" or effect_type == "L" or effect_type == "R" then
      -- 立即移动效果块：执行该移动后返回
      -- 衍生移动过程中经过的效果块也要收集
      local steps = tonumber(target:sub(2, 2))
      table.insert(effects, target)
      if steps and steps > 0 then
        for _ = 1, steps do
          local step_target, new_py, new_px = walk1StepInMap(map, effect_type, py, px)
          if new_py and new_px then
            py, px = new_py, new_px
            -- 衍生移动中踩到的非移动效果也要收集
            if step_target then
              local step_type = step_target:sub(1, 1)
              if step_type ~= "." then
                table.insert(effects, step_target)
              end
            end
          else
            break
          end
        end
      end
      break
    elseif effect_type ~= "." then
      -- 其他效果块（+n, Hn等），保存到数组中
      table.insert(effects, target)
    end
  end

  return effects
end

-- 针对+n或者Hn对player执行对应效果
---@param player ServerPlayer
function M.executeMapEffect(player, effect_string)
  local room = player.room
  local effect_type = effect_string:sub(1, 1)
  local n = tonumber(effect_string:sub(2, 2))
  ---@cast n -nil

  if effect_type == "+" then
    player:drawCards(n)
  elseif effect_type == "H" then
    room:recover {
      who = player,
      num = n,
    }
  end

  if effect_string:find(":") then
    local skill = effect_string:sub(4)
    local pool = player:getTableMark("@[:]maozhu_pool-turn")
    table.insertIfNeed(pool, skill)
    room:setPlayerMark(player, "@[:]maozhu_pool-turn", pool)
  end
end

-- 判断map中是否只剩下玩家、墙、空地
-- 即检查地图中是否所有有效果的格子（+n, Hn, Un, Dn, Ln, Rn）都已被走过
function M.effectToBeDone(map)
  local n = 0
  for i = 1, #map do
    for j = 1, #map[i] do
      local cell = map[i][j]
      -- 如果既不是玩家、墙、空地，说明还有效果格子未被走过
      if cell ~= "P" and cell ~= "#" and cell ~= "." then
        n = n + 1
      end
    end
  end
  return n
end

-- 判断从玩家当前位置能否往direction方向走一格
---@param map table 地图
---@return boolean 是否能移动
function M.canMoveTo(map, direction)
  local py, px = findPlayerInMap(map)
  if not py or not px then
    return false  -- 没有找到玩家棋子
  end

  -- 计算目标位置
  local nx, ny = px, py
  if direction == "U" then
    ny = py - 1
  elseif direction == "D" then
    ny = py + 1
  elseif direction == "L" then
    nx = px - 1
  elseif direction == "R" then
    nx = px + 1
  else
    return false  -- 无效方向
  end

  -- 边界检查
  if ny < 1 or ny > #map or nx < 1 or nx > #map[ny] then
    return false
  end

  local target = map[ny][nx]

  -- 墙壁不可走
  if target == "#" then
    return false
  end

  -- 其他格子（空地、效果格等）均可走
  return true
end

function M.printMap(map, map_name)
  local emoji_map = {
    ["#"] = "#",   -- 墙壁
    ["."] = ".",   -- 空地（黑色方块）
    ["P"] = "@",   -- 玩家
    ["+"] = "+",   -- 摸牌
    ["H"] = "H",   -- 回血
    ["U"] = "^",   -- 上移
    ["D"] = "v",   -- 下移
    ["L"] = "<",   -- 左移
    ["R"] = ">",   -- 右移
  }

  local name = map_name or "未知地图"
  local name_display = name:gsub("^map_", "")
  local title = "===== " .. name_display .. " ====="
  print(title)

  for i = 1, #map do
    local line = ""
    for j = 1, #map[i] do
      local cell = map[i][j]
      local cell_type = cell:sub(1, 1)
      local emoji = emoji_map[cell_type]

      if emoji then
        line = line .. emoji
      else
        line = line .. cell
      end
    end
    print(line)
  end
  print(string.rep("=", #title))
  print()
end

---@param player ServerPlayer
function M.maozhuEffect(player)
  local room = player.room
  local suits = { "spade", "heart", "club", "diamond" }
  for _, id in ipairs(player:getCardIds("h")) do
    table.removeOne(suits, Fk:getCardById(id):getSuitString())
  end
  if #suits > 0 then
    local cards = {}
    for i = #room.draw_pile, 1, -1 do
      if table.removeOne(suits, Fk:getCardById(room.draw_pile[i]):getSuitString()) then
        table.insert(cards, room.draw_pile[i])
      end
    end
    if #suits > 0 then
      for _, id in ipairs(room.discard_pile) do
        if table.removeOne(suits, Fk:getCardById(id):getSuitString()) then
          table.insert(cards, id)
        end
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, "maozhu", nil, false, player)
      if player.dead then return end
    end
  end

  local pool = player:getTableMark("maozhu_rest-turn")
  if #pool == 0 then
    pool = table.simpleClone(map_pool)
  end
  local map_name = room:tableRandomPick(pool)
  table.removeOne(pool, map_name)
  room:setPlayerMark(player, "maozhu_rest-turn", pool)
  room:setPlayerMark(player, "@[maozhu]", {
    name = map_name,
    map = table.clone(map_table[map_name]),
  })
  local skills = player:getTableMark("@[:]maozhu_pool-turn")
  table.insertIfNeed(skills, map_skills[map_name])
  room:setPlayerMark(player, "@[:]maozhu_pool-turn", skills)
end

return M
