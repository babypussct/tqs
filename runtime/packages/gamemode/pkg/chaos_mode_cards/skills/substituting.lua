local skill = fk.CreateSkill {
  name = "substituting_skill",
}

skill:addEffect("cardskill", {
  prompt = "#substituting_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if to.dead or from.dead or (to:isKongcheng() and from:isKongcheng()) then return end
    local cards = {}
    local moveInfos = {}
    for _, p in ipairs({from, to}) do
      if #p:getCardIds("h") > 0 then
        table.insert(moveInfos, {
          ids = table.clone(p:getCardIds("h")),
          fromArea = Card.PlayerHand,
          from = p,
          toArea = Card.Processing,
          moveReason = fk.ReasonJustMove,
          skillName = skill.name,
          moveVisible = false,
        })
        table.insertTable(cards, p:getCardIds("h"))
      end
    end
    room:moveCards(table.unpack(moveInfos))
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    room:delay(1000)
    if #cards == 0 then return false end
    local num = math.random(0, #cards)
    if to.dead and from.dead then
      room:cleanProcessingArea(cards)
      return false
    elseif from.dead then
      num = 0 --乐
    elseif to.dead then
      num = #cards
    end
    if num == 0 then
      room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonJustMove, skill.name, nil, false)
    elseif num == #cards then
      room:moveCardTo(cards, Card.PlayerHand, from, fk.ReasonJustMove, skill.name, nil, false)
    else
      local cids = room:tableRandomPick(cards, num)
      local cids2 = table.filter(cards, function(c)
        return not table.contains(cids, c)
      end)
      local moves = {}
      if #cids > 0 then
        table.insert(moves, {
          ids = cids,
          fromArea = Card.Processing,
          to = from,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          skillName = skill.name,
          moveVisible = false,
        })
      end
      if #cids2 > 0 then
        table.insert(moves, {
          ids = cids2,
          fromArea = Card.Processing,
          to = to,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          skillName = skill.name,
          moveVisible = false,
        })
      end
      if #moves > 0 then
        room:moveCards(table.unpack(moves))
      end
    end
    room:cleanProcessingArea(cards)
  end,
})

return skill
