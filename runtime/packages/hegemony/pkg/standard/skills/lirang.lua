local lirang = fk.CreateSkill{
  name = "lirang",
}

Fk:loadTranslationTable{
  ["lirang"] = "礼让",
  [":lirang"] = "当你的牌因弃置而移至弃牌堆后，你可以将其中的至少一张牌交给其他角色。",

  ["#lirang-give"] = "礼让：你可以将这些牌分配给任意角色，点“取消”仍弃置",

  ["$lirang1"] = "夫礼，先王以承天之道，以治人之情。",
  ["$lirang2"] = "谦者，德之柄也，让者，礼之主也。",
}

lirang:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player.room.discard_pile, info.cardId) and
            (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player.room.discard_pile, info.cardId) and
            (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end
    room:askToYiji(player, {
      targets = room:getOtherPlayers(player, false),
      cards = ids,
      skill_name = lirang.name,
      min_num = 0,
      max_num = #ids,
      prompt = "#lirang-give",
      expand_pile = ids,
    })
  end,
})

return lirang
