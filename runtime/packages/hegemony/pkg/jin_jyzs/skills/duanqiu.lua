local duanqiu = fk.CreateSkill{
  name = "heg__duanqiu",
}

Fk:loadTranslationTable{
  ["heg__duanqiu"] = "断虬",
  [":heg__duanqiu"] = "准备阶段，你可以选择一个其他势力，视为对该势力的所有角色使用一张【决斗】，此牌结算后，你令所有角色本回合内至多共计再使用X张手牌（X为此【决斗】结算过程中打出的【杀】数量）。",

  ["@heg__duanqiu_count-turn"] = "断虬 限制",

  ["$heg__duanqiu1"] = "此击若中，万念俱灰！",
  ["$heg__duanqiu2"] = "姿器膂力，万人之雄。",
}

local H = require "packages.hegemony.util"

duanqiu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(duanqiu.name) and target == player and player.phase == Player.Start then
      return table.find(player.room.alive_players, function (p)
        return not H.compareKingdomWith(p, player) and H.getGeneralsRevealedNum(p) > 0
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local enemy_choose = {}
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if not H.compareKingdomWith(p, player) and H.getGeneralsRevealedNum(p) > 0 then
        table.insertIfNeed(enemy_choose, p.kingdom)
      end
    end
    if #enemy_choose > 0 then
      local choice = room:askToChoice(player, {choices = enemy_choose, skill_name = duanqiu.name})
      local duel_targets = {}
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        if p.kingdom == choice then
          table.insertIfNeed(duel_targets, p)
        end
      end
      if #duel_targets > 0 then
        room:useVirtualCard("duel", nil, player, duel_targets, duanqiu.name, true)
      end
    end
  end,
})

duanqiu:addEffect(fk.CardUseFinished, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(duanqiu.name) and
      data.card and table.contains(data.card.skillNames, duanqiu.name) then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return end
      local cards = {}
      room.logic:getEventsByRule(GameEvent.RespondCard, 1, function (e)
        local response = e.data
        if response.responseToEvent and response.responseToEvent.card and
          table.contains(response.responseToEvent.card.skillNames, duanqiu.name) then
          local ids = response.card:isVirtual() and response.card.subcards or { response.card.id }
          for _, id in ipairs(ids) do
            table.insertIfNeed(cards, id)
          end
        end
      end, use_event.id)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      else
        player.room:setBanner("heg__duanqiu_count-turn", 1)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@heg__duanqiu_count-turn", #event:getCostData(self).cards)
  end,
})

duanqiu:addEffect(fk.CardUsing, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(duanqiu.name) and player.room.current == player and player:getMark("@heg__duanqiu_count-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@heg__duanqiu_count-turn", 1)
    if player:getMark("@heg__duanqiu_count-turn") <= 0 then
      player.room:setBanner("heg__duanqiu_count-turn", 1)
    end
  end,
})

duanqiu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if Fk:currentRoom():getBanner("heg__duanqiu_count-turn") then
     local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
})

return duanqiu
