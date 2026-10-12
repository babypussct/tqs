local sidao = fk.CreateSkill {
  name = "os__sidao",
}

Fk:loadTranslationTable{
  ["os__sidao"] = "司道",
  [":os__sidao"] = "游戏开始时，你选择一件法宝并使用之：<a href=':celestial_calabash'>【灵宝仙葫】</a>、" ..
  "<a href=':horsetail_whisk'>【太极拂尘】</a>、<a href=':talisman'>【冲应神符】</a>。" ..
  "准备阶段，若你选择过的法宝不在游戏内或在牌堆或弃牌堆中，则你获得并使用之。",

  ["#os__sidao-ask"] = "司道：选择一件法宝并使用之",

  ["$os__sidao1"] = "执吾法器，以司正道。",
  ["$os__sidao2"] = "内修道法，外需宝器。",
}

local U = require "packages.utility.utility"

sidao:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(sidao.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {
      { "celestial_calabash", Card.Heart, 1 },
      { "horsetail_whisk", Card.Heart, 1 },
      { "talisman", Card.Heart, 1 },
    }
    cards = table.filter(room:prepareDeriveCards(cards, "sidao_derivecards"), function (id)
      return room:getCardArea(id) == Card.Void
    end)
    if #cards == 0 then return end
    local use = room:askToUseRealCard(player, {
      pattern = cards,
      skill_name = sidao.name,
      prompt = "#os__sidao-ask",
      extra_data = {
        expand_pile = cards,
      },
      cancelable = false,
    })
    if use == nil then return end
    room:setPlayerMark(player, "_os__sidao", use.card.id)
  end,
})

sidao:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      player.phase == Player.Start and
      player:hasSkill(sidao.name) and
      player:getMark("_os__sidao") ~= 0 and
      table.contains(
        { Card.DiscardPile, Card.DrawPile, Card.Void, Card.PlayerSpecial },
        player.room:getCardArea(player:getMark("_os__sidao"))
      )
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cardId = player:getMark("_os__sidao")
    room:obtainCard(player, cardId, true, fk.ReasonPrey, player)
    if table.contains(player:getCardIds("he"), cardId) and player:canUseTo(Fk:getCardById(cardId), player) then
      room:useCard{
        from = player,
        tos = { player },
        card = Fk:getCardById(cardId),
      }
    end
  end,
})

sidao:addEffect(fk.BeforeCardsMove, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local hold_areas = { Card.PlayerEquip, Card.Processing, Card.Void, Card.PlayerHand, Card.PlayerSpecial }
    local card_names = { "celestial_calabash", "horsetail_whisk", "talisman" }
    local mirror_moves = {}
    local ids = {}
    for _, move in ipairs(data) do
      if not table.contains(hold_areas, move.toArea) then
        local move_info = {}
        local mirror_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.contains(card_names, Fk:getCardById(id).name) then
            table.insert(mirror_info, info)
            table.insert(ids, id)
          else
            table.insert(move_info, info)
          end
        end
        if #mirror_info > 0 then
          move.moveInfo = move_info
          local mirror_move = move:copy()
          mirror_move.to = nil
          mirror_move.toArea = Card.Void
          mirror_move.moveInfo = mirror_info
          table.insert(mirror_moves, mirror_move)
        end
      end
    end
    if #ids > 0 then
      player.room:sendLog{
        type = "#DestructCards",
        card = ids,
      }
    end
    table.insertTable(data, mirror_moves)
  end,
})

return sidao
