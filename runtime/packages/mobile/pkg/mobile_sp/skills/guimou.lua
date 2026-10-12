local guimou = fk.CreateSkill {
  name = "guimou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["guimou"] = "诡谋",
  [":guimou"] = "锁定技，游戏开始时你随机选择一项，或回合结束时你选择一项：直到你的下个准备阶段，1.记录使用牌最少的其他角色；" ..
  "2.记录弃置牌最少的其他角色；3.记录获得牌最少的其他角色。准备阶段，你选择被记录的一名角色，观看其手牌并可选择其中一张牌，" ..
  "弃置此牌或将此牌交给另一名其他角色。",

  ["@[private]guimou"] = "诡谋",
  ["#guimou-choose"] = "诡谋：你选择一项，你下个准备阶段令该项值最少的角色受到惩罚",
  ["guimou_use"] = "使用牌",
  ["guimou_discard"] = "弃置牌",
  ["guimou_gain"] = "获得牌",
  ["guimou_option_give"] = "给出此牌",
  ["guimou_option_discard"] = "弃置此牌",
  ["#guimou-invoke"] = "诡谋：选择其中一名角色查看其手牌，可选择其中一张给出或弃置",
  ["#guimou-give"] = "诡谋：将 %arg 交给另一名其他角色",
  ["#guimou-view"] = "当前观看的是 %dest 的手牌",

  ["$guimou1"] = "不过卒合之师，岂是将军之敌乎？",
  ["$guimou2"] = "连鸡势不俱栖，依珪计便可一一解离。",
}

local U = require "packages.utility.utility"

guimou:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guimou.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = { "guimou_use", "guimou_discard", "guimou_gain" }
    local choice = room:tableRandomPick(choices)

    for _, p in ipairs(room.alive_players) do
      p.tag["guimou_record" .. player.id] = nil
    end
    U.setPrivateMark(player, "guimou", { choice })
  end,
})

guimou:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guimou.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = { "guimou_use", "guimou_discard", "guimou_gain" }
    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = guimou.name,
        prompt = "#guimou-choose",
      }
    )

    for _, p in ipairs(room.alive_players) do
      p.tag["guimou_record" .. player.id] = nil
    end
    U.setPrivateMark(player, "guimou", { choice })
  end,
})

guimou:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(guimou.name) and
      player.phase == Player.Start and
      player:getMark("@[private]guimou") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = guimou.name
    local room = player.room
    local targets = {}
    local minValue = 999
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      local recordVal = p.tag["guimou_record" .. player.id] or 0
      if minValue >= recordVal then
        if minValue > recordVal then
          targets = {}
          minValue = recordVal
        end
        if not p:isKongcheng() then
          table.insert(targets, p)
        end
      end
    end

    if #targets > 0 then
      local to = targets[1]
      if #targets > 1 then
        to = room:askToChoosePlayers(
          player,
          {
            targets = targets,
            min_num = 1,
            max_num = 1,
            prompt = "#guimou-invoke",
            skill_name = skillName,
            cancelable = false,
          }
        )[1]
      end

      local choices = { "guimou_option_discard" }
      local canGive = table.filter(room.alive_players, function(p) return p ~= to and p ~= player end)
      if #canGive > 0 then
        table.insert(choices, 1, "guimou_option_give")
      end
      local ids, choice = room:askToChooseCardsAndChoice(player, {
        cards = to:getCardIds("h"),
        choices = choices,
        skill_name = skillName,
        prompt = "#guimou-view::" .. to.id,
        cancel_choices = {"Cancel"},
        min_num = 1,
        max_num = 1
      })

      if choice == "guimou_option_give" then
        local toGive = room:askToChoosePlayers(
          player,
          {
            targets = canGive,
            min_num = 1,
            max_num = 1,
            prompt = "#guimou-give:::" .. Fk:getCardById(ids[1]):toLogString(),
            skill_name = skillName,
            cancelable = false,
          }
        )[1]
        room:obtainCard(toGive, ids[1], false, fk.ReasonGive, player, skillName)
      elseif choice == "guimou_option_discard" then
        room:throwCard(ids, skillName, to, player)
      end
    end

    for _, p in ipairs(room.alive_players) do
      p.tag["guimou_record" .. player.id] = nil
    end
    room:setPlayerMark(player, "@[private]guimou", 0)
  end,
})

guimou:addEffect(fk.EventPhaseEnd, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:getMark("@[private]guimou") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      p.tag["guimou_record" .. player.id] = nil
    end
    room:setPlayerMark(player, "@[private]guimou", 0)
  end,
})

guimou:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target ~= player and U.getPrivateMark(player, "guimou")[1] == "guimou_use"
  end,
  on_refresh = function(self, event, target, player, data)
    target.tag["guimou_record" .. player.id] = (target.tag["guimou_record" .. player.id] or 0) + 1
  end,
})

guimou:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    local guimouMark = U.getPrivateMark(player, "guimou")[1]
    if guimouMark == "guimou_discard" then
      return table.find(data, function(info)
        return info.moveReason == fk.ReasonDiscard and info.proposer and info.proposer ~= player
      end)
    elseif guimouMark == "guimou_gain" then
      return table.find(data, function(info)
        return info.toArea == Player.Hand and info.to and info.to ~= player
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local guimouMark = U.getPrivateMark(player, "guimou")[1]
    if guimouMark == "guimou_discard" then
      table.forEach(data, function(info)
        if info.moveReason == fk.ReasonDiscard and info.proposer and info.proposer ~= player then
          info.proposer.tag["guimou_record" .. player.id] = (info.proposer.tag["guimou_record" .. player.id] or 0) + #info.moveInfo
        end
      end)
    elseif guimouMark == "guimou_gain" then
      table.forEach(data, function(info)
        if info.toArea == Player.Hand and info.to and info.to ~= player then
          info.to.tag["guimou_record" .. player.id] = (info.to.tag["guimou_record" .. player.id] or 0) + #info.moveInfo
        end
      end)
    end
  end,
})

return guimou
