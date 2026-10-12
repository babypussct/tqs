local runwei = fk.CreateSkill {
  name = "mobile__runwei",
}

Fk:loadTranslationTable{
  ["mobile__runwei"] = "润微",
  [":mobile__runwei"] = "出牌阶段限一次，你可以展示牌堆顶至多五张牌，令一名角色获得其中一种颜色的所有牌。若如此做："..
    "1.每阶段限一次，你失去X张牌后（X为其因此获得的牌数），该技能可以再次发动且不能指定本回合获得过牌的角色为目标；"..
    "2.本阶段结束时，你弃置以此法获得的手牌。",

  ["#mobile__runwei"] = "润微：你可展示牌堆顶至多5张牌，令1名角色获得其中一种颜色的牌",
  ["#mobile__runwei-choose"] = "润微：选择令1名角色获得其中一种颜色的牌",
  ["@mobile__runwei-phase"] = "润微",
  ["@@mobile__runwei-inhand-phase"] = "润微",
  ["mobile__runwei_disabled"] = "获得过牌",

  ["$mobile__runwei1"] = "以妾身微躯，亦可奉叔妹无虞。",
  ["$mobile__runwei2"] = "妾力虽微，然足以挑一肩家计。",
  ["$mobile__runwei3"] = "君等困顿未解，我岂可半途而废？",
  ["$mobile__runwei4"] = "有舍有得，此固自然之理。",
}

runwei:addAuxActiveSkill("mobile__runwei_active", {
  card_num = 0,
  target_num = 1,
  interaction = function(self)
    return UI.OptionBox { options = self.mobile__runwei_choices, all_options = {"red", "black"}, direct_send = true }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and not table.contains(self.mobile__runwei_disabled, to_select.id)
  end,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if table.contains(self.mobile__runwei_disabled, to_select.id) then
      return { {content = "mobile__runwei_disabled", type = "warning"} }
    end
  end,
  visible_pile = "_expand_pile",
})

runwei:addEffect("active", {
  anim_type = "support",
  prompt = "#mobile__runwei",
  audio_index = { 1, 2 },
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    local x = player:usedEffectTimes(runwei.name, Player.HistoryPhase)
    if x == 0 then
      return true
    elseif x == 1 then
      --机制不明，先偷懒
      return player:getMark("@mobile__runwei-phase") == 0
    end
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if player:usedEffectTimes(runwei.name, Player.HistoryPhase) == 1 and
      table.contains(player:getTableMark("mobile__runwei_disabled-turn"), to_select.id) then
      return { {content = "mobile__runwei_disabled", type = "warning"} }
    end
  end,
  interaction = function(self, player)
    return UI.Spin {
      from = 1,
      to = 5,
    }
  end,
  on_use = function(self, room, effect)
    local skillName = runwei.name
    local player = effect.from
    local cards = room:getNCards(self.interaction.data)
    local event_id = room.logic.current_event_id
    room:showCards(cards, player)
    if player.dead then return end
    cards = room.logic:moveCardsHoldingAreaCheck(cards, event_id)
    if #cards == 0 then return end

    local color
    local red = {}
    local black = table.filter(cards, function (id)
      color = Fk:getCardById(id).color
      if color == Card.Red then
        table.insert(red, id)
      end
      return color == Card.Black
    end)
    local choices = {}
    if #red > 0 then
      table.insert(choices, "red")
    end
    if #black > 0 then
      table.insert(choices, "black")
    end

    if #choices == 0 then return end
    local choice = choices[1]
    local to = player

    local disabled_players = {}
    if player:usedEffectTimes(skillName, Player.HistoryPhase) == 2 then
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.to and move.toArea == Card.PlayerHand and #move.moveInfo > 0 then
            table.insertIfNeed(disabled_players, move.to.id)
          end
        end
        return false
      end, nil, Player.HistoryTurn)
      if #disabled_players > 0 then
        to = table.find(room.alive_players, function (p)
          return not table.contains(disabled_players, p.id)
        end)
        if to == nil then return end
      end
    end

    local _, dat = room:askToUseActiveSkill(player, {
      skill_name = "mobile__runwei_active",
      prompt = "#mobile__runwei-choose",
      cancelable = false,
      extra_data = {
        skillName = skillName,
        expand_pile = cards,
        mobile__runwei_choices = choices,
        mobile__runwei_disabled = disabled_players,
      }
    })
    if dat then
      choice = dat.interaction
      to = dat.targets[1]
      room:doIndicate(player, { to })
    end
    if choice == "black" then
      red = black
    end

    room:obtainCard(to, red, true, fk.ReasonJustMove, player, skillName,
      (player == to and player:hasSkill(skillName, true)) and "@@mobile__runwei-inhand-phase" or nil)

    if player:hasSkill(skillName, true) and player:usedEffectTimes(skillName, Player.HistoryPhase) == 1 then
      room:setPlayerMark(player, "@mobile__runwei-phase", #red)
    end
  end,
})

local U = require "packages.utility.utility"

runwei:addEffect(fk.AfterCardsMove, {
  audio_index = 3,
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@mobile__runwei-phase") == 0 or not player:hasSkill(runwei.name) then return false end
    local x = #U.getLostCardsFromMove(player, data)
    if x > 0 then
      event:setCostData(self, { number = x, mute = (x < player:getMark("@mobile__runwei-phase")) })
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local x = math.max(0, player:getMark("@mobile__runwei-phase") - event:getCostData(self).number)
    player.room:setPlayerMark(player, "@mobile__runwei-phase", x)
  end,

  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(runwei.name, true) and player.room:getCurrent() == player
  end,
  on_refresh = function(self, event, target, player, data)
    local disabled_players = player:getTableMark("mobile__runwei_disabled-turn")
    local mark_refresh = false
    for _, move in ipairs(data) do
      if move.to and move.toArea == Card.PlayerHand and #move.moveInfo > 0 then
        if table.insertIfNeed(disabled_players, move.to.id) then
          mark_refresh = true
        end
      end
    end
    if mark_refresh then
      player.room:setPlayerMark(player, "mobile__runwei_disabled-turn", disabled_players)
    end
  end
})

runwei:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  audio_index = 4,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(runwei.name) and table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id, true):getMark("@@mobile__runwei-inhand-phase") > 0
    end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card
    local cards = table.filter(player:getCardIds("h"), function (id)
      card = Fk:getCardById(id)
      return card:getMark("@@mobile__runwei-inhand-phase") > 0 and not player:prohibitDiscard(card)
    end)
    if #cards > 0 then
      room:throwCard(cards, runwei.name, player, player)
    end
  end,
})

runwei:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  if room:getCurrent() == player then
    local disabled_players = {}
    room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.to and move.toArea == Card.PlayerHand and #move.moveInfo > 0 then
          table.insertIfNeed(disabled_players, move.to.id)
        end
      end
        return false
    end, nil, Player.HistoryTurn)
    if #disabled_players > 0 then
        room:setPlayerMark(player, "mobile__runwei_disabled-turn", disabled_players)
    end
  end
end)

runwei:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@mobile__runwei-phase", 0)
  local card
  for _, id in ipairs(player:getCardIds("h")) do
    card = Fk:getCardById(id, true)
    if card:getMark("@@mobile__runwei-inhand-phase") > 0 then
      room:setCardMark(card, "@@mobile__runwei-inhand-phase", 0)
    end
  end
end)

return runwei
