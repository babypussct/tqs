local qiaosi = fk.CreateSkill {
  name = "qiaosi",
}

Fk:loadTranslationTable{
  ["qiaosi"] = "巧思",
  [":qiaosi"] = "出牌阶段限一次，你可以表演一次“水转百戏图”，获得对应的牌，然后你选择一项：1.弃置等量的牌；2.将等量的牌交给一名其他角色。"..
  "（不足则全给/全弃）",

  ["#qiaosi"] = "巧思：你可以表演一次“水转百戏图”，赢取奖励！",
  ["qiaosi_baixitu"] = "百戏图",
  ["qiaosi_figure1"] = "王：两张锦囊",
  ["qiaosi_figure2"] = "商：75%装备，25%杀/酒；选中“将”则必出杀/酒",
  ["qiaosi_figure3"] = "工：75%杀，25%酒",
  ["qiaosi_figure4"] = "农：75%闪，25%桃",
  ["qiaosi_figure5"] = "士：75%锦囊，25%闪/桃；选中“王”则必出闪/桃",
  ["qiaosi_figure6"] = "将：两张装备",
  ["qiaosi_abort"] = "不转了",
  ["#qiaosi_log"] = "巧思转出来的结果是：%card",
  ["qiaosi_give"] = "交出等量张牌",
  ["qiaosi_discard"] = "弃置等量张牌",
  ["#qiaosi-give"] = "巧思：将%arg张牌交给一名其他角色",

  ["$qiaosi1"] = "待我稍作思量，更益其巧。",
  ["$qiaosi2"] = "虚争空言，不如思而试之。",
}

qiaosi:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#qiaosi",
  can_use = function(self, player)
    return player:usedSkillTimes(qiaosi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local choosed = room:askToChoices(player, {
      choices = {
        "qiaosi_figure1",
        "qiaosi_figure2",
        "qiaosi_figure3",
        "qiaosi_figure4",
        "qiaosi_figure5",
        "qiaosi_figure6",
        --"qiaosi_abort",
      },
      min_num = 0,
      max_num = 3,
      skill_name = "qiaosi_baixitu",
      cancelable = false,
    })
    local cards = {}
    for _, choice in ipairs(choosed) do
      local id_neg = "^(" .. table.concat(cards, ",") .. ")"
      if choice:endsWith("1") then
        local ids = room:getCardsFromPileByRule(".|.|.|.|.|trick|" .. id_neg, 2, "allPiles")
        table.insertTable(cards, ids)
        if #ids < 2 then
          table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|.|" .. id_neg, 2 - #ids, "allPiles"))
        end
      elseif choice:endsWith("2") then
        if table.contains(choosed, "qiaosi_figure6") or math.random() > 0.75 then
          local name = math.random() < 0.75 and "analeptic" or "slash"
          local ids = room:getCardsFromPileByRule(name .. "|.|.|.|.|.|" .. id_neg, 1, "allPiles")
          table.insertTable(cards, ids)
          if #ids < 1 then
            table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|.|" .. id_neg, 1, "allPiles"))
          end
        else
          local ids = room:getCardsFromPileByRule(".|.|.|.|.|equip|" .. id_neg, 1, "allPiles")
          table.insertTable(cards, ids)
          if #ids < 1 then
            table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|.|" .. id_neg, 1, "allPiles"))
          end
        end
      elseif choice:endsWith("3") then
        local name = math.random() > 0.75 and "analeptic" or "slash"
        local ids = room:getCardsFromPileByRule(name .. "|.|.|.|.|.|" .. id_neg, 1, "allPiles")
        table.insertTable(cards, ids)
        if #ids < 1 then
          table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|.|" .. id_neg, 1, "allPiles"))
        end
      elseif choice:endsWith("4") then
        local name = math.random() > 0.75 and "peach" or "jink"
        local ids = room:getCardsFromPileByRule(name .. "|.|.|.|.|.|" .. id_neg, 1, "allPiles")
        table.insertTable(cards, ids)
        if #ids < 1 then
          table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|.|" .. id_neg, 1, "allPiles"))
        end
      elseif choice:endsWith("5") then
        if table.contains(choosed, "qiaosi_figure1") or math.random() > 0.75 then
          local name = math.random() < 0.75 and "peach" or "jink"
          local ids = room:getCardsFromPileByRule(name .. "|.|.|.|.|.|" .. id_neg, 1, "allPiles")
          table.insertTable(cards, ids)
          if #ids < 1 then
            table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|.|" .. id_neg, 1, "allPiles"))
          end
        else
          local ids = room:getCardsFromPileByRule(".|.|.|.|.|trick|" .. id_neg, 1, "allPiles")
          table.insertTable(cards, ids)
          if #ids < 1 then
            table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|.|" .. id_neg, 1, "allPiles"))
          end
        end
      elseif choice:endsWith("6") then
        local ids = room:getCardsFromPileByRule(".|.|.|.|.|equip|" .. id_neg, 2, "allPiles")
        table.insertTable(cards, ids)
        if #ids < 2 then
          table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|.|" .. id_neg, 2 - #ids, "allPiles"))
        end
      end
    end
    if #cards == 0 then return end
    room:sendLog {
      type = "#qiaosi_log",
      card = cards,
    }
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, qiaosi.name, nil, false, player)
    if player.dead or player:isNude() then return end
    local choices = {"qiaosi_discard"}
    if #room:getOtherPlayers(player, false) > 0 then
      table.insert(choices, "qiaosi_give")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = qiaosi.name,
    })
    if choice == "qiaosi_discard" then
      room:askToDiscard(player, {
        min_num = #cards,
        max_num = #cards,
        include_equip = true,
        skill_name = qiaosi.name,
        cancelable = false,
      })
    else
      local n = math.min(#cards, #player:getCardIds("he"))
      local tos, ids = room:askToChooseCardsAndPlayers(player, {
        min_num = 1,
        max_num = 1,
        min_card_num = n,
        max_card_num = n,
        targets = room:getOtherPlayers(player, false),
        skill_name = qiaosi.name,
        prompt = "#qiaosi-give:::"..n,
        cancelable = false,
      })
      room:moveCardTo(ids, Card.PlayerHand, tos[1], fk.ReasonGive, qiaosi.name, nil, false, player)
    end
  end,
})

qiaosi:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    return { {}, {} }, ai:getBenefitOfEvents(function(logic)
      logic:drawCards(ai.player, 2)
    end)
  end,
})

return qiaosi
