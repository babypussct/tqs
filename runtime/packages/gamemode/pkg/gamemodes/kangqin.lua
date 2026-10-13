
local kangqin_desc = [[
  
# 合纵抗秦简介

  ---

  ## 身份说明

  游戏由8名玩家进行，8名玩家的身份分配如下：主公，忠臣（秦兵），反贼，反贼，反贼，忠臣（汉奸），忠臣（汉奸），忠臣（秦兵）

  ---

  ## 选将

  1. 主公从8名秦势力武将中选择（嬴政、白起、芈月、赵姬、吕不韦、赵高、商鞅、张仪）

  2. 忠臣（秦兵）从3名秦势力武将中选择（步兵、骑兵、弩手）；忠臣（汉奸）从将池中选择

  3. 反贼从3名武将中随机选择（界曹操、界孙权、界刘备；均无技能），选将结束后从随机的一定数量（受房间选将数影响）的技能中选择3个获得

  ---

  ## 启用副将

  主公、忠臣正常，为选择2名武将；反贼则改为选择6个技能获得

  ---
  
  ## 随机事件

  1. **变法图强**：
  牌堆中加入3张【商鞅变法】；
  若场上有商鞅，则商鞅使用的【商鞅变法】的目标上限+1。
  
  2. **合纵连横**：
  每个回合开始时，所有角色横置；
  若场上有张仪，则拥有“横”标记的角色无法对横置状态的角色使用牌。
  
  3. **长平之战**：
  游戏开始时，进入鏖战状态（所有角色只能将【桃】当【杀】或【闪】使用、打出）；
  当一名角色成为【杀】的目标时，其需要额外使用一张【闪】抵消之；
  若场上有白起，则秦势力角色的回合开始时，其获得一张【桃】。

  4. **横扫六合**：
  牌堆中加入【传国玉玺】和【真龙长剑】；
  若场上有嬴政，游戏开始时，嬴政将【传国玉玺】和【真龙长剑】置入装备区。

  5. **吕氏春秋**：
  所有男性角色的额定摸牌数+1；
  若场上有吕不韦，当吕不韦摸牌时，摸牌数+1。

  6. **沙丘之变**：
  当一名角色死亡时，将其所有牌随机分配给所有男性角色；
  若场上有赵高，则将上述“随机分配给所有男性角色”改为“交给赵高”。

  7. **赵姬之乱**：
  当一名男性角色每回合首次造成伤害时，此伤害-1；
  若场上有赵姬，则将上述“男性角色”改为“非秦势力角色”。

  8. **始称太后**：
  游戏开始时，所有女性角色的体力值和体力上限+1；
  若场上有芈月，每名男性角色的回合开始时，其选择一项：1.令芈月回复1点体力；2.令芈月摸一张牌。

  ---

  ## 击杀奖惩

  1. 非秦势力角色死亡后，所有非秦势力角色各摸一张牌。

  2. 秦势力角色死亡后，杀死其的角色摸三张牌。

  ---

  <font color="gray">模式专属武将及模式专属卡牌请移步至OL扩展包查看</font>

]]

local qin_generals = { "shangyang", "zhangyiq", "baiqi", "yingzheng", "lvbuwei", "zhaogao", "zhaoji", "miyue" } -- 秦将
local qin_soldiers = { "qin__qibing", "qin__bubing", "qin__nushou" } -- 秦兵
local han_generals = { "", "", "ex__caocao", "ex__liubei", "ex__sunquan" } -- 汉将

--- getSkills
---@param room Room
---@param num integer
---@return string[]
local function getSkills(room, num)
  num = num
  local skills = {}
  local skill_pool = room:getTag("skill_pool")
  if num > #skill_pool then return {} end
  for i = 1, num do
    local skill = room:tableRandomPick(skill_pool)
    table.removeOne(skill_pool, skill)
    table.insert(skills, skill)
  end
  return skills
end

local kangqin_getLogic = function()
  local kangqin_logic = GameLogic:subclass("kangqin_logic")

  function kangqin_logic:initialize(room)
    GameLogic.initialize(self, room)
    self.role_table = { {"lord", "loyalist", "rebel", "rebel", "rebel", "loyalist", "loyalist", "loyalist"} }
  end

  function kangqin_logic:assignRoles()
    local room = self.room
    local players = room.players
    local n = #players
    local roles = self.role_table[1]
    table.shuffle(players)
    for i = 1, n do
      local p = players[i]
      p.role = roles[i]
      room:setPlayerProperty(p, "role_shown", true)
      room:broadcastProperty(p, "role")
    end
  end

  function kangqin_logic:chooseGenerals()
    local room = self.room
    local generalNum = room:getSettings('generalNum')
    local n = room:getSettings('enableDeputy') and 2 or 1
    local lord = room:getLord() --[[@as ServerPlayer]]
    room:setCurrent(lord)
    -- 询问选将
    local lords, soldiers = room:tableRandomPick(qin_generals, math.max(2, generalNum//3) ), table.simpleClone(qin_soldiers)
    local others = room:getNGenerals( 2* generalNum )
    local to_ask = table.filter(room.players, function(p) return p.role ~= "rebel" end)
    local req = Request:new(to_ask, "AskForGeneral")
    req.timeout = self.room:getSettings('generalTimeout')
    req.focus_text = "AskForGeneral"
    for i, p in ipairs(room.players) do
      local arg, count = nil, 0
      if p == lord then -- 主公
        arg = lords
      elseif table.contains({2,8}, i) then -- 秦兵
        arg = soldiers
      elseif table.contains({6,7}, i) then -- 汉奸
        count = count + 1
        arg = table.slice(others, (count-1)*generalNum+1, count*generalNum+1)
      else -- 反贼
        local avatar = han_generals[i]
        room:setPlayerGeneral(p, avatar, true)
        room:broadcastProperty(p, "general")
      end
      if arg then
        req:setData(p, {arg, n})
        req:setDefaultReply(p, room:tableRandomPick(arg, n))
      end
    end
    -- 设置武将
    local selected = {}
    for _, p in ipairs(to_ask) do
      local general_ret = req:getResult(p)
      local general, deputy = general_ret[1], general_ret[2]
      table.insertTableIfNeed(selected, general_ret)
      room:setPlayerGeneral(p, general, true, true)
      room:setDeputyGeneral(p, deputy)
    end
    -- 返回武将库
    local ret_generals = table.filter(others, function(g) return not table.contains(selected, g) end)
    room:returnToGeneralPile(ret_generals)
  end

  function kangqin_logic:attachSkillToPlayers()
    local room = self.room
    local n = room:getSettings('enableDeputy') and 2 or 1
    local players = room.players
    -- 创建技能池
    local skill_pool = {}
    for _, g_name in ipairs(room.general_pile) do
      local general = Fk.generals[g_name]
      if general.kingdom ~= "qin" then
        local skills = general:getSkillNameList()
        skills = table.filter(skills, function(s)
          return #Fk.skill_skels[s].tags == 0 or
            (#Fk.skill_skels[s].tags == 1 and Fk.skill_skels[s].tags[1] == Skill.Compulsory)
        end)
        table.insertTableIfNeed(skill_pool, skills)
      end
    end
    room:setTag("skill_pool", skill_pool)
    -- 选3个技能
    local num = math.floor(1.5* room:getSettings('generalNum'))
    local to_ask = table.filter(players, function (p)
      return p.role == "rebel"
    end)
    local toSelectSkills = getSkills(room, #to_ask*num)
    local req = Request:new(to_ask, "CustomDialog")
    req.focus_text = "ChooseSkillsOfHans"
    for i, p in ipairs(to_ask) do
      local choices = table.slice(toSelectSkills, (i-1)*num +1, i*num +1)
      req:setData(p, {
        component = {
          url = "packages/utility/qml/ChooseSkillBox.qml",
          model = {
            url = "packages/utility/qml/models/ChooseSkillModel.qml",
            prop = {
              skills = choices,
              min = 3*n,
              max = 3*n,
              prompt = "#kangqin-choose:::" .. tostring(3*n),
              generals = {},
            }
          },
        }
      })
      req:setDefaultReply(p, room:tableRandomPick(choices, n*3))
    end

    for _, p in ipairs(to_ask) do
      local choice = req:getResult(p)
      room:handleAddLoseSkills(p, table.concat(choice, "|"), nil, false)
    end
    -- 上技能函数
    local addRoleModSkills = function(player, skillName)
      local skill = Fk.skills[skillName]
      if not skill then
        fk.qCritical("Skill: "..skillName.." doesn't exist!")
        return
      end
      if skill:hasTag(Skill.Lord) and (player.role ~= "lord" or #room.players < 5) then
        return
      end
      if skill:hasTag(Skill.AttachedKingdom) and not table.contains(skill:getSkeleton().attached_kingdom, player.kingdom) then
        return
      end
      room:handleAddLoseSkills(player, skillName, nil, false)
    end

    local to_add = table.filter(players, function (p)
      return not table.contains(to_ask, p)
    end)
    for _, p in ipairs(to_add) do
      for _, s in ipairs(Fk.generals[p.general]:getSkillNameList(false)) do
        addRoleModSkills(p, s)
      end
      if p.deputyGeneral ~= "" then
        for _, s in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList(false)) do
          addRoleModSkills(p, s)
        end
      end
    end

    local storys = {
      "#kq__bianfa",
      "#kq__lianheng",
      "#kq__changping",
      "#kq__hengsao",
      "#kq__chunqiu",
      "#kq__shaqiu",
      "#kq__zhaoji",
      "#kq__taihou",
    }
    local story = room:tableRandomPick(storys)
    room:setBanner("@[:]kq_story", story)
    room:addSkill(story)
  end

  return kangqin_logic
end

local kangqin_mode = fk.CreateGameMode{
  name = "kangqin_mode",
  minPlayer = 8,
  maxPlayer = 8,
  logic = kangqin_getLogic,
  reward_punish = function (self, victim, killer)
    local room = victim.room
    if victim.kingdom == "qin" then
      if killer and not killer.dead then
        killer:drawCards(3, "kill")
      end
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if p.kingdom ~= "qin" and not p.dead then
          p:drawCards(1, "game_rule")
        end
      end
    end
  end,
}

Fk:loadTranslationTable{
  ["kangqin_mode"] = "合纵抗秦",
  [":kangqin_mode"] = kangqin_desc,
  ["#kangqin-choose"] = "从以下技能选择 %arg 个获得",
  ["@[:]kq_story"] = "事件",
  ["ChooseSkillsOfHans"] = "汉将技能",
}

return kangqin_mode
