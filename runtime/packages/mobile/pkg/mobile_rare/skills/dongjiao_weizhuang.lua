local weizhuang = fk.CreateSkill {
  name = "mobile_dongjiao__weizhuang",
  max_branches_use_time = {
    ["mobile_dongjiao__weizhuang_basic"] = {
      [Player.HistoryTurn] = 1,
    },
    ["mobile_dongjiao__weizhuang_trick"] = {
      [Player.HistoryTurn] = 1,
    },
    ["mobile_dongjiao__weizhuang_equip"] = {
      [Player.HistoryTurn] = 1,
    },
  }
}

---@type mobileUtil
local mobileUtil = require "packages.mobile.mobile_util"

Fk:loadTranslationTable{
  ["mobile_dongjiao__weizhuang"] = "褽装",
  [":mobile_dongjiao__weizhuang"] = "每回合每项限一次，若你的<a href='#CardDisplayedDesc'>明置牌</a>包含类别数不小于：" ..
  "1，你使用基本牌的数值+1；2，当你使用锦囊牌指定第一个目标后，可以获得目标中的一名其他角色的一张牌；3，当你使用装备牌结算结束后，" ..
  "你可以令一名有<a href='#CardDisplayedDesc'>明置牌</a>的角色摸两张牌。",

  ["#mobile_dongjiao__weizhuang-choose"] = "褽装：你可以获得目标中的一名其他角色的一张牌",
  ["#mobile_dongjiao__weizhuang-draw"] = "褽装：你可以令一名有明置牌的角色摸两张牌",
  ["@[cardtypes]mobile_dongjiao__weizhuang_tip-noclear"] = "褽装",

  ["$mobile_dongjiao__weizhuang1"] = "固为妾之所得，何来赏赐之说？",
  ["$mobile_dongjiao__weizhuang2"] = "妾身受屈良久，夫君以何为谢？",
  ["$mobile_dongjiao__weizhuang3"] = "此婢不尊主母，该当何罪？",
  ["$mobile_dongjiao__weizhuang4"] = "此衣妃者所服，贱婢岂敢逾制。",
  ["$mobile_dongjiao__weizhuang5"] = "沉鱼落雁难参比，质本天然第一流。",
  ["$mobile_dongjiao__weizhuang6"] = "貌美非吾本意，奈何难拒天恩。",
}

---@param player ServerPlayer
---@return integer
local getCardTypesDisplayed = function(player)
  local types = {}
  for _, id in ipairs(player:getCardIds("he")) do
    local card = Fk:getCardById(id)
    if mobileUtil.cardIsVisible(player.room, card) then
      table.insertIfNeed(types, card.type)
    end

    if #types > 2 then
      break
    end
  end

  return #types
end

weizhuang:addEffect(fk.DamageCaused, {
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card and
      data.card.type == Card.TypeBasic and
      data.by_user and
      player:hasSkill(weizhuang.name) and
      weizhuang:withinBranchTimesLimit(player, "mobile_dongjiao__weizhuang_basic") and
      getCardTypesDisplayed(player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { history_branch = "mobile_dongjiao__weizhuang_basic" })
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
})

weizhuang:addEffect(fk.PreHpRecover, {
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    if
      not (
        data.card and
        data.card.type == Card.TypeBasic and
        player:hasSkill(weizhuang.name) and
        weizhuang:withinBranchTimesLimit(player, "mobile_dongjiao__weizhuang_basic") and
        getCardTypesDisplayed(player) > 0
      )
    then
      return false
    end

    local effect = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    return effect and effect.data.from == player
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { history_branch = "mobile_dongjiao__weizhuang_basic" })
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.num = data.num + 1
  end,
})

weizhuang:addEffect(fk.CardUsing, {
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.trueName == "analeptic" and
      not (data.extra_data or {}).analepticRecover and
      player:hasSkill(weizhuang.name) and
      weizhuang:withinBranchTimesLimit(player, "mobile_dongjiao__weizhuang_basic") and
      getCardTypesDisplayed(player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { history_branch = "mobile_dongjiao__weizhuang_basic" })
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.additionalDrank = (data.extra_data.additionalDrank or 0) + 1
  end,
})

weizhuang:addEffect(fk.TargetSpecified, {
  audio_index = { 3, 4 },
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.type == Card.TypeTrick and
      data.firstTarget and
      player:hasSkill(weizhuang.name) and
      weizhuang:withinBranchTimesLimit(player, "mobile_dongjiao__weizhuang_trick") and
      getCardTypesDisplayed(player) > 1 and
      table.find(data.use.tos, function(p)
        return p ~= player and not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(data.use.tos, function(p)
      return p ~= player and not p:isNude()
    end)
    if #targets == 0 then
      return false
    end

    local tos = player.room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = weizhuang.name,
        prompt = "#mobile_dongjiao__weizhuang-choose",
      }
    )

    if #tos > 0 then
      event:setCostData(self, { tos = tos, history_branch = "mobile_dongjiao__weizhuang_trick" })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]

    local id = room:askToChooseCard(
      player,
      {
        target = to,
        flag = "he",
        skill_name = weizhuang.name,
      }
    )

    room:obtainCard(player, id, false, fk.ReasonPrey, player, weizhuang.name)
  end,
})

weizhuang:addEffect(fk.CardUseFinished, {
  audio_index = { 5, 6 },
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.type == Card.TypeEquip and
      player:hasSkill(weizhuang.name) and
      weizhuang:withinBranchTimesLimit(player, "mobile_dongjiao__weizhuang_equip") and
      getCardTypesDisplayed(player) > 2 and
      table.find(player.room.alive_players, function(p) return mobileUtil.hasCardsDisplayed(player.room, p) end)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function(p) return mobileUtil.hasCardsDisplayed(player.room, p) end)
    if #targets == 0 then
      return false
    end

    local tos = player.room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = weizhuang.name,
        prompt = "#mobile_dongjiao__weizhuang-draw",
      }
    )

    if #tos > 0 then
      event:setCostData(self, { tos = tos, history_branch = "mobile_dongjiao__weizhuang_equip" })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    to:drawCards(2, weizhuang.name)
  end,
})

weizhuang:addEffect(mobileUtil.CardDisplayed, {
  can_refresh = function(self, event, target, player, data)
    return
      player:hasSkill(weizhuang.name, true) and
      table.find(data.cards, function(card)
        return not table.contains(player:getTableMark("@[cardtypes]mobile_dongjiao__weizhuang_tip-noclear"), card.type)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    table.forEach(data.cards, function(card)
      player.room:addTableMarkIfNeed(player, "@[cardtypes]mobile_dongjiao__weizhuang_tip-noclear", card.type)
    end)
  end,
})

local weizhuangRecordTypesOnRefresh = function(player)
  local types = {}
  table.forEach(player:getCardIds("he"), function(id)
    local card = Fk:getCardById(id)
    if mobileUtil.cardIsVisible(player.room, card) then
      table.insertIfNeed(types, card.type)
    end
  end)

  if #types ~= #player:getTableMark("@[cardtypes]mobile_dongjiao__weizhuang_tip-noclear") then
    player.room:setPlayerMark(player, "@[cardtypes]mobile_dongjiao__weizhuang_tip-noclear", types)
  end
end

weizhuang:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return
      player:hasSkill(weizhuang.name, true) and
      table.find(data, function(move)
        if move.to == player and move.toArea == Card.PlayerEquip then
          return true
        end

        return table.find(move.moveInfo, function(info)
          return
            move.from == player and
            table.contains({ Card.PlayerHand, Card.PlayerEquip }, info.fromArea)
        end) ~= nil
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    weizhuangRecordTypesOnRefresh(player)
  end,
})

weizhuang:addAcquireEffect(function(self, player)
  weizhuangRecordTypesOnRefresh(player)
end)

weizhuang:addLoseEffect(function(self, player, isDeath)
  if not isDeath then
    player.room:setPlayerMark(player, "@[cardtypes]mobile_dongjiao__weizhuang_tip-noclear", 0)
  end
end)

return weizhuang
