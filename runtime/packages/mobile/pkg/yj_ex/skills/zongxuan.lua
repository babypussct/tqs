local zongxuan = fk.CreateSkill {
  name = "m_ex__zongxuan",
}

Fk:loadTranslationTable{
  ["m_ex__zongxuan"] = "纵玄",
  [":m_ex__zongxuan"] = "出牌阶段限一次，你可以摸一张牌，然后将一张牌置于牌堆顶；当你的牌因弃置而置入弃牌堆时，你可以将其中任意张牌置于牌堆顶。",

  ["#m_ex__zongxuan-active"] = "纵玄：你可以摸一张牌，然后将一张牌置于牌堆顶",
  ["#m_ex__zongxuan-put"] = "纵玄：将一张牌置于牌堆顶",
  ["#m_ex__zongxuan-invoke"] = "纵玄：将任意数量的弃牌置于牌堆顶",
  ["#PutKnownCardtoDrawPile"] = "%from 将 %card 置于牌堆顶",

  ["$m_ex__zongxuan1"] = "近日之事，吾心已有谱。",
  ["$m_ex__zongxuan2"] = "我来为将军算上一卦。",
}

zongxuan:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#m_ex__zongxuan-active",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, use)
    local player = use.from
    player:drawCards(1, zongxuan.name)
    if player:isNude() then return end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = zongxuan.name,
      cancelable = false,
      prompt = "#m_ex__zongxuan-put",
    })
    room:moveCardTo(card, Card.DrawPile, nil, fk.ReasonPut, zongxuan.name, nil, false, player)
  end,
})

zongxuan:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zongxuan.name) then
      local room = player.room
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              if room:getCardArea(info.cardId) == Card.DiscardPile then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end
      cards = room.logic:moveCardsHoldingAreaCheck(cards)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local top = event:getCostData(self).cards
    if #top > 1 then
      top = room:askToArrangeCards(player, {
        skill_name = zongxuan.name,
        card_map = {top, "pile_discard","Top"},
        prompt = "#m_ex__zongxuan-invoke",
        free_arrange = true,
        box_size = 7,
        min_limit = {0, 1},
      })[2]
    end
    room:sendLog{
      type = "#PutKnownCardtoDrawPile",
      from = player.id,
      card = top
    }
    room:moveCardTo(table.reverse(top), Card.DrawPile, nil, fk.ReasonPut, zongxuan.name, nil, true, player)
  end,
})

return zongxuan
