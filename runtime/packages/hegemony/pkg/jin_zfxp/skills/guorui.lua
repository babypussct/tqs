
local guorui = fk.CreateSkill{
  name = "heg__guorui",
}

Fk:loadTranslationTable{
  ["heg__guorui"] = "果锐",
  [":heg__guorui"] = "一张【决斗】结算后，你可以选择一项：1.对一名角色依次使用弃牌堆中此过程中打出的【杀】；2.变更副将牌。",

  ["#heg__guorui-invoke"] = "果锐：你可以对一名角色使用响应此【决斗】的【杀】或变更副将",
  ["heg__guorui_slash"] = "对一名角色使用响应此【决斗】的【杀】",
}

local H = require "packages.hegemony.util"

guorui:addAuxActiveSkill("#heg__guorui_active", {
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  interaction = function(self, player)
    return UI.OptionBox { options = { "heg__guorui_slash", "transformDeputy" }, direct_send = true }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and
      player:canUseTo(Fk:cloneCard("slash"), to_select, { bypass_distances = true, bypass_times = true })
  end,
  refresh_interaction = function (self, player, selected_cards, selected_targets, extra_data)
    if #selected_targets == 1 then
      return { "heg__guorui_slash" }
    end
    return {}
  end,
})

guorui:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guorui.name) and data.card.trueName == "duel"
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#heg__guorui_active",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if to then
      local cards = {}
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return end
      use_event:searchEvents(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.moveReason == fk.ReasonResponse and move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).trueName == "slash" and table.contains(room.discard_pile, info.cardId) then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end)
      while #cards > 0 do
        local looplock = 0
        for _, id in ipairs(cards) do
          local slash = Fk:getCardById(id)
          if slash.trueName == "slash" and table.contains(room.discard_pile, id) then
            if player:canUseTo(slash, to, { bypass_distances = true, bypass_times = true }) then
              table.removeOne(cards, id)
              room:useCard{
                from = player,
                tos = { to },
                card = slash,
                extraUse = true,
              }
              if player.dead or to.dead then return end
            else
              looplock = looplock + 1
              if looplock > 20 then
                return
              end
            end
          end
        end
      end
    else
      H.transformGeneral(room, player)
    end
  end,
})

return guorui
