local xinghun = fk.CreateSkill{
  name = "xinghun",
}

Fk:loadTranslationTable{
  ["xinghun"] = "星魂",
  [":xinghun"] = "出牌阶段限一次，你可观看牌堆顶五张牌，用任意张手牌与其中等量牌进行交换并排序，"..
    "然后你令一名其他角色展示你手牌与牌堆顶共五张牌，你对其依次使用其中的【杀】。",

  ["#xinghun"] = "星魂：观看、交换并排列牌堆顶的5张牌",
  ["#xinghun-exchange"] = "星魂：观看、交换并排列这些牌，进入下一步",
  ["#xinghun-choose"] = "星魂：令1名角色选择展示的牌，然后你对其使用其中的【杀】",
  ["#xinghun-choosecard"] = "星魂：从牌堆顶及%src的手牌中选择5张卡牌展示，其中的【杀】将对你使用",

  ["$xinghun1"] = "仰观紫微知兴替，俯察将星照铁衣。",
  ["$xinghun2"] = "既晓九星所向，傲破万难独前。",
}

xinghun:addEffect("active", {
  prompt = "#xinghun",
  anim_type = "offensive",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local skillName = xinghun.name
    local player = effect.from
    local cards = room:getNCards(5)
    room:turnOverCardsFromDrawPile(player, cards, skillName, false)
    local results = room:askToArrangeCards(player, {
      skill_name = skillName,
      card_map = {
        "Top", cards,
        "$Hand", player:getCardIds("h"),
      },
      prompt = "#xinghun-exchange",
      free_arrange = true
    })

    --把不同区域的牌按特定顺序置于牌堆只能采用单卡move
    local moveInfos = {}
    for _, id in ipairs(table.reverse(results[1])) do
      table.insert(moveInfos, {
        ids = {id},
        from = not table.contains(cards, id) and player or nil,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = skillName,
        moveVisible = false,
        proposer = player,
        visiblePlayers = { player }
      })
    end
    room:moveCards(table.unpack(moveInfos))

    cards = table.filter(results[2], function(id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards > 0 then
      if player.dead then
        room:cleanProcessingArea(cards)
        return
      else
        room:obtainCard(player, cards, false, fk.ReasonJustMove, player, skillName)
        if player.dead then return end
      end
    end

    local others = room:getOtherPlayers(player, false)
    if #others == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = others,
      skill_name = skillName,
      prompt = "#xinghun-choose",
      cancelable = false,
    })[1]

    cards = room:getNCards(5)
    local handCards = player:getCardIds("h")

    local visible_data = {}
    for _, id in ipairs(cards) do
      visible_data[tostring(id)] = 0 -- 临时约定0为不可见且不参与随机
    end
    for _, id in ipairs(handCards) do
      visible_data[tostring(id)] = false
    end

    local poxiParams = { ---@type AskToPoxiParams
      poxi_type = "AskForCardsChosen",
      data = {
        { "Top", cards },
        { "$Hand", handCards }
      },
      extra_data = {
        to = player.id,
        min = 5,
        max = 5,
        skillName = skillName,
        prompt = "#xinghun-choosecard:" .. player.id,
        visible_data = visible_data
      },
      cancelable = false
    }

    local toShow = room:askToPoxi(to, poxiParams)
    handCards = {}
    cards = table.filter(toShow, function(id)
      if table.contains(cards, id) then
        return true
      else
        table.insert(handCards, id)
      end
    end)
    if #handCards > 0 then
      player:showCards(handCards, to)
    end
    if #cards > 0 then
      room:showCards(cards, nil, to)
    end
    room:delay(1000)

    for _, id in ipairs(toShow) do
      if player.dead or to.dead then break end
      local card = Fk:getCardById(id)
      --手杀不判区域是真的逆天啊
      if card.trueName == "slash" and player:canUseTo(card, to, { bypass_distances = true, bypass_times = true }) then
        room:useCard {
          from = player,
          card = card,
          tos = { to },
          extraUse = true
        }
      end
    end
  end,
})

return xinghun
