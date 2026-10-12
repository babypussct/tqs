local mianzhu = fk.CreateSkill {
  name = "peixiu_mianzhu",
}

Fk:loadTranslationTable {
  ["peixiu_mianzhu"] = "绵竹",
  [":peixiu_mianzhu"] = "结束阶段，你观看牌堆顶三张牌，然后可以获得其中类型不同的牌各一张。",

  ["#peixiu_mianzhu-choose"] = "绵竹：选择要获得的牌",
}

Fk:addPoxiMethod{
  name = mianzhu.name,
  card_filter = function(to_select, selected, data)
    ---@cast data integer[][]
    if table.contains(data[2], to_select) then return true end
    local type = Fk:getCardById(to_select).type
    return table.every(data[2], function (id)
      return Fk:getCardById(id).type ~= type
    end)
  end,
  feasible = Util.TrueFunc,
}

mianzhu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mianzhu.name) and player.phase == Player.Finish
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:turnOverCardsFromDrawPile(player, cards, mianzhu.name, false)
    local get = {}
    for _, id in ipairs(cards) do
      local type = Fk:getCardById(id).type
      if table.every(get, function (id2)
        return Fk:getCardById(id2).type ~= type
      end) then
        table.insert(get, id)
      end
    end
    get = room:askToArrangeCards(player, {
      skill_name = mianzhu.name,
      card_map = cards,
      prompt = "#peixiu_mianzhu-choose",
      free_arrange = false,
      box_size = 0,
      max_limit = { 3, 3 },
      min_limit = { 0, #get },
      poxi_type = mianzhu.name,
      default_choice = {{}, get},
    })[2]
    if #get > 0 then
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonJustMove, mianzhu.name, nil, false, player)
    end
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards > 0 then
      room:returnCardsToDrawPile(player, cards, mianzhu.name, "top", false)
    end
  end,
})

return mianzhu
