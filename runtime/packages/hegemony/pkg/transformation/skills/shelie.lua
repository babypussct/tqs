local shelie = fk.CreateSkill {
  name = "ld__lordsunquan_shelie",
}

Fk:loadTranslationTable{
  ["ld__lordsunquan_shelie"] = "涉猎",
  [":ld__lordsunquan_shelie"] = "摸牌阶段，你可以改为亮出牌堆顶五张牌，获得不同花色的牌各一张。",

  ["$ld__lordsunquan_shelie1"] = "军中多务，亦当涉猎。",
  ["$ld__lordsunquan_shelie2"] = "少说话，多看书。",
}

shelie:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shelie.name) and player.phase == Player.Draw and not data.phase_end
  end,
  on_use = function(self, event, target, player, data)
    data.phase_end = true
    local room = player.room
    local cards = room:getNCards(5)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = shelie.name,
      proposer = player.id,
    })
    local get = {}
    for _, id in ipairs(cards) do
      local suit = Fk:getCardById(id).suit
      if table.every(get, function (id2)
        return Fk:getCardById(id2).suit ~= suit
      end) then
        table.insert(get, id)
      end
    end
    get = room:askToArrangeCards(player, {
      skill_name = shelie.name,
      card_map = cards,
      prompt = "#shelie-choose",
      free_arrange = false,
      box_size = 0,
      max_limit = {5, 4},
      min_limit = {0, #get},
      poxi_type = "shelie",
      default_choice = {{}, get},
    })[2]
    if #get > 0 then
      room:obtainCard(player, get, true, fk.ReasonPrey, player, shelie.name)
    end
    room:cleanProcessingArea(cards)
  end,
})

return shelie
