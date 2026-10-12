local quanyu = fk.CreateSkill {
  name = "quanyu",
  tags = { Skill.Compulsory },
  add_skills = { "#quanyu_bixie" },
}

local U = require "packages.utility.utility"

Fk:loadTranslationTable{
  ["quanyu"] = "权御",
  [":quanyu"] = "锁定技，每轮开始时，你令所有角色同时选择一项“权御”效果（每人每项限一次），然后你摸X张牌（X为本次所选“权御”效果与你相同的角色数，" ..
  "且至多为3）：<br>"..
  "白虹，伤害+1；<br>青冥，目标+1；<br>辟邪，无视防具；<br>紫电，不可响应；<br>百里，额外结算一次；<br>流星，不计次数。<br>" ..
  "当你使用【杀】指定唯一目标时，执行你本轮选择的“权御”效果。",

  ["quanyu_baihong"] = "伤害+1",
  ["quanyu_qingming"] = "目标+1",
  ["quanyu_bixie"] = "无视防具",
  ["quanyu_zidian"] = "不可响应",
  ["quanyu_baili"] = "额外结算",
  ["quanyu_liuxing"] = "不计次数",

  ["quanyu_baihong_name"] = "白虹",
  ["quanyu_qingming_name"] = "青冥",
  ["quanyu_bixie_name"] = "辟邪",
  ["quanyu_zidian_name"] = "紫电",
  ["quanyu_baili_name"] = "百里",
  ["quanyu_liuxing_name"] = "流星",

  ["@[private]quanyu_effect-round-noclear"] = "权御",
  ["#quanyu-choice"] = "权御：请选择一项“权御”效果",
  ["#quanyu-choose"] = "请为%arg额外选择一个目标",

  ["$quanyu1"] = "百川奔流入海，却尽入朕之彀中。",
  ["$quanyu2"] = "恩威予取，功过皆在朕心。",
}

local quanyuChoices = { "quanyu_baihong", "quanyu_qingming", "quanyu_bixie", "quanyu_zidian", "quanyu_baili", "quanyu_liuxing" }

quanyu:addEffect(fk.RoundStart, {
  can_trigger = function (self, event, target, player, data)
    return
      player:hasSkill(quanyu.name) and
      table.find(player.room.alive_players, function(p)
        return #p:getTableMark("quanyu_chosen-noclear") < #quanyuChoices and p:getMark("@[private]quanyu_effect-round-noclear") == 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = quanyu.name
    local room = player.room
    local players = table.filter(player.room.alive_players, function(p)
      return #p:getTableMark("quanyu_chosen-noclear") < #quanyuChoices
    end)

    local choicesMap = {}
    for _, p in ipairs(players) do
      local availableChoices = table.filter(quanyuChoices, function(choice)
        return not table.contains(p:getTableMark("quanyu_chosen-noclear"), choice .. "_name")
      end)
      table.insert(choicesMap, availableChoices)
    end

    room:doIndicate(player, players)

    local results = room:askToJointChoice(player, {
      players = players, choices = choicesMap, prompt = "#quanyu-choice", skill_name = skillName, all_choices = quanyuChoices,
    })

    local yourChoice = results[player]
    local drawNum = 0
    for _, p in ipairs(players) do
      local result = results[p]
      room:addTableMark(p, "quanyu_chosen-noclear", result .. "_name")
      U.setPrivateMark(p, "quanyu_effect-round-noclear", result .. "_name", { p.id, player.id })

      if result == yourChoice and drawNum < 3 then
        drawNum = drawNum + 1
      end
    end

    player:drawCards(drawNum, skillName)
  end,
})

---@param player ServerPlayer
---@param effect string
---@param data AimData
local doQuanyuEffect = function(player, effect, data)
  local room = player.room
  if effect == "quanyu_baihong_name" then
    data.use.additionalDamage = (data.use.additionalDamage or 0) + 1
  elseif effect == "quanyu_qingming_name" then
    if not player:isAlive() then
      return
    end

    local targets = data:getExtraTargets({ bypass_times = true, bypass_distances = true })
    if #targets > 0 then
      local tos = room:askToChoosePlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = quanyu.name,
          prompt = "#quanyu-choose:::" .. data.card:toLogString(),
          cancelable = false,
        }
      )

      data:addTarget(tos[1])
    end
  elseif effect == "quanyu_zidian_name" then
    data.use.disresponsiveList = room:getAllPlayers(false)
  elseif effect == "quanyu_baili_name" then
    data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
  elseif effect == "quanyu_liuxing_name" and not data.use.extraUse then
    data.use.extraUse = true
    player:addCardUseHistory("slash", -1)
  end

  data.extra_data = data.extra_data or {}
  data.extra_data.quanyuEffect = data.extra_data.quanyuEffect or {}
  table.insertIfNeed(data.extra_data.quanyuEffect, effect)
end

--线上的权御会早于魔孙权自己的同时机的其他技能发动，不会自选，但是不会突破座次优先级
quanyu:addEffect(fk.TargetSpecifying, {
  can_trigger = function(self, event, target, player, data)
    if
      not (
        target == player and
        data.card.trueName == "slash" and
        player:hasSkill(quanyu.name) and
        data:isOnlyTarget(data.to)
      )
    then
      return false
    end

    local quanyuEffect = U.getPrivateMark(player, "quanyu_effect-round-noclear", false)
    return
      quanyuEffect ~= 0 and
      not table.contains((data.extra_data or {}).quanyuEffect or {}, quanyuEffect) and
      not (
        quanyuEffect == "quanyu_qingming_name" and
        #data:getExtraTargets({ bypass_times = true, bypass_distances = true }) == 0
      )
  end,
  on_use = function(self, event, target, player, data)
    local quanyuEffect = U.getPrivateMark(player, "quanyu_effect-round-noclear", false)
    U.showPrivateMark(player, "quanyu_effect-round-noclear")
    doQuanyuEffect(player, quanyuEffect, data)
  end,
})

quanyu:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.trueName == "slash" and player:hasSkill(quanyu.name) and
      U.getPrivateMark(player, "quanyu_effect-round-noclear", false) == "quanyu_liuxing_name"
  end,
})

return quanyu
