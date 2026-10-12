local guqing = fk.CreateSkill {
  name = "guqing",
}

Fk:loadTranslationTable{
  ["guqing"] = "固请",
  [":guqing"] = "出牌阶段限一次，你可以选择一名其他角色，其需将至多两张手牌交给另一名角色，"..
    "每少交出一张牌，其失去1点体力，你回复1点体力。若其未交出牌，直到其下个回合结束之前，其当前所有手牌均视为【无懈可击】。",

  ["#guqing-active"] = "固请：选择要交出牌的角色",
  ["#guqing-target"] = "固请：选择要获得牌的角色",
  ["#guqing-confirm"] = "固请：%src需将至多两张手牌交给%dest",
  ["guqing_tip_1"] = "交出牌",
  ["guqing_tip_2"] = "获得牌",
  ["#guqing-cards"] = "固请：你需将至多两张手牌交给%dest，每少一张失去1点体力，不交出则手牌均视为【无懈可击】",

  ["$guqing1"] = "",
  ["$guqing2"] = "",
}

guqing:addEffect("active", {
  anim_type = "offensive",
  prompt = function(self, player, selected_cards, selected_targets)
    if #selected_targets == 1 then
      return "#guqing-target"
    elseif #selected_targets == 2 then
      return "#guqing-confirm:" .. selected_targets[1].id ..":" .. selected_targets[2].id
    end
    return "#guqing-active"
  end,
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return to_select ~= player
    else
      return #selected < 2
    end
  end,
  on_use = function(self, room, effect)
    local skillName = guqing.name
    local player = effect.from
    local from, to = effect.tos[1], effect.tos[2]
    local cards = room:askToCards(from, {
      min_num = 1,
      max_num = 2,
      include_equip = false,
      skill_name = skillName,
      prompt = "#guqing-cards::" .. to.id,
      cancelable = true,
    })
    if #cards > 0 then
      room:obtainCard(to, cards, false, fk.ReasonGive, from, skillName)
    end
    local n = 2-#cards
    if n > 0 then
      if from:isAlive() then
        room:loseHp(from, n, skillName, player)
      end
      if player:isAlive() and player:isWounded() then
        room:recover { who = player, num = n, skillName = skillName, recoverBy = player }
      end
      if n == 2 then
        for _, id in ipairs(from:getCardIds("h")) do
          room:setCardMark(Fk:getCardById(id, true), "guqing-inhand", 1)
          Fk:filterCard(id, from)
        end
      end
    end
  end,
  target_tip = function(self, _, to_select, selected, _, _, selectable, _)
    if not selectable then return end
    if #selected == 0 or (#selected > 0 and selected[1] == to_select) then
      return "guqing_tip_1"
    else
      return "guqing_tip_2"
    end
  end,
})

guqing:addEffect("filter", {
  card_filter = function(self, to_select, player)
    return table.contains(player:getCardIds("h"), to_select.id) and to_select:getMark("guqing-inhand") ~= 0
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("nullification", card.suit, card.number)
  end,
})

guqing:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id, true)
      if card:getMark("guqing-inhand") ~= 0 then
        room:setCardMark(card, "guqing-inhand", 0)
        Fk:filterCard(id, player)
      end
    end
  end,
})

return guqing
