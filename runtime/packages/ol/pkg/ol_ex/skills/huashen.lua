
local huashen = fk.CreateSkill {
  name = "ol_ex__huashen",
}

Fk:loadTranslationTable{
  ["ol_ex__huashen"] = "化身",
  [":ol_ex__huashen"] = "游戏开始时，你随机获得三张武将牌作为“化身”牌，然后你选择其中一张“化身”牌的一个技能（主公技/限定技/觉醒技/转换技/势力技除外），"..
  "你视为拥有此技能，且性别和势力视为与此“化身”牌相同。<br>回合开始或结束时，你可以选择一项：1.重新进行一次“化身”；2.移去至多两张不为亮出的“化身”牌，"..
  "然后获得等量的新“化身”牌。",

  ["@[private]&ol_ex__huashen"] = "化身",
  ["@ol_ex__huashen_skill"] = "化身",
  ["ol_ex__huashen_re"] = "进行一次“化身”",
  ["ol_ex__huashen_recast"] = "移去至多两张“化身”，获得等量新“化身”",
  ["#ol_ex__huashen-recast"] = "移去至多两张“化身”，获得等量新“化身”",
  ["#ol_ex__huashen-skill"] = "化身：选择一个武将，再选择一个要获得的技能",

  ["$ol_ex__huashen1"] = "容貌发肤，不过浮尘。",
  ["$ol_ex__huashen2"] = "皮囊万千，吾皆可化。",
}

local U = require("packages.utility.utility")

local huashen_blacklist = {
  -- imba
  "zuoci", "ol_ex__zuoci", "qyt__dianwei", "starsp__xiahoudun", "mou__wolong",
  -- haven't available skill
  "js__huangzhong", "liyixiejing", "olz__wangyun", "yanyan", "duanjiong", "wolongfengchu", "wuanguo", "os__wangling", "tymou__jiaxu",
}

local function Gethuashen(player, n)
  local room = player.room
  local generals = table.filter(room.general_pile, function (name)
    return not table.contains(huashen_blacklist, name)
  end)
  local mark = U.getPrivateMark(player, "&ol_ex__huashen")
  for _ = 1, n do
    if #generals == 0 then break end
    local g = table.remove(generals, math.random(#generals))
    table.insert(mark, g)
    table.removeOne(room.general_pile, g)
  end
  U.setPrivateMark(player, "&ol_ex__huashen", mark)
end

local function Dohuashen(player)
  local room = player.room
  local generals = U.getPrivateMark(player, "&ol_ex__huashen")
  if #generals == 0 then return end
  local default = {}
  local skillList = {}
  for _, g in ipairs(generals) do
    local general = Fk.generals[g]
    local skills = {}
    local tags = {Skill.Lord, Skill.Limited, Skill.Wake, Skill.Switch, Skill.AttachedKingdom}
    for _, skillName in ipairs(general:getSkillNameList()) do
      local s = Fk.skills[skillName]
      if table.every(tags, function (tag)
        return not s:hasTag(tag)
      end) then
        table.insert(skills, skillName)
        if #default == 0 then
          default = {g, skillName}
        end
      end
    end
    table.insert(skillList, skills)
  end
  local result = U.askToChooseGeneralSkills(player, {
    skill_name = huashen.name,
    generals = generals,
    skills = skillList,
    min_num = 1, max_num = 1,
    prompt = "#ol_ex__huashen-skill"
  })
  local skill = result[1]
  if not skill then return end
  local generalName = "diaochan"
  for i, s in ipairs(skillList) do
    if table.contains(s, skill) then
      generalName = generals[i]
      break
    end
  end
  local general = Fk.generals[generalName]
  room:setPlayerMark(player, "ol_ex__huashen_general", generalName)
  if player:getMark("HuashenOrignalProperty") == 0 then
    room:setPlayerMark(player, "HuashenOrignalProperty", {player.gender, player.kingdom})
  end
  player.gender = general.gender
  room:broadcastProperty(player, "gender")
  player.kingdom = general.kingdom
  room:askToChooseKingdom({player})
  room:broadcastProperty(player, "kingdom")
  local old_mark = player:getMark("@ol_ex__huashen_skill")
  if old_mark ~= 0 then
    room:handleAddLoseSkills(player, "-"..old_mark[2])
  end
  room:setPlayerMark(player, "@ol_ex__huashen_skill", {generalName, skill})
  room:handleAddLoseSkills(player, skill)
  room:delay(500)
end

--- 更换化身
local function Recasthuashen(player)
  local room = player.room
  local generals = U.getPrivateMark(player, "&ol_ex__huashen")
  if #generals < 2 then return end
  local disable_generals = {}
  local current_general = player:getMark("ol_ex__huashen_general") -- 禁止替换当前在使用的化身
  if type(current_general) == "string" then
    table.insert(disable_generals, current_general)
  end

  local removed, choice = U.askToChooseGeneralsAndChoice(player, {
    generals = generals, disable_generals = disable_generals,
    choices = {"OK"},
    cancel_options = {"Cancel"},
    min_num = 1, max_num = 2,
    prompt = "#ol_ex__huashen-recast",
    skill_name = huashen.name,
  })

  if choice ~= "OK" then return end
  for _, g in ipairs(removed) do
    table.removeOne(generals, g)
  end
  U.setPrivateMark(player, "&ol_ex__huashen", generals)
  Gethuashen(player, #removed)
  room:returnToGeneralPile(removed)
end

huashen:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(huashen.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    Gethuashen(player, 3)
    Dohuashen(player)
  end,
})

local spec = {
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = {"ol_ex__huashen_re", "ol_ex__huashen_recast", "Cancel"},
      skill_name = huashen.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event:getCostData(self).choice == "ol_ex__huashen_re" then
      Dohuashen(player)
    else
      Recasthuashen(player)
    end
  end,
}

huashen:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(huashen.name) and target == player and #U.getPrivateMark(player, "&ol_ex__huashen") > 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

huashen:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(huashen.name) and target == player and #U.getPrivateMark(player, "&ol_ex__huashen") > 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

huashen:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    return player == target and data.skill == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@[private]&ol_ex__huashen", 0)
    local pro = player:getMark("HuashenOrignalProperty")
    if pro ~= 0 then
      player.gender = pro[1]
      room:broadcastProperty(player, "gender")
      player.kingdom = pro[2]
      room:broadcastProperty(player, "kingdom")
      room:setPlayerMark(player, "HuashenOrignalProperty", 0)
    end
  end,
})

return huashen
