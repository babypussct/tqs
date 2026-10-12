local youyan = fk.CreateSkill {
  name = "ol__youyan",
}

Fk:loadTranslationTable{
  ["ol__youyan"] = "诱言",
  [":ol__youyan"] = "出牌和弃牌阶段各限一次，当你的牌因弃置置入弃牌堆后，你可以从牌堆中获得与弃置牌花色不同的牌各一张。",

  ["$ol__youyan1"] = "巧佞卑谄，诱言者皆为之！",
  ["$ol__youyan2"] = "诱言者，巧言而令色，鲜矣仁！",
}

youyan:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(youyan.name) and
      (player.phase == Player.Play or player.phase == Player.Discard) and
      player:usedSkillTimes(youyan.name, Player.HistoryPhase) == 0 then
      local suits = {"spade", "club", "heart", "diamond"}
      local can_invoke = false
      for _, move in ipairs(data) do
        if move.from == player and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
              can_invoke = true
            end
          end
        end
      end
      if can_invoke and #suits > 0 then
        event:setCostData(self, { choice = suits })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = event:getCostData(self).choice
    local cards = {}

    --实测从牌堆底开始检索，正面移动
    local id = -1
    for i = #room.draw_pile, 1, -1 do
      id = room.draw_pile[i]
      if table.removeOne(suits, Fk:getCardById(id):getSuitString()) then
        table.insert(cards, id)
        if #suits == 0 then break end
      end
    end

    if #cards > 0 then
      room:obtainCard(player, cards, true, fk.ReasonJustMove, player, youyan.name)
    end
  end,
})

local AI = Fk.Ltk.AI
youyan:addAI(AI.reuse("biyue", AI.InvokeStrategy))

return youyan
