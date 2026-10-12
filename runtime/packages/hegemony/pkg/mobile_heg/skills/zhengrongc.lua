
local zhengrongc = fk.CreateSkill {
  name = "m_heg__zhengrongc",
}

Fk:loadTranslationTable{
  ["m_heg__zhengrongc"] = "征戎",
  [":m_heg__zhengrongc"] = "你受到伤害后，可以将一名角色的至多X张手牌替换为等量张【杀】（X为你已损失的体力值，且至少为1）。",

  ["#m_heg__zhengrongc-choose"] = "暗流：你可以将一名角色的至多%arg张手牌替换为等量【杀】",

  ["$m_heg__zhengrongc1"] = "瞻彼洛城郭，微子为哀伤。",
  ["$m_heg__zhengrongc2"] = "孤心所虑，唯荡平天下，以期太平！",
  ["$m_heg__zhengrongc3"] = "孤若不成，壮士焉能入土，忠魂岂归九泉？",
  ["$m_heg__zhengrongc4"] = "戎马不解鞍，铠甲不离傍。",
}

zhengrongc:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhengrongc.name) and
      table.find(player.room.alive_players, function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#m_heg__zhengrongc-choose:::"..math.max(1, player:getLostHp()),
      skill_name = zhengrongc.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = room:askToChooseCards(player, {
      target = to,
      min = 1,
      max = math.max(1, player:getLostHp()),
      flag = "h",
      skill_name = zhengrongc.name,
    })
    local x = #cards
    room:shuffleTable(cards)
    local positions = {}
    local y = #room.draw_pile
    for _ = 1, x, 1 do
      table.insert(positions, math.random(y + 1))
    end
    table.sort(positions, function (a, b)
      return a > b
    end)
    local moveInfos = {}
    for i = 1, x, 1 do
      table.insert(moveInfos, {
        ids = {cards[i]},
        from = to,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = zhengrongc.name,
        drawPilePosition = positions[i],
        proposer = player,
      })
    end
    room:moveCards(table.unpack(moveInfos))
    if to.dead then return end
    cards = room:getCardsFromPileByRule("slash", x)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonJustMove, zhengrongc.name, nil, false, to)
    end
  end,
})

return zhengrongc
