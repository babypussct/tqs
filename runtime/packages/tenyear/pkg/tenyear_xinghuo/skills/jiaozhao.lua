local jiaozhao = fk.CreateSkill {
  name = "ty_ex__jiaozhao",
  dynamic_desc = function (self, player)
    if player:getMark("ty_ex__danxin") > 0 then
      return "ty_ex__jiaozhao_update"..player:getMark("ty_ex__danxin")
    end
  end,
}

Fk:loadTranslationTable{
  ["ty_ex__jiaozhao"] = "矫诏",
  [":ty_ex__jiaozhao"] = "出牌阶段限一次，你可以展示一张手牌并选择一名距离最近的其他角色，该角色声明一种基本牌或普通锦囊牌的牌名，"..
  "本回合你可以将此牌当声明的牌使用（不能指定自己为目标）。",

  [":ty_ex__jiaozhao_update1"] = "出牌阶段限一次，你可以展示一张手牌并声明一种基本牌或普通锦囊牌的牌名，"..
  "本回合你可以将此牌当声明的牌使用（不能指定自己为目标）。",
  [":ty_ex__jiaozhao_update2"] = "出牌阶段，你可以展示一张手牌并声明一种基本牌或普通锦囊牌的牌名（每阶段每种类型限一次），"..
  "本回合你可以将此牌当声明的牌使用。",

  ["#ty_ex__jiaozhao0"] = "矫诏：展示一张手牌，令一名角色声明一种基本牌或普通锦囊牌",
  ["#ty_ex__jiaozhao1"] = "矫诏：展示一张手牌，然后声明一种基本牌或普通锦囊牌",
  ["#ty_ex__jiaozhao2"] = "矫诏：展示一张手牌，然后声明一种基本牌或普通锦囊牌",
  ["#ty_ex__jiaozhao-use"] = "矫诏：你可以将“矫诏”牌当声明的牌 %arg 使用",
  ["#ty_ex__jiaozhao-choice"] = "矫诏：声明一种牌名，%src 本回合可以将%arg当此牌使用",
  ["@ty_ex__jiaozhao-inhand-turn"] = "矫诏",
  ["#ty_ex__jiaozhao-both"] = "矫诏：你可以展示一张手牌并声明一种牌，或将“矫诏”牌当声明的牌使用",
  ["#ty_ex__jiaozhao2-choice"] = "矫诏：使用这张牌，还是重新声明“矫诏”牌名？",
  ["ty_ex__jiaozhao_declare"] = "重新声明",

  ["$ty_ex__jiaozhao1"] = "事关社稷，万望阁下谨慎行事。",
  ["$ty_ex__jiaozhao2"] = "为续江山，还请爱卿仔细观之。",
}

---@param player Player
---@return Card?
local getJiaoZhaoCard = function(player)
  for _, cid in ipairs(player:getCardIds("h")) do
    local name = Fk:getCardById(cid, true):getMark("ty_ex__jiaozhao-inhand-turn")
    if type(name) == "string" and Fk.all_card_types[name] then
      local card = Fk:cloneCard(name)
      card.skillName = jiaozhao.name
      card:addSubcard(cid)
      return card
    end
  end
end

local U = require "packages.utility.utility"

jiaozhao:addEffect("viewas", {
  pattern = ".",
  prompt = function (self, player, selected_cards, selected_targets)
    local card = getJiaoZhaoCard(player)
    if card then
      return "#ty_ex__jiaozhao-use:::" .. card:toLogString()
    end
    return "#ty_ex__jiaozhao" .. player:getMark("ty_ex__danxin")
  end,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  card_filter = function(self, player, to_select, selected, selected_targets)
    if #selected > 0 then return false end
    local card = getJiaoZhaoCard(player)
    if card then
      return to_select == card.subcards[1] and player:canUseOrResponseInCurrent(card)
    else
      return table.contains(player:getCardIds("h"), to_select)
    end
  end,
  view_as = function(self, player, cards)
    if #cards > 0 then
      return getJiaoZhaoCard(player)
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards, c, extra_data)
    if getJiaoZhaoCard(player) == nil and player:getMark("ty_ex__danxin") == 0 and
      #selected == 0 and to_select ~= player and not player:isRemoved() and not to_select:isRemoved() then
      local x = player:distanceTo(to_select)
      return table.every(Fk:currentRoom().alive_players, function(p)
        return p == player or p == to_select or p:isRemoved() or player:distanceTo(p) >= x
      end)
    end
  end,
  feasible = function(self, player, selected, selected_cards, card)
    return #selected_cards == 1 and #selected + player:getMark("ty_ex__danxin") > 0
  end,
  on_use = function(self, room, effect, card, params)
    if card then
      return ViewAsSkill:onUse(room, effect, card, params)
    else
      local player = effect.from
      local target = #effect.tos > 0 and effect.tos[1] or player
      player:showCards(effect.cards)
      if target.dead or not player:hasSkill(jiaozhao.name, true) then return end

      local id = effect.cards[1]
      if not table.contains(player:getCardIds("h"), id) then return end
      local flag = "bt"
      if #player:getTableMark("ty_ex__jiaozhao_types-phase") == 1 then
        if player:getMark("ty_ex__jiaozhao_types-phase")[1] == "b" then
          flag = "t"
        else
          flag = "b"
        end
      end
      local choice = U.askForChooseCardNames(room, target,
        Fk:getAllCardNames(flag),
        1,
        1,
        jiaozhao.name,
        "#ty_ex__jiaozhao-choice:"..player.id.."::"..Fk:getCardById(id):toLogString()
      )[1]
      room:sendLog{
        type = "#Choice",
        from = target.id,
        arg = choice,
        toast = true,
      }
      room:addTableMark(player, "ty_ex__jiaozhao_types-phase", Fk:cloneCard(choice):getTypeString()[1])
      room:setCardMark(Fk:getCardById(id), "ty_ex__jiaozhao-inhand-turn", choice)
      room:setCardMark(Fk:getCardById(id), "@ty_ex__jiaozhao-inhand-turn", Fk:translate(choice))
    end
  end,
  enabled_at_play = function(self, player)
    local card = getJiaoZhaoCard(player)
    if card then
      return player:canUse(card)
    else
      return #player:getTableMark("ty_ex__jiaozhao_types-phase") < math.max(1, player:getMark("ty_ex__danxin"))
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return false end
    local card = getJiaoZhaoCard(player)
    return card and player:canUseOrResponseInCurrent(card)
  end,
})

jiaozhao:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return card and table.contains(card.skillNames, jiaozhao.name) and from == to and from:getMark("ty_ex__danxin") < 2
  end,
})

jiaozhao:addLoseEffect(function (self, player)
  local room = player.room
  room:setPlayerMark(player, "ty_ex__jiaozhao_types-phase", 0)
  room:setPlayerMark(player, "ty_ex__danxin", 0)
  local c
  for _, cid in ipairs(player:getCardIds("h")) do
    c = Fk:getCardById(cid, true)
    if c:getMark("ty_ex__jiaozhao-inhand-turn") ~= 0 then
      room:setCardMark(c, "@ty_ex__jiaozhao-inhand-turn", 0)
      room:setCardMark(c, "ty_ex__jiaozhao-inhand-turn", 0)
    end
  end
end)

return jiaozhao
