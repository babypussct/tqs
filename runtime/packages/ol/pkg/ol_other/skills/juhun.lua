local juhun = fk.CreateSkill {
  name = "juhun",
}

Fk:loadTranslationTable {
  ["juhun"] = "拘魂",
  [":juhun"] = "出牌阶段开始时，将你的手牌变为扑克牌，直到此回合结束。然后你可以根据以下组合打出手牌扑克牌执行效果：<br>"..
  "对子：视为使用一张基本牌（不计次数）；<br>三条：获得相邻角色各一张牌；<br>炸弹：造成2点伤害；<br>顺子：你将一名角色随机两张牌变为扑克牌。",

  ["#juhun"] = "拘魂：打出对子、三条、炸弹、顺子",
  ["#juhun2"] = "拘魂：打出对子，视为使用一张不计次数的基本牌",
  ["#juhun3"] = "拘魂：打出三条，获得相邻角色各一张牌",
  ["#juhun4"] = "拘魂：打出炸弹，对一名角色造成2点伤害",
  ["#juhun5"] = "拘魂：打出顺子，将一名角色随机两张牌变为扑克牌",

  ["$juhun1"] = "啊？！我们打张飞？真的假的？",
  ["$juhun2"] = "不是我们害了你啊！是这加班害了你！",
  ["$juhun3"] = "哥呀！说两句得了，反正阎王爷也听不见！",
  ["$juhun4"] = "骑红马的！你可私藏黑厮！",
  ["$juhun5"] = "张翼德！你不要给我们哇哇叫！",
}

local U = require "packages.utility.utility"

juhun:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, player, selected_cards, selected_targets)
    if #selected_cards < 2 then
      return "#juhun"
    else
      if Fk:getCardById(selected_cards[1]).number ~= Fk:getCardById(selected_cards[2]).number then
        return "#juhun5"
      else
        return "#juhun"..#selected_cards
      end
    end
  end,
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(juhun.name, all_names, {}, {}, { bypass_times = true })
    if #names > 0 then
      return UI.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = ".",
  },
  card_filter = function(self, player, to_select, selected, selected_targets)
    if not Fk:getCardById(to_select).name:endsWith("__poker") then return false end
    if table.contains(player:getCardIds("h"), to_select) and #selected < 5 and
      Fk:getCardById(to_select).number > 0 and Fk:getCardById(to_select).number < 14 then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return math.abs(Fk:getCardById(selected[1]).number - Fk:getCardById(to_select).number) < 2
      else
        if Fk:getCardById(selected[1]).number == Fk:getCardById(selected[2]).number then
          return #selected < 4 and Fk:getCardById(selected[1]).number == Fk:getCardById(to_select).number
        else
          return not table.find(selected, function (id)
            return Fk:getCardById(id).number == Fk:getCardById(to_select).number
          end) and
          table.find(selected, function (id)
            return math.abs(Fk:getCardById(id).number - Fk:getCardById(to_select).number) == 1
          end)
        end
      end
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards, card, extra_data)
    if #selected == 0 then
      if #selected_cards < 4 then
        return false
      elseif #selected_cards == 4 then
        return true
      elseif #selected_cards == 5 then
        return not to_select:isKongcheng()
      end
    end
  end,
  feasible = function(self, player, selected, selected_cards, card)
    if #selected_cards > 1 and #selected_cards < 6 then
      if #selected_cards < 5 then
        return table.every(selected_cards, function (id)
          return Fk:getCardById(id).number == Fk:getCardById(selected_cards[1]).number
        end)
      else
        local nums = table.map(selected_cards, function (id)
          return Fk:getCardById(id).number
        end)
        table.sort(nums)
        return nums[5] - nums[1] == 4
      end
    end
  end,
  view_as = function(self, player, cards)
    if #cards == 2 and self.interaction.data and
      Fk:getCardById(cards[1]).number == Fk:getCardById(cards[2]).number then
      local card = Fk:cloneCard(self.interaction.data)
      card.skillName = juhun.name
      return card
    end
  end,
  on_use = function (self, room, effect, card, params)
    local player = effect.from
    room:throwCard(effect.cards, juhun.name, player, player)
    if card then
      return ViewAsSkill:onUse(room, effect, card, params)
    else
      if #effect.cards == 3 then
        if not player.dead then
          local targets = { player:getNextAlive(), player:getLastAlive() }
          room:sortByAction(targets)
          for _, p in ipairs(targets) do
            if not player.dead and not p:isNude() then
              card = room:askToChooseCard(player, {
                target = p,
                skill_name = juhun.name,
                flag = "he",
              })
              room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, juhun.name, nil, false, player)
            end
          end
        end
      elseif #effect.cards == 4 then
        local target = effect.tos[1]
        if not target.dead then
          room:damage{
            from = player,
            to = target,
            damage = 2,
            skillName = juhun.name,
          }
        end
      elseif #effect.cards == 5 then
        local target = effect.tos[1]
        if not target:isKongcheng() then
          local cards = room:tableRandomPick(target:getCardIds("h"), 2)
          for _, id in ipairs(cards) do
            local c = Fk:getCardById(id)
            if c.number > 0 and c.number < 14 and c.suit > 0 and c.suit < 5 then
              room:setCardMark(c, "juhun-inhand", { c:getSuitString(), c.number })
            end
          end
        end
      end
    end
    if player:hasSkill("dianbu") and room:addTableMarkIfNeed(player, "dianbu-turn", #effect.cards) then
      player:broadcastSkillInvoke("dianbu")
      room:notifySkillInvoked(player, "dianbu", "drawcard")
      if #effect.cards == 4 then
        room:setPlayerMark(player, "dianbu-turn", 0)
      end
      room:useVirtualCard("ex_nihilo", {}, player, player, "dianbu")
    end
  end,
  after_use = function (self, player, use)
    local room = player.room
    if player:hasSkill("dianbu") and room:addTableMarkIfNeed(player, "dianbu-turn", 2) then
      player:broadcastSkillInvoke("dianbu")
      room:notifySkillInvoked(player, "dianbu", "drawcard")
      room:useVirtualCard("ex_nihilo", {}, player, player, "dianbu")
    end
  end,
  enabled_at_response = function (self, player, response)
    return not response and player.phase == Player.Play
  end,
})

juhun:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(juhun.name) and player.phase == Player.Play
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getBanner("juhun-turn") or {}
    table.insertTableIfNeed(cards, player:getCardIds("h"))
    room:setBanner("juhun-turn", cards)
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card.number > 0 and card.number < 14 and card.suit > 0 and card.suit < 5 then
        room:setCardMark(card, "juhun-inhand", { card:getSuitString(), card.number })
      end
    end
  end,
})

juhun:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and player.room:getBanner("juhun-turn")
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(room:getBanner("juhun-turn")) do
      local card = Fk:getCardById(id)
      room:setCardMark(card, "juhun-inhand", 0)
    end
    player:filterHandcards()
  end,
})

juhun:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("juhun-inhand") ~= 0
  end,
  view_as = function(self, player, card)
    local suit, number = card:getMark("juhun-inhand")[1], card:getMark("juhun-inhand")[2]
    return Fk:cloneCard(suit..number.."__poker", U.ConvertSuit(suit, "str", "int"), number)
  end,
  card_pic_filter = function (self, card)
    if card:getMark("juhun-inhand") ~= 0 then
      return card:getMark("juhun-inhand")[1]..card:getMark("juhun-inhand")[2].."__poker"
    end
  end,
})

juhun:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, juhun.name)
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
  end,
})

juhun:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, juhun.name)
  end,
})

return juhun
