local danggu = fk.CreateSkill {
  name = "danggu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["danggu"] = "党锢",
  [":danggu"] = "锁定技，游戏开始时，你获得十张不同的“常侍牌”，然后你进行一次“结党”（随机展示一张“常侍”牌，然后随机展示四张“常侍”牌，"..
  "你从中选择一张与最初展示的“常侍”牌互相认可的与其组成双将）；当你因休整而返回游戏后，你进行一次“结党”并摸一张牌。",

  ["@&changshiCards"] = "常侍",
  ["jiedang"] = "结党",
  ["$JieDang"] = "结党",

  [":changshi__zhangrang-specificSkillDesc"] = "滔乱：（滔乱）",
  [":changshi__zhaozhong-specificSkillDesc"] = "鸱咽：（破军）",
  [":changshi__sunzhang-specificSkillDesc"] = "自谋：（勤政）",
  [":changshi__bilan-specificSkillDesc"] = "庀材：（慧识）",
  [":changshi__xiayun-specificSkillDesc"] = "谣诼：（义争）",
  [":changshi__hankui-specificSkillDesc"] = "宵赂：（巧思）",
  [":changshi__lisong-specificSkillDesc"] = "窥机：（魄袭）",
  [":changshi__duangui-specificSkillDesc"] = "叱吓：（烈弓）",
  [":changshi__guosheng-specificSkillDesc"] = "逆取：（评才）",
  [":changshi__gaowang-specificSkillDesc"] = "妙语：（龙魂）",
}

local tenChangShiMapper = {
  ["changshi__zhangrang"] = "changshi__taoluan",
  ["changshi__zhaozhong"] = "changshi__chiyan",
  ["changshi__sunzhang"] = "changshi__zimou",
  ["changshi__bilan"] = "changshi__picai",
  ["changshi__xiayun"] = "changshi__yaozhuo",
  ["changshi__hankui"] = "changshi__xiaolu",
  ["changshi__lisong"] = "changshi__kuiji",
  ["changshi__duangui"] = "changshi__chihe",
  ["changshi__guosheng"] = "changshi__niqu",
  ["changshi__gaowang"] = "changshi__miaoyu",
}

---@param room Room
---@param player ServerPlayer
---@param generals string[]
local doJieDang = function(room, player, generals)
  if type(generals) ~= "table" or #generals < 2 then
    return
  end

  generals = table.simpleClone(generals)

  local mainGeneral
  local deputyGeneral
  if #generals < 3 then
    mainGeneral = generals[1]
    deputyGeneral = generals[2]
  else
    mainGeneral = room:tableRandomPick(generals)
    table.removeOne(generals, mainGeneral)
    local deputyGenerals = room:tableRandomPick(generals, 4)

    local haters = {
      ["changshi__bilan"] = 'changshi__hankui',
      ["changshi__hankui"] = 'changshi__bilan',
      ["changshi__duangui"] = 'changshi__guosheng',
      ["changshi__guosheng"] = 'changshi__duangui',
    }

    local disabledGeneral = ""
    local hater = haters[mainGeneral]
    if hater and table.contains(deputyGenerals, hater) then
      disabledGeneral = hater
    elseif math.random() < 0.1 then
      disabledGeneral = room:tableRandomPick(deputyGenerals)
    end

    local result = room:askToCustomDialog( player, {
      skill_name = "jiedang",
      component = {
        url = "packages/mobile/qml/JieDangBox.qml",
        prop = {
          mainGeneral = mainGeneral,
          deputyGenerals = deputyGenerals,
          disabledGeneral = disabledGeneral
        },
      }
    })

    if result ~= "" then
      deputyGeneral = result.general
    else
      deputyGeneral = room:tableRandomPick(deputyGenerals)
    end
  end

  player.tag['jiedang_before_generals'] = { player.general, player.deputyGeneral }
  table.removeOne(generals, mainGeneral)
  table.removeOne(generals, deputyGeneral)
  player.tag['changshi_cards'] = generals
  room:setPlayerMark(player, "@&changshiCards", #generals > 0 and generals or 0)

  room:changeHero(player, mainGeneral, true, false, false, false)
  room:changeHero(player, deputyGeneral, true, true, false, false)
  room:handleAddLoseSkills(player, tenChangShiMapper[mainGeneral] .. "|" .. tenChangShiMapper[deputyGeneral], nil, false)
end

danggu:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(danggu.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tenChangShis = {}
    for changShi, _ in pairs(tenChangShiMapper) do
      table.insert(tenChangShis, changShi)
    end
    room:setPlayerMark(player, "@&changshiCards", tenChangShis)

    doJieDang(room, player, tenChangShis)
  end,
})
danggu:addEffect(fk.AfterPlayerRevived, {
  can_trigger = function (self, event, target, player, data)
    return target == player and data.reason == "rest" and
      type(player.tag["changshi_cards"]) == "table" and
      #player.tag["changshi_cards"] > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    doJieDang(room, player, player.tag['changshi_cards'])
    player:drawCards(1, danggu.name)
  end,
})
danggu:addEffect(fk.AfterPropertyChange, {
  can_refresh = function (self, event, target, player, data)
    if not player.tag['jiedang_before_generals'] then
      return false
    end
    return target == player and data.results and (data.results.generalChange or data.results.deputyChange)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.results.generalChange then
      local beforeGeneral = data.results.generalChange[1]
      if tenChangShiMapper[beforeGeneral] then
        room:handleAddLoseSkills(player, "-" .. tenChangShiMapper[beforeGeneral], nil, false)
      end

      if not tenChangShiMapper[player.general] then
        player.tag['jiedang_before_generals'][1] = player.general
      end
    end

    if data.results.deputyChange then
      local beforeGeneral = data.results.deputyChange[1]
      if tenChangShiMapper[beforeGeneral] then
        room:handleAddLoseSkills(player, "-" .. tenChangShiMapper[beforeGeneral], nil, false)
      end

      if not tenChangShiMapper[player.deputyGeneral] then
        player.tag['jiedang_before_generals'][2] = player.deputyGeneral
      end
    end
  end,
})
danggu:addEffect(fk.BeforeGameOverJudge, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player.tag['jiedang_before_generals']
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local generals = player.tag['jiedang_before_generals']

    local hasDangGu = player:hasSkill(self, true, true)
    local hasMoWang = player:hasSkill("mowang", true, true)

    if #generals > 1 then
      room:changeHero(player, generals[2], false, true, false, false)
    end
    if generals[1] ~= "" then
      room:changeHero(player, generals[1], false, false, false, false)
    end
    local toObtain = {}
    if hasDangGu and not player:hasSkill(danggu.name) then
      table.insert(toObtain, danggu.name)
    end
    if hasMoWang and not player:hasSkill("mowang") then
      table.insert(toObtain, "mowang")
    end

    if #toObtain > 0 then
      room:handleAddLoseSkills(player, table.concat(toObtain, "|"), nil, false)
    end
  end,
})
danggu:addEffect(fk.GameFinished, {
  can_refresh = function (self, event, target, player, data)
    return player.tag['jiedang_before_generals']
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local generals = player.tag['jiedang_before_generals']
    if #generals > 1 then
      room:setPlayerProperty(player, "deputyGeneral", generals[2])
    end
    if generals[1] ~= "" then
      room:setPlayerProperty(player, "general", generals[1])
    end
  end,
})

return danggu
