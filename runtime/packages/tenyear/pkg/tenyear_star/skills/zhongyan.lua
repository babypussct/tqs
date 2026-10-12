local zhongyan = fk.CreateSkill {
  name = "zhongyanz",
}

Fk:loadTranslationTable{
  ["zhongyanz"] = "忠言",
  [":zhongyanz"] = "出牌阶段限一次，你可展示牌堆顶三张牌，令一名角色将一张手牌交换其中一张牌。然后若这些牌颜色相同，其选择回复1点体力或"..
  "获得场上一张牌；若该角色不为你，你执行另一项。",

  ["#zhongyanz"] = "忠言：亮出牌堆顶三张牌，令一名角色用一张手牌交换其中一张牌",
  ["#zhongyanz-target"] = "忠言：选择一名角色，令其用一张手牌交换其中一张牌",
  ["#zhongyanz-exchange"] = "忠言：请用一张手牌交换其中一张牌",
  ["zhongyanz_prey"] = "获得场上一张牌",
  ["#zhongyanz-choose"] = "忠言：选择一名角色，获得其场上一张牌",

  ["$zhongyanz1"] = "千夫诺诺，不如一士谔谔。",
  ["$zhongyanz2"] = "忠言如药，苦口而利身。",
}

local function DoZhongyanz(player, source, choice)
  local room = player.room
  if choice == "recover" then
    if not player.dead and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = source,
        skillName = zhongyan.name,
      }
    end
  else
    local targets = table.filter(room.alive_players, function(p)
      return #p:getCardIds("ej") > 0
    end)
    if not player.dead and #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = zhongyan.name,
        prompt = "#zhongyanz-choose",
        cancelable = false,
      })[1]
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "ej",
        skill_name = zhongyan.name,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, zhongyan.name, nil, true, player)
    end
  end
end

Fk:addPoxiMethod{
  name = "zhongyanz",
  prompt = "#zhongyanz-exchange",
  card_filter = function(to_select, selected, data)
    if #selected < 2 then
      if #selected == 0 then
        return true
      else
        if table.contains(data[1][2], selected[1]) then
          return table.contains(data[2][2], to_select)
        else
          return table.contains(data[1][2], to_select)
        end
      end
    end
  end,
  feasible = function(selected)
    return #selected == 2
  end,
  default_choice = function (data, extra_data)
    return { data[1][2][1], data[2][2][1] }
  end,
}

zhongyan:addEffect("active", {
  anim_type = "support",
  prompt = "#zhongyanz",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zhongyan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = room:getNCards(3)
    room:turnOverCardsFromDrawPile(player, cards, zhongyan.name)

    local to = nil
    if #effect.tos > 0 then
      to = effect.tos[1]
    elseif not player.dead then
      --可以选没有手牌的角色
      to = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#zhongyanz-target",
        skill_name = zhongyan.name,
        cancelable = false,
      })[1]
    end

    if to == nil or to.dead or to:isKongcheng() then
      room:moveCardTo(table.reverse(cards), Card.DrawPile, nil, fk.ReasonJustMove, zhongyan.name, nil, true, to)
      return
    end

    local results = room:askToPoxi(to, {
      poxi_type = zhongyan.name,
      data = {
        { "Top", cards },
        { "hand_card", to:getCardIds("h") },
      },
      cancelable = false,
    })

    local card1 = table.contains(to:getCardIds("h"), results[1]) and results[1] or results[2]
    local card2 = card1 == results[1] and results[2] or results[1]

    --把不同区域的牌按特定顺序置于牌堆顶只能采用单卡move
    local moveInfos = {}
    for i = 3, 1, -1 do
      local moveInfo = {
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = zhongyan.name,
        moveVisible = false,
        proposer = to,
        visiblePlayers = { to }
      }
      if cards[i] == card2 then
        moveInfo.from = to
        cards[i] = card1
      end
      moveInfo.ids = { cards[i] }
      table.insert(moveInfos, moveInfo)
    end
    room:moveCards(table.unpack(moveInfos))

    if to.dead then
      room:cleanProcessingArea({card2})
      return
    else
      room:obtainCard(to, card2, false, fk.ReasonJustMove, to, zhongyan.name)
    end

    if to.dead then return end

    if table.every(cards, function(id)
      return Fk:getCardById(id).color == Fk:getCardById(cards[1]).color
    end) then
      local choices = {"recover", "zhongyanz_prey"}
      local choice = room:askToChoice(to, {
        choices = choices,
        skill_name = zhongyan.name,
      })
      DoZhongyanz(to, player, choice)
      if to ~= player then
        table.removeOne(choices, choice)
        DoZhongyanz(player, player, choices[1])
      end
    end
  end,
})

return zhongyan
