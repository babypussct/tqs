
local xiongnve = fk.CreateSkill {
  name = "nos_heg__xiongnve",
}

Fk:loadTranslationTable {
  ["nos_heg__xiongnve"] = "凶虐",
  [":nos_heg__xiongnve"] = "出牌阶段开始时，你可以移去一张“戮”，令你本回合对此“戮”势力角色获得下列效果中的一项：" ..
  "1.对其造成伤害+1；2.对其造成伤害时，你获得其一张牌；3.对其使用牌无次数限制。" ..
  "出牌阶段结束时，你可以移去两张“戮”，然后直到你下回合开始，其他角色对你造成的伤害-1。",

  ["#nos_heg__xiongnve-choice"] = "凶虐：移去一张“戮”，获得一项效果",
  ["nos_heg__xiongnve_choice1"] = "增加伤害",
  ["nos_heg__xiongnve_choice2"] = "造成伤害时拿牌",
  ["nos_heg__xiongnve_choice3"] = "用牌无次数限制",
  ["#nos_heg__xiongnve-defence"] = "凶虐：移去两张“戮”，直到下回合开始，其他角色对你造成的伤害-1",

  ["@nos_heg__xiongnve_choice-phase"] = "凶虐",
  ["@nos_heg__xiongnve_kingdom-phase"] = "凶虐",
  ["@nos_heg__xiongnve_choice"] = "凶虐",
  ["nos_heg__xiongnve_defence"] = "减少伤害",
  ["nos_heg__xiongnve_effect1"] = "增加伤害",
  ["nos_heg__xiongnve_effect2"] = "造伤拿牌",
  ["nos_heg__xiongnve_effect3"] = "无限用牌",

  ["$nos_heg__xiongnve1"] = "当今天子乃我所立，他敢怎样？",
  ["$nos_heg__xiongnve2"] = "我兄弟三人同掌禁军，有何所惧？",
}

local U = require "packages.utility.utility"
local H = require "packages.hegemony.util"

xiongnve:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiongnve.name) and player.phase == Player.Play and
      #player:getTableMark("@&massacre") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local generals, choice = U.askToChooseGeneralsAndChoice(player, {
      skill_name = xiongnve.name,
      generals = player:getMark("@&massacre"),
      choices = { "nos_heg__xiongnve_choice1", "nos_heg__xiongnve_choice2", "nos_heg__xiongnve_choice3" },
      prompt = "#nos_heg__xiongnve-choice",
      cancelable = true,
      max_num = 1,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { generals = generals, choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local general = event:getCostData(self).generals[1]
    room:returnToGeneralPile({ general })
    room:removeTableMark(player, "@&massacre", general)
    room:setPlayerMark(player, "@nos_heg__xiongnve_choice-phase",
      "nos_heg__xiongnve_effect" .. string.sub(event:getCostData(self).choice, 16, 16))
    local mark = player:getTableMark("@xiongnve-turn")
    table.insertIfNeed(mark, Fk.generals[general].kingdom)
    if Fk.generals[general].subkingdom then
      table.insertIfNeed(mark, Fk.generals[general].subkingdom)
    end
    room:setPlayerMark(player, "@nos_heg__xiongnve_kingdom-phase", mark)
  end,
})

xiongnve:addEffect(fk.EventPhaseEnd, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiongnve.name) and player.phase == Player.Play and
      #player:getTableMark("@&massacre") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local generals, choice = U.askToChooseGeneralsAndChoice(player, {
      skill_name = xiongnve.name,
      generals = player:getMark("@&massacre"),
      prompt = "#nos_heg__xiongnve-defence",
      cancelable = true,
      min_num = 2,
      max_num = 2,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { generals = generals })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).generals ---@type string[]
    room:returnToGeneralPile(cards)
    local generals = player:getTableMark("@&massacre")
    for _, g in ipairs(cards) do
      table.removeOne(generals, g)
    end
    room:setPlayerMark(player, "@&massacre", generals)
    room:setPlayerMark(player, "@nos_heg__xiongnve_choice", "nos_heg__xiongnve_defence")
  end,
})

xiongnve:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@nos_heg__xiongnve_choice", 0)
  end,
})

xiongnve:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and not data.to.dead and
      table.contains(player:getTableMark("@nos_heg__xiongnve_kingdom-phase"), H.getKingdom(data.to)) then
      local effect_name = player:getMark("@nos_heg__xiongnve_choice-phase")
      if effect_name == "nos_heg__xiongnve_effect1" then
        return true
      elseif effect_name == "nos_heg__xiongnve_effect2" then
        return #data.to:getCardIds("e") > 0 or (not data.to:isKongcheng() and data.to ~= player)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = { data.to } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local effect_name = player:getMark("@nos_heg__xiongnve_choice-phase")
    if effect_name == "nos_heg__xiongnve_effect1" then
      data:changeDamage(1)
    elseif effect_name == "nos_heg__xiongnve_effect2" then
      local card = room:askToChooseCard(player, {
        target = data.to,
        flag = data.to == player and "e" or "he",
        skill_name = xiongnve.name,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, xiongnve.name, nil, false, player)
    end
  end,
})

xiongnve:addEffect(fk.DamageCaused, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target and target ~= player and
      player:getMark("@nos_heg__xiongnve_choice") == "nos_heg__xiongnve_defence"
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
  end,
})

xiongnve:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and player:getMark("@nos_heg__xiongnve_choice-phase") == "nos_heg__xiongnve_effect3" and
      table.contains(player:getTableMark("@nos_heg__xiongnve_kingdom-phase"), H.getKingdom(to))
  end,
})

return xiongnve
