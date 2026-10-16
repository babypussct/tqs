---@class HegUtil
local HegUtil = require "packages.hegemony.utilevent._base"

local U = require "packages.utility.utility"

HegUtil.GameEvent = {}

------------------------ 势力相关 ------------------------

--- 获取势力（野心家为role）
---@param player Player
---@return string
function HegUtil.getKingdom(player)
  local ret = player.kingdom
  if ret == "wild" then
    ret = player.role -- 野心家改为role（即建国势力，新月杀为了胜率统计野心家自动建国）
  end
  return ret
end

--- 势力判断
---@param from Player
---@param to Player
---@param diff boolean? @ 判断是否不同
---@param ignore_gouni boolean? @ 是否无视“构逆”
---@return boolean
function HegUtil.compareKingdomWith(from, to, diff, ignore_gouni)
  if from == to then
    return not diff
  end
  if from.kingdom == "unknown" or to.kingdom == "unknown" then
    return false
  end
  if not ignore_gouni then
    if table.contains(from:getTableMark("heg__gouni"), to) or table.contains(to:getTableMark("heg__gouni"), from) then
      return false
    end
  end
  local ret = HegUtil.getKingdom(from) == HegUtil.getKingdom(to)
  if diff then ret = not ret end
  return ret
end

--- from明置后与to势力判断
---@param from Player @ 将明置的角色
---@param to Player @ 另一角色
---@param diff boolean? @ 判断是否不同
---@return boolean?
function HegUtil.compareExpectedKingdomWith(from, to, diff)
  local room = Fk:currentRoom()
  if from == to then
    return not diff
  end

  if HegUtil.compareKingdomWith(from, to) then
    return not diff
  end
  if to.kingdom == "unknown" then
    return not diff
  end
  if from.kingdom == "unknown" then
    local kingdom = from:getMark("__heg_kingdom")
    local i = 1
    local lord = false

    for _, p in ipairs(room.players) do
      if HegUtil.getKingdom(p) == kingdom then
        i = i + 1
        if string.find(p.general, "lord") then
          lord = true
        end
      end
    end

    if i > #room.players // 2 and not lord then
      return diff
    elseif kingdom == HegUtil.getKingdom(to) then
      return not diff
    end
  end
  return diff
end

--- 获取势力角色数列表，注意键unknown的值为nil
---@param room AbstractRoom @ 房间
---@param include_dead? boolean @ 包括死人
---@return table<string, number> @ 势力与角色数映射表
function HegUtil.getKingdomPlayersNum(room, include_dead)
  local kingdomMapper = {}
  for _, p in ipairs(include_dead and room.players or room.alive_players) do
    local kingdom = HegUtil.getKingdom(p)
    if kingdom ~= "unknown" then
      kingdomMapper[kingdom] = (kingdomMapper[kingdom] or 0) + 1
    end
  end
  return kingdomMapper
end

--- 获取与某角色势力角色数
---@param room AbstractRoom @ 房间
---@param player? Player @ 角色，与此角色相同的势力，填写则覆盖``kingdom``
---@param kingdom? string @ 势力，与``player``参数至少要填写一个
---@param include_dead? boolean @ 包括死人
---@return integer
function HegUtil.getSameKingdomPlayersNum(room, player, kingdom, include_dead)
  assert(player or kingdom, "must provide player or kingdom")
  if player then kingdom = HegUtil.getKingdom(player) end
  if kingdom == "unknown" then return 0 end
  local ret = 0
  for _, p in ipairs(include_dead and room.players or room.alive_players) do
    if HegUtil.getKingdom(p) == kingdom then
      ret = ret + 1
    end
  end
  return ret
end

--- 判断角色是否为大势力角色
---@param player Player
---@return boolean
function HegUtil.isBigKingdomPlayer(player)
  if player.kingdom == "unknown" then return false end
  local room = Fk:currentRoom()

  local status_skills = room.status_skills[HegUtil.BigKingdomSkill] or Util.DummyTable ---@type HegUtil.BigKingdomSkill[]
  for _, skill in ipairs(status_skills) do
    for _, p in ipairs(room.alive_players) do
      if skill:getFixed(p) then
        return HegUtil.compareKingdomWith(p, player)
      end
    end
  end

  local mapper = HegUtil.getKingdomPlayersNum(room)
  local num = mapper[HegUtil.getKingdom(player)]
  if num < 2 then return false end
  for k, n in pairs(mapper) do
    if n > num then return false end
  end
  return true
end

--- 判断角色是否为小势力角色
---@param player ServerPlayer
---@return boolean?
function HegUtil.isSmallKingdomPlayer(player)
  if HegUtil.isBigKingdomPlayer(player) then return false end
  return not not table.find(Fk:currentRoom().alive_players, function(p) return HegUtil.isBigKingdomPlayer(p) end)
end

------------------------ 野心家相关 ------------------------

--- 野心家势力
HegUtil.wildKingdoms = {
  "heg_qin", "heg_qi", "heg_chu", "heg_yan", "heg_zhao", "heg_hanr",
  "heg_jin", "heg_han", "heg_xia", "heg_shang", "heg_zhou", "heg_liang",
}

--- 野心家武将钦点势力（钟会–汉，司马昭–晋，公孙渊–燕，孙綝–楚）
HegUtil.kingdomMapper = {
  ["ld__zhonghui"] = "heg_han",
  ["ld__simazhao"] = "heg_jin",
  ["ld__gongsunyuan"] = "heg_yan",
  ["ld__sunchen"] = "heg_chu",
}

--- 添加野心家武将钦点势力
function HegUtil.addWildKingdomMap(general, kingdom)
  HegUtil.kingdomMapper[general] = kingdom
end

--- 野心家选择国家
---@param player ServerPlayer
---@param generalName string
---@return string? @ 建立的国家
function HegUtil.wildChooseKingdom(player, generalName)
  local room = player.room
  local allKingdoms = room:getBanner("all_kingdoms")
  table.insertTable(allKingdoms, {"unknown", "hidden"})

  local choice
  local all_choices = table.clone(HegUtil.wildKingdoms)
  local choices = table.clone(all_choices)
  for _, p in ipairs(room.players) do
    table.removeOne(choices, p.role)
  end
  if player.general == generalName and
    HegUtil.kingdomMapper[generalName] and HegUtil.kingdomMapper[generalName] ~= player.role then -- 野心家钦定
    if table.contains(choices, HegUtil.kingdomMapper[generalName]) then
      choice = HegUtil.kingdomMapper[generalName]
    else
      choice = room:askToChoice(player, {
        choices = choices,
        skill_name = "game_rule",
        prompt = "#wild-choose",
        cancelable = false,
        all_choices = all_choices,
      })
    end
  elseif table.contains(allKingdoms, player.role) then
    choice = room:askToChoice(player, {
      choices = choices,
      skill_name = "game_rule",
      prompt = "#wild-choose",
      cancelable = false,
      all_choices = all_choices,
    })
  end

  if choice then
    player.role = choice
    room:setPlayerProperty(player, "role_shown", true)
    room:broadcastProperty(player, "role")

    room:sendLog{
      type = "#WildChooseKingdom",
      from = player.id,
      arg = choice,
      arg2 = "wild",
    }
  end
  return choice
end

--- 询问加入建国
---@param player ServerPlayer
---@param generalName string
---@param isActive boolean
---@return boolean @ 是否成功加入
function HegUtil.AskForBuildCountry(player, generalName, isActive)
  local room = player.room
  if not (player.general == generalName and HegUtil.kingdomMapper[generalName]) then return false end
  local choices = { "heg_rule_join_country:"..player.id.."::"..player.role, "Cancel" }
  for _, p in ipairs(room:getAlivePlayers()) do
    if p:getMark("__heg_join_wild") == 0 and p.kingdom ~= "wild" and not string.find(p.general, "lord") and
      (not isActive or p.general ~= "anjiang") then
      local choice = room:askToChoice(p, {
        choices = choices,
        skill_name = "game_rule",
        prompt = "#wild_join-choose",
      })
      if choice ~= "Cancel" then
        room:setPlayerProperty(p, "role_shown", true)
        room:setPlayerProperty(p, "role", player.role)
        room:sendLog{
          type = "#WildChooseKingdom",
          from = p.id,
          arg = player.role,
          arg2 = "wild",
        }
        room:setPlayerProperty(p, "kingdom", "wild")
        room:setPlayerMark(p, "__heg_join_wild", 1)
        room:setPlayerMark(player, "__heg_construct_wild", 1)
        room:sendLog{
          type = "#SuccessBuildCountry",
          from = player.id,
          arg = player.role,
          arg2 = p.general,
        }
        room:recover({
          who = p,
          num = 1,
          recoverBy = player,
          skillName = "game_rule",
        })
        if p:getHandcardNum() < 4 and not p.dead then
          p:drawCards(4 - p:getHandcardNum(), "game_rule")
        end
        return true
      end
    end
  end
  return false
end

------------------------ 阵型 ------------------------

--- 获取与角色成队列的其余角色
---@param player Player
---@return ServerPlayer[] @ 队列中的角色
function HegUtil.getFormationRelation(player)
  if player:isRemoved() then return {} end
  local players = {}
  local p = player
  while true do
    p = p:getNextAlive(false)
    if p == player then break end
    if HegUtil.compareKingdomWith(p, player) then
      table.insert(players, p)
    else
      break
    end
  end
  p = player
  while true do
    p = p:getLastAlive(false)
    if p == player then break end
    if HegUtil.compareKingdomWith(p, player) then
      table.insertIfNeed(players, p)
    else
      break
    end
  end
  return players
end

--- 确认与某角色是否处于队列中
---@param player Player @ 角色1
---@param target Player @ 角色2，若为 player 即 player 是否处于某一队列
---@return boolean
function HegUtil.inFormationRelation(player, target)
  if target == player then
    return #HegUtil.getFormationRelation(player) > 0
  else
    return table.contains(HegUtil.getFormationRelation(player), target)
  end
end

--- 确认与某角色是否处于围攻关系
---@param player Player @ 围攻角色1
---@param target Player @ 围攻角色2，可填 player
---@param victim Player @ 被围攻角色
---@return boolean?
function HegUtil.inSiegeRelation(player, target, victim)
  if HegUtil.compareKingdomWith(player, victim) or
    not HegUtil.compareKingdomWith(player, target) or
    victim.kingdom == "unknown" then
    return false
  end
  if player == target then
    return (player:getNextAlive() == victim and player:getNextAlive(false, 2) ~= player and HegUtil.compareKingdomWith(player:getNextAlive(false, 2), player))
    or (victim:getNextAlive() == player and player:getLastAlive(false, 2) ~= player and HegUtil.compareKingdomWith(player:getLastAlive(false, 2), player))
  else
    return (player:getNextAlive() == victim and victim:getNextAlive() == target) -- P V T
    or (victim:getNextAlive() == player and target:getNextAlive() == victim) -- T V P
  end
end

--- 阵法召唤技
---@class HegUtil.ArraySummonSkill : ActiveSkill
HegUtil.ArraySummonSkill = ActiveSkill:subclass("HegUtil.ArraySummonSkill")

--- 阵法类型
HegUtil.ArraySummonSkill.arrayType = ""

---@param player Player
---@return boolean?
function HegUtil.ArraySummonSkill:canUse(player, card)
  local room = Fk:currentRoom()
  local ret = self:isEffectable(player) and player:usedEffectTimes(self.name, Player.HistoryPhase) == 0 and player.kingdom ~= "wild"
    and HegUtil.inGeneralSkills(player, self:getSkeleton().name) and table.find(room.alive_players, function(p) return p.kingdom == "unknown" end)
    and HegUtil.getKingdomPlayersNum(room, true)[HegUtil.getKingdom(player)] < #room.players // 2
  if not ret then return false end
  local pattern = self.arrayType
  if pattern == "formation" then -- 队列
    local p = player
    while true do
      p = p:getNextAlive() -- 下家
      if p == player then break end
      if not HegUtil.compareKingdomWith(p, player) then
        if p.kingdom == "unknown" then return true
        else break end
      end
    end
    while true do
      p = p:getLastAlive() -- 上家
      if p == player then break end
      if not HegUtil.compareKingdomWith(p, player) then
        if p.kingdom == "unknown" then return true
        else break end
      end
    end
  elseif pattern == "siege" then -- 围攻
    if HegUtil.compareKingdomWith(player:getNextAlive(), player, true) and player:getNextAlive(false, 2).kingdom == "unknown" then return true end
    if HegUtil.compareKingdomWith(player:getLastAlive(), player, true) and player:getLastAlive(false, 2).kingdom == "unknown" then return true end
  end
  return false
end

---@param room Room
---@param effect SkillUseData
---@return boolean?
function HegUtil.ArraySummonSkill:onUse(room, effect)
  local player = effect.from
  local pattern = self.arrayType
  local kingdom = HegUtil.getKingdom(player)
  local function arraySummonAskForReveal(_kingdom, to, skill_name)
    local flag = ""
    if HegUtil.compareExpectedKingdomWith(to, player) then
      local general = Fk.generals[to:getMark("__heg_general")]
      if (general.kingdom == _kingdom or general.subkingdom == _kingdom) then flag = flag .. "m" end
      general = Fk.generals[to:getMark("__heg_deputy")]
      if (general.kingdom == _kingdom or general.subkingdom == _kingdom) then flag = flag .. "d" end
    end
    return HegUtil.askToRevealGenerals(to, {
      skill_name = skill_name,
      flag = flag,
    }) ~= "Cancel"
  end
  if pattern == "formation" then
    for i = 1, 2 do
      local p = player
      while true do
        if HegUtil.getKingdomPlayersNum(room, true)[kingdom] >= #room.players // 2 then break end
        ---@diagnostic disable-next-line: cast-local-type
        p = i == 1 and p:getNextAlive() or p:getLastAlive()
        if p == player then break end
        if not HegUtil.compareKingdomWith(p, player) then
          if p.kingdom == "unknown" then
            if not arraySummonAskForReveal(kingdom, p, self:getSkeleton().name) then break end
          else break end
        end
      end
    end
  elseif pattern == "siege" then -- 围攻
    local p
    if HegUtil.compareKingdomWith(player:getNextAlive(), player, true) then
      p = player:getNextAlive(false, 2)
    elseif HegUtil.compareKingdomWith(player:getLastAlive(), player, true) and HegUtil.getKingdomPlayersNum(room, true)[kingdom] < #room.players // 2 then
      p = player:getLastAlive(false, 2)
    end
    if p.kingdom == "unknown" then
      arraySummonAskForReveal(kingdom, p, self:getSkeleton().name)
    end
  end
end

---@class ArraySummonSpec: ActiveSkillSpec
---@field public array_type string @ 阵型类型

---@class SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: "arraysummon", data: BigKingdomSpec, attribute: nil)

--- 阵法召唤技
---@param key 'arraysummon'
---@param spec ArraySummonSpec
---@return HegUtil.ArraySummonSkill
function HegUtil:CreateArraySummonSkill(_skill, idx, key, attr, spec)
  assert(type(spec.array_type) == "string")
  local new_name = string.format("#%s_%d_arraysummon", _skill.name, idx)
  Fk:loadTranslationTable({ [new_name] = Fk:translate(_skill.name) }, Config.language)

  local skill = HegUtil.ArraySummonSkill:new(new_name, #_skill.tags > 0 and _skill.tags[1] or Skill.NotFrequent)
  fk.readUsableSpecToSkill(skill, spec)
  -- fk.readInteractionToSkill(skill, spec)

  skill.arrayType = spec.array_type -- 围攻 siege，队列 formation

  if spec.can_use then skill.canUse = spec.can_use end -- 可扩展
  if spec.on_use then skill.onUse = spec.on_use end

  return skill
end

Fk:addSkillType("arraysummon", HegUtil.CreateArraySummonSkill, 5)

Fk:loadTranslationTable{
  ["heg_formation"] = "队列",
  ["heg_formation_href"] = "队列：连续相邻的至少两名势力相同的角色处于同一队列",
  ["heg_siege"] = "围攻",
  --线下对垒……
}

------------------------ 武将牌相关 ------------------------

--- 判断有无主将/副将
---@param player Player
---@param isDeputy boolean?
---@return boolean?
function HegUtil.hasGeneral(player, isDeputy)
  local orig = isDeputy and (player.deputyGeneral or "") or player.general
  return orig ~= "" and not orig:startsWith("blank_")
end

--- 获得真正的主将/副将（而非暗将）
---@param player Player
---@param isDeputy boolean?
---@return string
function HegUtil.getActualGeneral(player, isDeputy)
  if isDeputy then
    return player.deputyGeneral == "anjiang" and player:getMark("__heg_deputy") or player.deputyGeneral or ""
  else
    return player.general == "anjiang" and player:getMark("__heg_general") or player.general
  end
end

--- 移除武将
---@param player ServerPlayer @ 被移除武将的玩家
---@param isDeputy boolean? @ 是否是移除副将
---@return string @ 返回被移除的武将
function HegUtil.removeGeneral(player, isDeputy)
  local room = player.room
  local orig_general, new_general = HegUtil.getActualGeneral(player, isDeputy), "blank_shibing"
  if Fk.generals[orig_general].gender ~= General.Male then
    new_general = "blank_nvshibing"
  end
  room:setPlayerMark(player, isDeputy and "__heg_deputy" or "__heg_general", new_general)
  room:changeHero(player, new_general, false, isDeputy, true, false, false)
  return orig_general
end

--- 获取明置的武将牌数
---@param player Player
---@return integer
function HegUtil.getGeneralsRevealedNum(player)
  local num = 0
  if player.general ~= "anjiang" then num = num + 1 end
  if player.deputyGeneral and player.deputyGeneral ~= "anjiang" then num = num + 1 end
  return num
end

--- 是否明置所有武将牌
---@param player Player
---@return boolean
function HegUtil.allGeneralsRevealed(player)
  local num = HegUtil.getGeneralsRevealedNum(player)
  if player.deputyGeneral and player.deputyGeneral ~= "" then return num == 2
  else return num == 1 end
end

-- 君主将。
HegUtil.lordGenerals = {} ---@type table<string, string> @ 普通将 --> 君主将

--- 获取所属势力的君主，可能为nil
---@param room AbstractRoom
---@param player Player
---@return Player? @ 君主
function HegUtil.getHegLord(room, player)
  local kingdom = HegUtil.getKingdom(player)
  return table.find(room.alive_players, function(p)
    return p.kingdom == kingdom and not not string.find(p.general, "lord")
  end)
end

--- 获取是否有君主拥有技能
---@param room AbstractRoom
---@param player Player
---@param skill string
---@return boolean
function HegUtil.hasHegLordSkill(room, player, skill)
  return not not HegUtil.getHegLord(room, player) and HegUtil.getHegLord(room, player):hasSkill(skill)
end

---@class AskForRevealGeneralsParams
---@field skill_name string @ 发起亮将的技能名
---@field prompt? string @ 烧条上面显示的提示文本内容
---@field flag? string @ "m"仅主将，"d"仅副将，"md"全亮。默认可以全亮
---@field cancelable? boolean  @ 是否可以取消。默认可以
---@field lord_convert? boolean  @ 是否可以变为君主。默认不可以
---@field revealAll? boolean @ 是否可以全亮。默认可以

--- 询问亮将
---@param player ServerPlayer @ 被询问亮将的玩家
---@param params AskForRevealGeneralsParams @ 各种变量
---@return string @ 返回选择的选项（"m"、"d"、"md"、"Cancel"）
function HegUtil.askToRevealGenerals(player, params)
  local room = player.room
  if HegUtil.allGeneralsRevealed(player) then
    return "Cancel"
  end
  local skill_name = params.skill_name or "heg_rule"
  local flag = params.flag or "md"
  local cancelable = params.cancelable == nil and true or params.cancelable
  local lord_convert = params.lord_convert or false
  local revealAll = params.revealAll == nil and true or params.revealAll

  local all_choices = {
    "revealMain:::" .. player:getMark("__heg_general"),
    "revealDeputy:::" .. player:getMark("__heg_deputy"),
    "revealAll",
    "Cancel",
  }
  local choices = {}
  if string.find(flag, "m") and player.general == "anjiang" and not player:prohibitReveal() then
    table.insert(choices, "revealMain:::" .. player:getMark("__heg_general"))
  end
  if string.find(flag, "d") and player.deputyGeneral == "anjiang" and not player:prohibitReveal(true) then
    table.insert(choices, "revealDeputy:::" .. player:getMark("__heg_deputy"))
  end
  if #choices == 2 and flag == "md" and revealAll then
    table.insert(choices, "revealAll")
  end
  if cancelable then
    table.insert(choices, "Cancel")
  end
  if #choices == 0 then
    return "Cancel"
  end

  -- 能否变身君主
  local convert = false
  if lord_convert and room:getBanner("RoundCount") == 1 and player:getMark("hasShownMainGeneral") == 0 then
    local lord = HegUtil.lordGenerals[player:getMark("__heg_general")]
    if lord then
      if not table.contains(room.disabled_packs, Fk.generals[lord].package.name) and not table.contains(room.disabled_generals, lord) then
        convert = true
      end
    end
  end

  local prompt = params.prompt
  if prompt == nil then
    if convert then
      prompt = "#HegPrepareConvertLord"
    else
      prompt = "#HegRevealGenerals"
    end
  end

  local choice = room:askToChoice(player, {
    choices = choices,
    skill_name = skill_name,
    prompt = prompt,
    all_choices = all_choices,
    cancelable = false,
  })
  -- 先变身君主
  local doConvert = false
  if convert and (choice:startsWith("revealMain") or choice == "revealAll") then
    local lordGeneral = HegUtil.lordGenerals[player:getMark("__heg_general")]
    doConvert = room:askToChoice(player, {
      choices = {
        "ConvertToLord:::" .. lordGeneral,
        "Cancel",
      },
      skill_name = skill_name,
    }) ~= "Cancel"
    if doConvert then
      local normalGeneral = player:getMark("__heg_general")
      room:setPlayerMark(player, "__heg_general", lordGeneral)
      -- 以下一坨用来处理技能
      --room:changeHero(player, lordGeneral, false, false, false, false, false)
      --player:hideGeneral(false)
      local tolose = {}
      for _, s in ipairs(Fk.generals[normalGeneral]:getSkillNameList(true)) do
        local skill = Fk.skills[s]
        if player:isFakeSkill(skill) then
          player:loseFakeSkill(skill)
        else
          table.insert(tolose, skill.name)
        end
      end
      local ret = true
      if player.deputyGeneral == "anjiang" then
        local other = Fk.generals[player:getMark("__heg_deputy")]
        for _, sname in ipairs(other:getSkillNameList(true)) do
          local s = Fk.skills[sname]
          if s:hasTag(Skill.Compulsory) and not s:hasTag(Skill.MainPlace) and player:isFakeSkill(s) then
            ret = false
            break
          end
        end
      end
      if ret then
        player:loseFakeSkill("reveal_skill&")
      end

      local general = Fk.generals[lordGeneral]
      local skills = general:getSkillNameList(true)

      for _, sn in ipairs(skills) do
        room:addFakeSkill(player, sn)
      end

      -- local general = Fk.generals[lordGeneral]
      local deputy = Fk.generals[player:getMark("__heg_deputy")]
      local dmaxHp = deputy.maxHp + deputy.deputyMaxHpAdjustedValue
      local gmaxHp = general.maxHp + general.mainMaxHpAdjustedValue
      local maxHp = (dmaxHp + gmaxHp) // 2
      local num = maxHp - player.maxHp
      if num > 0 then
        player.maxHp = maxHp
        player.hp = player.hp + num
        room:broadcastProperty(player, "maxHp")
        room:broadcastProperty(player, "hp")
      end
      if (dmaxHp + gmaxHp) % 2 == 1 then -- 重新计算阴阳鱼
        player:setMark("HalfMaxHpLeft", 1)
        player:doNotify("SetPlayerMark", { player.id, "HalfMaxHpLeft", 1})
      else
        player:setMark("HalfMaxHpLeft", 0)
        player:doNotify("SetPlayerMark", { player.id, "HalfMaxHpLeft", 0})
      end
      player:setMark("CompanionEffect", 1)
      player:doNotify("SetPlayerMark", { player.id, "CompanionEffect", 1})
    end
  end

  if choice:startsWith("revealMain") then
    player:revealGeneral(false)
    return "m"
  elseif choice:startsWith("revealDeputy") then
    player:revealGeneral(true)
    return "d"
  elseif choice == "revealAll" then
    player:revealGenerals()
    return "md"
  elseif choice == "Cancel" then
    return "Cancel"
  end
  return "Cancel"
end

Fk:loadTranslationTable{
  ["#HegRevealGenerals"] = "国战规则：请选择要明置的武将",
  ["#HegPrepareConvertLord"] = "国战规则：请选择要明置的武将（仅本次明置主将可变身君主）",
  ["ConvertToLord"] = "<b>变身为<font color='goldenrod'>%arg</font></b>！",
}

--- A暗置B的武将牌
---@param room Room
---@param player ServerPlayer
---@param target ServerPlayer
---@param skill_name string
---@return boolean @ 是否为副将
function HegUtil.doHideGeneral(room, player, target, skill_name)
  if player.dead or target.dead then return false end
  local all_choices = {target.general, target.deputyGeneral}
  local disable_choices = {}
  if not (target.general ~= "anjiang" and not target.general:startsWith("blank_") and not string.find(target.general, "lord")) then -- 耦合君主
    table.insert(disable_choices, target.general)
  end
  if not (target.deputyGeneral ~= "anjiang" and not target.deputyGeneral:startsWith("blank_")) then
    table.insert(disable_choices, target.deputyGeneral)
  end
  if #disable_choices == 2 then return false end
  local generals = U.askToChooseGeneralsAndChoice(player,{
    skill_name = skill_name,
    generals = all_choices,
    prompt = "#hide_general-ask::" .. target.id .. ":" .. skill_name,
    min_num = 1,
    max_num = 1,
    disable_generals = disable_choices,
  })
  local isDeputy = generals[1] == target.deputyGeneral
  if isDeputy then room:setPlayerMark(target, "__heg_deputy", target.deputyGeneral)
  else room:setPlayerMark(target, "__heg_general", target.general) end
  target:hideGeneral(isDeputy)
  room:sendLog{
    type = "#HideOtherGeneral",
    from = player.id,
    to = {target.id},
    arg = isDeputy and "deputyGeneral" or "mainGeneral",
    arg2 = isDeputy and target:getMark("__heg_deputy") or target:getMark("__heg_general"),
  }
  return isDeputy
end
Fk:loadTranslationTable{
  ["#hide_general-ask"] = "%arg：暗置 %dest 一张武将牌",
  ["#HideOtherGeneral"] = "%from 暗置了 %to 的 %arg %arg2",
}

--- 根据技能暗置武将牌
---@param player ServerPlayer
---@param skill string | Skill
---@param allowBothHidden? boolean?
---@return string? @ 暗置的是主将还是副将，或没有暗置
function HegUtil.hideBySkillName(player, skill, allowBothHidden)
  local isDeputy = HegUtil.inGeneralSkills(player, skill)
  if isDeputy and (allowBothHidden or HegUtil.allGeneralsRevealed(player)) then
    player:hideGeneral(isDeputy == "d")
    return isDeputy
  end
end

--- 观看武将牌
---@param player ServerPlayer
---@param target ServerPlayer
---@param skillName string
---@param isMain? boolean @ 是否观看主将
---@param isDeputy? boolean @ 是否观看副将
---@param prompt? string
---@return string @ 返回被观看的武将
function HegUtil.viewGeneral(player, target, skillName, isMain, isDeputy, prompt)
  local generals = {isMain and target:getMark("__heg_general") or target.general, isDeputy and target:getMark("__heg_deputy") or target.deputyGeneral}
  prompt = prompt or ("#ViewGeneral::" .. target.id .. ":" .. skillName .. ":" .. ((isMain and Fk:translate("mainGeneral") or "") .. (isDeputy and Fk:translate("deputyGeneral") or "")))
  local room = player.room
  room:askToCustomDialog(player, {
    skill_name = skillName,
    component = {
      url = "packages/hegemony/qml/KnownBothBox.qml",
      model = {
        url = "packages/utility/qml/models/ChooseGeneralsAndChoiceModel.qml",
        prop = {
          cards = generals,
          all_cards = generals,
          disable_cards = {},
          min = 0,
          max = 0,
          prompt = prompt,
          ok_options = {"OK"},
          cancel_options = {},
        }
      }
    },
  })
  room:sendLog{
    type = "#ViewGeneralLog",
    from = player.id,
    to = {target.id},
    arg = (isMain and Fk:translate("mainGeneral") or "") .. (isDeputy and Fk:translate("deputyGeneral") or ""),
  }
  return isMain and target:getMark("__heg_general") or target:getMark("__heg_deputy")
end

Fk:loadTranslationTable{
  ["#ViewGeneral"] = "%arg：观看 %dest 的 %arg2",
  ["#ViewGeneralLog"] = "%from 观看了 %to 的 %arg",
}

-- 技能相关

--- 技能是否为主将/副将武将牌上的技能，返回“m”“d”或nil
---@param player Player
---@param skill string | Skill @ 技能，建议技能名
---@return string?
function HegUtil.inGeneralSkills(player, skill)
  assert(type(skill) == "string" or skill:isInstanceOf(Skill))
  if type(skill) ~= "string" then skill = skill.name end
  -- A prelighted hidden skill is still owned by its original slot while the
  -- public general field is `anjiang`.  Resolve the private marks first so
  -- callers such as Jilix/Qingyin remove or transform the correct main/deputy
  -- general after the hidden skill has actually taken effect.
  local main = HegUtil.getActualGeneral(player, false)
  local deputy = HegUtil.getActualGeneral(player, true)
  if Fk.generals[main] and table.contains(Fk.generals[main]:getSkillNameList(), skill) then
    return "m"
  elseif deputy ~= "" and Fk.generals[deputy] and table.contains(Fk.generals[deputy]:getSkillNameList(), skill) then
    return "d"
  end
  return nil
end

------------------------ 国战标记 ------------------------

--- 国战标记类型
---@alias HegMarkType "vanguard" | "yinyangfish" | "companion" | "wild"

--- 添加国战标记
---@param player ServerPlayer @ 角色
---@param markName string|HegMarkType @ 标记种类
---@param number? integer @ 数量，默认为1
function HegUtil.addHegMark(player, markName, number)
  local room = player.room
  number = number or 1
  if markName == "vanguard" then
    room:addPlayerMark(player, "@!!vanguard", number)
    room:handleAddLoseSkills(player, "vanguard_skill&")
  elseif markName == "yinyangfish" then
    room:addPlayerMark(player, "@!!yinyangfish", number)
    room:handleAddLoseSkills(player, "yinyangfish_skill&")
  elseif markName == "companion" then
    room:addPlayerMark(player, "@!!companion", number)
    room:handleAddLoseSkills(player, "companion_skill&")
  elseif markName == "wild" then
    room:addPlayerMark(player, "@!!wild", number)
    room:handleAddLoseSkills(player, "wild_skill&")
  end
end

Fk:loadTranslationTable{
  ["@!!vanguard"] = "先驱",
  [":@!!vanguard"] = "出牌阶段，你可弃一枚“先驱”，将手牌摸至4张，然后观看一名其他角色的一张暗置武将牌。",
  ["@!!yinyangfish"] = "阴阳鱼",
  [":@!!yinyangfish"] = "①出牌阶段，你可弃一枚“阴阳鱼”，摸一张牌；②弃牌阶段开始时，你可弃一枚“阴阳鱼”，此回合手牌上限+2。",
  ["@!!companion"] = "珠联璧合",
  [":@!!companion"] = "①出牌阶段，你可弃一枚“珠联璧合”，摸两张牌；②你可弃一枚“珠联璧合”，视为使用【桃】。",
  ["@!!wild"] = "野心家",
  [":@!!wild"] = "你可弃一枚“野心家”，执行“先驱”、“阴阳鱼”或“珠联璧合”的效果。",
}

--- 移除国战标记
---@param room Room @ 房间
---@param player ServerPlayer @ 角色
---@param markName string|HegMarkType @ 标记种类
---@param number? integer @ 数量，默认为1
function HegUtil.removeHegMark(room, player, markName, number)
  number = number or 1
  if markName == "vanguard" then
    room:removePlayerMark(player, "@!!vanguard", number)
    if player:getMark("@!!vanguard") == 0 then
      room:handleAddLoseSkills(player, "-vanguard_skill&")
    end
  elseif markName == "yinyangfish" then
    room:removePlayerMark(player, "@!!yinyangfish", number)
    if player:getMark("@!!yinyangfish") == 0 then
      room:handleAddLoseSkills(player, "-yinyangfish_skill&")
    end
  elseif markName == "companion" then
    room:removePlayerMark(player, "@!!companion", number)
    if player:getMark("@!!companion") == 0 then
      room:handleAddLoseSkills(player, "-companion_skill&")
    end
  elseif markName == "wild" then
    room:removePlayerMark(player, "@!!wild", number)
    if player:getMark("@!!wild") == 0 then
      room:handleAddLoseSkills(player, "-wild_skill&")
    end
  end
end

------------------------ 鏖战 ------------------------

--鏖战
---@param room Room
function HegUtil.enterBattleRoyalMode(room)
  local isold = room:getSettings("old_battle_royal")
  if isold then
   room:doBroadcastNotify("ShowToast", Fk:translate("#EnterBattleRoyalMode"))
  else
   room:doBroadcastNotify("ShowToast", Fk:translate("#EnterNewBattleRoyalMode"))
  end
  room:sendLog{ type = "#EnterBattleRoyalModeLog" }
  room:setTag("BattleRoyalMode", true)
  if isold then
    room:setBanner("@[:]BattleRoyalDummy", "BattleRoyalMode")
  else
    room:setBanner("@[:]BattleRoyalDummy", "NewBattleRoyalMode")
  end
  local name = isold and "battle_royal&" or "new_battle_royal&"
  for _, p in ipairs(room.alive_players) do
    room:handleAddLoseSkills(p, name, nil, false)
  end
  if not isold then
    room:addSkill("#new_battle_royal_event&")
  end
end

------------------------ 合纵 ------------------------

HegUtil.allianceCards = {}

--- 向合纵库中加载一张卡牌。
---@param card table @ 要加载的卡牌
function HegUtil.addCardToAllianceCards(card)
  table.insertIfNeed(HegUtil.allianceCards, card)
end

--- 向扩展包添加一张可合纵的牌。
---@param extension Package
---@param name string
---@param suit integer
---@param number integer
function HegUtil.addAllianceCardSpec(extension, name, suit, number)
  extension:addCardSpec(name, suit, number)
  HegUtil.addCardToAllianceCards{name, suit, number}
end

--- 可合纵
---@param from Player
---@param to Player
---@return boolean
function HegUtil.canAlliance(from, to)
  if to == from then return false end
  if HegUtil.compareKingdomWith(from, to, true) or to.kingdom == "unknown" then return true end
  local status_skills = Fk:currentRoom().status_skills[HegUtil.AllianceSkill] or Util.DummyTable
  for _, skill in ipairs(status_skills) do
    if skill:allowAlliance(from, to) then
      return true
    end
  end
  return false
end

--- 允许合纵技
---@class AllianceSkill : StatusSkill
HegUtil.AllianceSkill = StatusSkill:subclass("AllianceSkill")

---@param from Player
---@param to Player
---@return boolean
function HegUtil.AllianceSkill:allowAlliance(from, to)
  return false
end

---@class AllianceSpec: StatusSkillSpec
---@field public allow_alliance? fun(self: AllianceSkill, from: Player, to:Player): boolean?

---@param spec AllianceSpec
---@return AllianceSkill
HegUtil.CreateAllianceSkill = function(spec)
  assert(type(spec.name) == "string")
  assert(type(spec.allow_alliance) == "function")

  local skill = HegUtil.AllianceSkill:new(spec.name)
  fk.readStatusSpecToSkill(skill, spec)
  skill.allowAlliance = spec.allow_alliance or skill.allowAlliance
  return skill
end

-- 卡牌替换

--- 卡牌替换库，键为旧牌牌名，值为新牌牌名
HegUtil.convertCards = {} ---@type table<string, string>

--- 向卡牌替换库中添加牌名映射。（君主替换）（修改：只能替换为一种）
---@param newName string @ 要替换的卡牌的卡牌名（如飞龙夺凤）
---@param oldName string @ 要被替换的卡牌名（如雌雄双股剑）
function HegUtil.addCardToConvertCards(newName, oldName)
  HegUtil.convertCards[oldName] = newName
end

-- 大势力

--- 视为大势力技
---@class HegUtil.BigKingdomSkill : StatusSkill
HegUtil.BigKingdomSkill = StatusSkill:subclass("HegUtil.BigKingdomSkill")

--- 视为大势力
---@param player Player
---@return boolean?
function HegUtil.BigKingdomSkill:getFixed(player)
  return false
end

---@class BigKingdomSpec: StatusSkillSpec
---@field public fixed_func? fun(self: HegUtil.BigKingdomSkill, player: Player): boolean?

---@class SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: "bigkingdom", data: BigKingdomSpec, attribute: nil)

---@param key 'bigkingdom'
---@param spec BigKingdomSpec
---@return HegUtil.BigKingdomSkill
function HegUtil:CreateBigKingdomSkill(_skill, idx, key, attr, spec)
  assert(type(spec.fixed_func) == "function")
  local new_name = string.format("#%s_%d_bigkingdom", _skill.name, idx)
  Fk:loadTranslationTable({ [new_name] = Fk:translate(_skill.name) }, Config.language)

  local skill = HegUtil.BigKingdomSkill:new(new_name, #_skill.tags > 0 and _skill.tags[1] or Skill.Compulsory)
  fk.readStatusSpecToSkill(skill, spec)

  if spec.fixed_func then
    skill.getFixed = spec.fixed_func
  end

  return skill
end

Fk:addSkillType("bigkingdom", HegUtil.CreateBigKingdomSkill)

-- 调虎离山
--- RemovePlayerData 描述和调离有关的数据
---@class RemovePlayerDataSpec
---@field public who ServerPlayer @ 被调离的角色

---@class HegUtil.RemovePlayerData: RemovePlayerDataSpec, TriggerData
HegUtil.RemovePlayerData = TriggerData:subclass("RemovePlayerData")

--- 调离事件
---@class HegUtil.RemovePlayerEvent: TriggerEvent
---@field public data HegUtil.RemovePlayerData
HegUtil.RemovePlayerEvent = TriggerEvent:subclass("RemovePlayerEvent")

--- 被调离改变后
--- 
--- 原RemoveStateChanged
---@class HegUtil.PlayerRemoved: HegUtil.RemovePlayerEvent
HegUtil.PlayerRemoved = HegUtil.RemovePlayerEvent:subclass("HegUtil.PlayerRemoved")

---@alias PlayerRemoveTrigFunc fun(self: TriggerSkill, event: HegUtil.RemovePlayerEvent,
---  target: ServerPlayer, player: ServerPlayer, data: HegUtil.RemovePlayerData):any

---@class SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: HegUtil.RemovePlayerEvent,
---  data: TrigSkelSpec<PlayerRemoveTrigFunc>, attr: TrigSkelAttribute?): SkillSkeleton

--为了复刻易位，重新判断国战标记（阴阳鱼和珠联）（仅限非双亮，会在双亮之后给，不会扣除已有标记）
---@param p ServerPlayer
function HegUtil.judegHegMark(p)
  local room = p.room
  local general = Fk.generals[HegUtil.getActualGeneral(p, false)]
  local deputy = Fk.generals[HegUtil.getActualGeneral(p, true)]
  local dmaxHp = deputy.maxHp + deputy.deputyMaxHpAdjustedValue
  local gmaxHp = general.maxHp + general.mainMaxHpAdjustedValue

  if (dmaxHp + gmaxHp) % 2 == 1 and not HegUtil.allGeneralsRevealed(p) and not string.find(general.name, "blank_") and not string.find(deputy.name, "blank_") then
    p:setMark("HalfMaxHpLeft", 1)
    p:doNotify("SetPlayerMark", { p.id, "HalfMaxHpLeft", 1})
  else
    room:setPlayerMark(p, "HalfMaxHpLeft", 0)
  end
  if general:isCompanionWith(deputy) and not HegUtil.allGeneralsRevealed(p) then
    p:setMark("CompanionEffect", 1)
    p:doNotify("SetPlayerMark", { p.id, "CompanionEffect", 1})
  else
    room:setPlayerMark(p, "CompanionEffect", 0)
  end
end

--- 易位（交换副将）
---@param room Room
---@param player ServerPlayer
---@param target ServerPlayer
---@return boolean
function HegUtil.swapDeputy(room, player, target)
  if target == player then return false end
  if not (player.deputyGeneral and target.deputyGeneral) then return false end
  local g1hide, g2hide = false, false
  if player.deputyGeneral == "anjiang" then g1hide = true end
  if target.deputyGeneral == "anjiang" then g2hide = true end
  local general1 = player.deputyGeneral == "anjiang" and player:getMark("__heg_deputy") or player.deputyGeneral
  local general2 = target.deputyGeneral == "anjiang" and target:getMark("__heg_deputy") or target.deputyGeneral

  local general11 = Fk.generals[general1]
  local general22 = Fk.generals[general2]

  --私人牌堆交换

  local pile1 = {} ---@type string[]
  local pile2 = {} ---@type string[]

  for _, s in pairs(general11:getSkillNameList()) do
    local skill = Fk.skill_skels[s]
    if skill.derived_piles and #skill.derived_piles > 0 then
      for _, p in ipairs(skill.derived_piles) do
        table.insert(pile1, p)
      end
    end
  end

  for _, s in pairs(general22:getSkillNameList()) do
    local skill = Fk.skill_skels[s]
    if skill.derived_piles and #skill.derived_piles > 0 then
      for _, p in ipairs(skill.derived_piles) do
        table.insert(pile2, p)
      end
    end
  end

  local s1 = {} ---@type integer[]
  local s2 = {} ---@type integer[]

  if #pile1 > 0 then
    for _, s in ipairs(pile1) do
      local cards = player:getPile(s)
      if #cards > 0 then
        table.insertTableIfNeed(s1, cards)
      end
    end
  end

  if #pile2 > 0 then
    for _, s in ipairs(pile2) do
      local cards = target:getPile(s)
      if #cards > 0 then
        table.insertTableIfNeed(s2, cards)
      end
    end
  end

  local tolose1 = {}
  --先把技能lose掉，就不会触发handleaddlose的失去技能效果了(不丢武将牌上的牌)
  for _, s in ipairs(Fk.generals[general1]:getSkillNameList()) do
    if player:hasSkill(s, true, true) then
      local lost_skills = player:loseSkill(s)
      for _, ss in ipairs(lost_skills) do
        room:doBroadcastNotify("LoseSkill", {
          player.id,
          ss.name
        })
      end
    else
      table.insert(tolose1, s)
    end
    for _, h in ipairs({Player.HistoryPhase, Player.HistoryTurn, Player.HistoryRound, Player.HistoryGame}) do
      target:setSkillUseHistory(s, player:usedSkillTimes(s, h), h)
    end
  end
  local tolose2 = {}
  for _, s in ipairs(Fk.generals[general2]:getSkillNameList()) do
    if target:hasSkill(s, true, true) then
      local lost_skills = target:loseSkill(s)
      for _, ss in ipairs(lost_skills) do
        room:doBroadcastNotify("LoseSkill", {
          target.id,
          ss.name
        })
      end
    else
      table.insert(tolose2, s)
    end
    for _, h in ipairs({Player.HistoryPhase, Player.HistoryTurn, Player.HistoryRound, Player.HistoryGame}) do
      player:setSkillUseHistory(s, target:usedSkillTimes(s, h), h)
    end
  end
  if not g2hide then
    room:changeHero(player, general2, false, true, false, false, false)
  else
    room:changeHero(player, "anjiang", false, true, false, false, false)
    room:setPlayerMark(player, "__heg_deputy", general2)
    for _, sname in ipairs(general22:getSkillNameList()) do
      if target:hasSkill(sname, true, true) or target:isFakeSkill(sname) then
        target:loseFakeSkill(sname)
        local s = Fk.skills[sname]
        if not s:hasTag(Skill.MainPlace) then
          if s:hasTag(Skill.Compulsory) then
            player:addFakeSkill("reveal_skill&")
          end
          player:addFakeSkill(s)
        end
      end
    end
    local ret = true
    if target.general == "anjiang" then
      local other = Fk.generals["__heg_general"] or Fk.generals["blank_shibing"]
      for _, sname in ipairs(other:getSkillNameList(true)) do
        local s = Fk.skills[sname]
        if s:hasTag(Skill.Compulsory) and not s:hasTag(Skill.DeputyPlace) and target:isFakeSkill(s) then
          ret = false
          break
        end
      end
    end
    if ret then
      target:loseFakeSkill("reveal_skill&")
    end
  end
  if not g1hide then
    room:changeHero(target, general1, false, true, false, false, false)
  else
    room:changeHero(target, "anjiang", false, true, false, false, false)
    room:setPlayerMark(target, "__heg_deputy", general1)
    for _, sname in ipairs(general11:getSkillNameList()) do
      if player:hasSkill(sname, true, true) or player:isFakeSkill(sname) then
        player:loseFakeSkill(sname)
        local s = Fk.skills[sname]
        if not s:hasTag(Skill.MainPlace) then
          if s:hasTag(Skill.Compulsory) then
            target:addFakeSkill("reveal_skill&")
          end
          target:addFakeSkill(s)
        end
      end
    end
    local ret = true
    if player.general == "anjiang" then
      local other = Fk.generals["__heg_general"] or Fk.generals["blank_shibing"]
      for _, sname in ipairs(other:getSkillNameList(true)) do
        local s = Fk.skills[sname]
        if s:hasTag(Skill.Compulsory) and not s:hasTag(Skill.DeputyPlace) and player:isFakeSkill(s) then
          ret = false
          break
        end
      end
    end
    if ret then
      player:loseFakeSkill("reveal_skill&")
    end
  end
  HegUtil.judegHegMark(player)
  HegUtil.judegHegMark(target)
  if HegUtil.getGeneralsRevealedNum(player) == 0 then
    room:changeKingdom(player, "unknown")
  end
  if HegUtil.getGeneralsRevealedNum(target) == 0 then
    room:changeKingdom(target, "unknown")
  end

  room:doSuperLightBox("packages/hegemony/qml/swapDeputy.qml",{
    generalLeft = player.deputyGeneral,
    generalRight = target.deputyGeneral,
  })

  room:sendLog{
    type = "#heg_swap_deputy",
    from = player.id,
    to = {target.id},
    toast = true,
  }

  local new_deputy1 = Fk.generals[target.deputyGeneral]
  local new_deputy2 = Fk.generals[player.deputyGeneral]
  if #tolose1 > 0 then
    room:handleAddLoseSkills(target, "-"..table.concat(tolose1, "|-"), nil, false)
  end
  if #tolose2 > 0 then
    room:handleAddLoseSkills(player, "-"..table.concat(tolose2, "|-"), nil, false)
  end

  local new_pile1 = {} ---@type string[]
  local new_pile2 = {} ---@type string[]

  for _, s in pairs(new_deputy1:getSkillNameList()) do
    local skill = Fk.skill_skels[s]
    if skill.derived_piles and #skill.derived_piles > 0 then
      for _, p in ipairs(skill.derived_piles) do
        table.insert(new_pile1, p)
      end
    end
  end

  for _, s in pairs(new_deputy2:getSkillNameList()) do
    local skill = Fk.skill_skels[s]
    if skill.derived_piles and #skill.derived_piles > 0 then
      for _, p in ipairs(skill.derived_piles) do
        table.insert(new_pile2, p)
      end
    end
  end

  if #new_pile1 > 0 then
    for _, s in ipairs(pile1) do
      if #s1 > 0 then
        target:addToPile(s, s1, true)
      end
    end
  end

  if #new_pile2 > 0 then
    for _, s in ipairs(pile2) do
      if #s2 > 0 then
        player:addToPile(s, s2, true)
      end
    end
  end

  for _, s in ipairs(general11:getSkillNameList()) do
    room.logic:trigger(fk.EventLoseSkill, player, {skill = Fk.skills[s], who = player})
    Fk.skills[s]:getSkeleton():onLose(player, false)
  end
  for _, s in ipairs(general22:getSkillNameList()) do
    room.logic:trigger(fk.EventLoseSkill, target, {skill = Fk.skills[s], who = target})
    Fk.skills[s]:getSkeleton():onLose(target, false)
  end

  return true
end

-- 注册各种事件用
dofile 'packages/hegemony/utilevent/init.lua'

-- 用于选武将牌的 interaction type ，和UI.ComboBox差不多，照着用就行
-- 必输参数：可选牌名choices；可输参数：全部牌名all_choices
-- For 役鬼
function HegUtil.GeneralCardNameBox(spec)
  local choices = type(spec.choices) == "table" and spec.choices or Util.DummyTable
  local all_choices = type(spec.all_choices) == "table" and spec.all_choices or spec.choices
  local default_choice = spec.default_choice or spec.choices[1]
  spec.type = "custom"
  spec.qml = {
    model = {
      url = "packages/hegemony/qml/SkillGeneralCardName.qml",
      prop = {
        choices = choices,
        all_choices = all_choices,
        default_choice = default_choice,
      }
    }
  }
  return spec
end

--是否控制武将牌
---@param player ServerPlayer @ 判断角色
---@param general string @ 武将名
---@return boolean
function HegUtil.isControllingGeneral(player, general)
  if HegUtil.getActualGeneral(player, false) == general then return true end
  if HegUtil.getActualGeneral(player, true) == general then return true end
  return false
end

return HegUtil
