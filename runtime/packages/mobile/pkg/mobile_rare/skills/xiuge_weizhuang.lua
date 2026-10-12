local weizhuang = fk.CreateSkill {
  name = "mobile_xiuge__weizhuang",
  max_branches_use_time = {
    ["mobile_xiuge__weizhuang_slash"] = {
      [Player.HistoryTurn] = 1,
    },
    ["mobile_xiuge__weizhuang_jink"] = {
      [Player.HistoryTurn] = 1,
    },
    ["mobile_xiuge__weizhuang_peach"] = {
      [Player.HistoryTurn] = 1,
    },
    ["mobile_xiuge__weizhuang_analeptic"] = {
      [Player.HistoryTurn] = 1,
    },
  }
}

---@type mobileUtil
local mobileUtil = require "packages.mobile.mobile_util"

Fk:loadTranslationTable{
  ["mobile_xiuge__weizhuang"] = "褽装",
  [":mobile_xiuge__weizhuang"] = "每回合每项限一次，你可以弃置一张：1.武器牌，视为使用一张任意【杀】；2.防具牌，视为使用一张【闪】；" ..
  "防御坐骑牌，视为使用一张【桃】；进攻坐骑牌，视为使用一张【酒】你以此法使用的牌。无次数限制且不计入次数，" ..
  "且于结算结束后从牌堆或弃牌堆获得一张弃置牌花色的牌。若你的<a href='#CardDisplayedDesc'>明置牌</a>包含四种花色，将此技能中的弃置改为展示。",

  ["#mobile_xiuge__weizhuang-viewAs"] = "褽装：你可以转化",
  ["@[suits]mobile_xiuge__weizhuang_tip-noclear"] = "褽装",

  ["$mobile_xiuge__weizhuang1"] = "哼，尔等婢妾，岂配与我相较。",
  ["$mobile_xiuge__weizhuang2"] = "纵我舍得，夫君可否舍得？",
  ["$mobile_xiuge__weizhuang3"] = "面若春桃，亦需华服来饰。",
  ["$mobile_xiuge__weizhuang4"] = "景好使人悦，该当小酌一杯。",
  ["$mobile_xiuge__weizhuang5"] = "夫君所选，自是雍容非凡。",
  ["$mobile_xiuge__weizhuang6"] = "妾身之美，可入夫君眸中？",
}

---@param player Player
---@return integer
local getCardSuitsDisplayed = function(player)
  local suits = {}
  for _, id in ipairs(player:getCardIds("he")) do
    local card = Fk:getCardById(id)
    if card.suit ~= Card.NoSuit and mobileUtil.cardIsVisible(Fk:currentRoom(), card) then
      table.insertIfNeed(suits, card.suit)
    end

    if #suits > 3 then
      break
    end
  end

  return #suits
end

weizhuang:addEffect("viewas", {
  prompt = "#mobile_xiuge__weizhuang-viewAs",
  pattern = "peach,slash,jink,analeptic",
  interaction = function(self, player)
    local names = { "slash" }
    table.insertTable(names, table.filter(Fk:getAllCardNames("b"), function(name) return name:endsWith("__slash") end))
    table.insertTable(names, { "jink", "peach", "analeptic" })
    local allNames = table.simpleClone(names)
    if not weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_slash") then
      names = table.filter(names, function(name) return not name:endsWith("slash") end)
    end
    if not weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_jink") then
      table.removeOne(names, "jink")
    end
    if not weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_peach") then
      table.removeOne(names, "peach")
    end
    if not weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_analeptic") then
      table.removeOne(names, "analeptic")
    end

    if #names == 0 then
      return
    end

    names = player:getViewAsCardNames(weizhuang.name, names)
    if #names == 0 then
      return
    end

    return UI.CardNameBox { choices = names, all_choices = allNames }
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = function (self, player, to_select, selected)
    local name = self.interaction.data
    if
      not (
        #selected < 1 and
        (getCardSuitsDisplayed(player) > 3 or not player:prohibitDiscard(to_select)) and
        type(name) == "string"
      )
    then
      return false
    end

    local subType = Fk:getCardById(to_select).sub_type
    return
      (
        name:endsWith("slash") and
        subType == Card.SubtypeWeapon and
        weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_slash")
      ) or
      (
        name == "jink" and
        subType == Card.SubtypeArmor and
        weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_jink")
      ) or
      (
        name == "peach" and
        subType == Card.SubtypeDefensiveRide and
        weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_peach")
      ) or
      (
        name == "analeptic" and
        subType == Card.SubtypeOffensiveRide and
        weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_analeptic")
      )
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or self.interaction.data == nil then
      return
    end

    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = weizhuang.name
    card:addFakeSubcards(cards)
    return card
  end,
  before_use = function (self, player, use)
    ---@type string
    local skillName = weizhuang.name
    local room = player.room
    player:addSkillBranchUseHistory(skillName, skillName .. "_" .. use.card.trueName, 1)
    if getCardSuitsDisplayed(player) > 3 then
      player:showCards(use.card.fake_subcards)
    else
      room:throwCard(use.card.fake_subcards, skillName, player, player)
    end

    use.extraUse = true

    local suit = Fk:getCardById(use.card.fake_subcards[1]):getSuitString()
    if suit ~= "nosuit" then
      use.extra_data = use.extra_data or {}
      use.extra_data.xiugeWeizhuangMapper = { [player] = suit }
    end
  end,
  enabled_at_play = function(self, player)
    local names = { "slash", "jink", "peach", "analeptic" }
    if not weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_slash") then
      table.removeOne(names, "slash")
    end
    if not weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_jink") then
      table.removeOne(names, "jink")
    end
    if not weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_peach") then
      table.removeOne(names, "peach")
    end
    if not weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_analeptic") then
      table.removeOne(names, "analeptic")
    end

    if #names == 0 then
      return
    end

    return
      not player:isNude() and
      #player:getViewAsCardNames(weizhuang.name, names) > 0
  end,
  enabled_at_response = function(self, player, response)
    local names = { "slash", "jink", "peach", "analeptic" }
    if not weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_slash") then
      table.removeOne(names, "slash")
    end
    if not weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_jink") then
      table.removeOne(names, "jink")
    end
    if not weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_peach") then
      table.removeOne(names, "peach")
    end
    if not weizhuang:withinBranchTimesLimit(player, "mobile_xiuge__weizhuang_analeptic") then
      table.removeOne(names, "analeptic")
    end

    if #names == 0 then
      return
    end

    return
      not response and
      not player:isNude() and
      #player:getViewAsCardNames(weizhuang.name, names) > 0
  end,
})

weizhuang:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return ((data.extra_data or {}).xiugeWeizhuangMapper or {})[player] and player:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suit = data.extra_data.xiugeWeizhuangMapper[player]
    local cards = room:getCardsFromPileByRule(".|.|" .. suit)
    if #cards == 0 then
      cards = room:getCardsFromPileByRule(".|.|" .. suit, 1, "discardPile")
    end

    if #cards > 0 then
      room:obtainCard(player, cards, true, fk.ReasonPrey, player, weizhuang.name)
    end
  end,
})

weizhuang:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, weizhuang.name)
  end
})

weizhuang:addEffect(mobileUtil.CardDisplayed, {
  can_refresh = function(self, event, target, player, data)
    return
      player:hasSkill(weizhuang.name, true) and
      table.find(data.cards, function(card)
        return
          card.suit ~= Card.NoSuit and
          not table.contains(player:getTableMark("@[suits]mobile_xiuge__weizhuang_tip-noclear"), card.suit)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    table.forEach(data.cards, function(card)
      if card.suit ~= Card.NoSuit then
        player.room:addTableMarkIfNeed(player, "@[suits]mobile_xiuge__weizhuang_tip-noclear", card.suit)
      end
    end)
  end,
})

local weizhuangRecordSuitsOnRefresh = function(player)
  local suits = {}
  table.forEach(player:getCardIds("he"), function(id)
    local card = Fk:getCardById(id)
    if card.suit ~= Card.NoSuit and mobileUtil.cardIsVisible(player.room, card) then
      table.insertIfNeed(suits, card.suit)
    end
  end)

  if #suits ~= #player:getTableMark("@[suits]mobile_xiuge__weizhuang_tip-noclear") then
    player.room:setPlayerMark(player, "@[suits]mobile_xiuge__weizhuang_tip-noclear", suits)
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
    weizhuangRecordSuitsOnRefresh(player)
  end,
})

weizhuang:addAcquireEffect(function(self, player)
  weizhuangRecordSuitsOnRefresh(player)
end)

weizhuang:addLoseEffect(function(self, player, isDeath)
  if not isDeath then
    player.room:setPlayerMark(player, "@[suits]mobile_xiuge__weizhuang_tip-noclear", 0)
  end
end)

return weizhuang
