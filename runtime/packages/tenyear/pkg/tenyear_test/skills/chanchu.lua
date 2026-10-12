
local chanchu = fk.CreateSkill{
  name = "chanchu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chanchu"] = "谗黜",
  [":chanchu"] = "锁定技，你的回合开始时，令所有角色弃置一张手牌并选择支持你或反对你，"..
  "若所有选择反对的角色弃置的牌点数和大于等于所有选择支持的角色弃置的牌点数和，你失去1点体力并获得本回合因此技能弃置的点数最大的牌；"..
  "否则你令至多三名其他角色失去1点体力并随机获得这些角色各一张牌。",

  ["#chanchu-ask"] = "谗黜：请弃置一张手牌，并选择支持或反对 %src",
  ["chanchu_support"] = "支持",
  ["chanchu_against"] = "反对",
  ["#chanchu_result"] = "%from 的谗黜结果：%arg 支持，%arg2 反对",
  ["#chanchu-choose"] = "谗黜：令至多三名其他角色失去1点体力，并随机获得这些角色各一张牌",

  ["$chanchu1"] = "",
  ["$chanchu2"] = "",
}

chanchu:addAuxActiveSkill("#chanchu_active", {
  card_num = 1,
  target_num = 0,
  interaction = UI.OptionBox { options = { "chanchu_support", "chanchu_against" }, direct_send = true },
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
  end,
  refresh_interaction = function (self, player, selected_cards, selected_targets, extra_data)
    if #selected_cards == 1 then
      return { "chanchu_support", "chanchu_against" }
    end
    return {}
  end,
})

chanchu:addEffect(fk.TurnStart, {
  anim_type = "control",
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = player.room:getAlivePlayers() })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng()
    end)

    local req = Request:new(targets, "AskForUseActiveSkill")
    req.focus_text = chanchu.name
    req.focus_players = targets
    local extraData = {
      "#chanchu_active",
      "#chanchu-ask:"..player.id,
      false,
      {},
    }
    for _, p in ipairs(targets) do
      if table.find(p:getCardIds("h"), function (id)
        return not p:prohibitDiscard(id)
      end) then
        extraData[3] = false
      else
        extraData[3] = true
      end
      req:setData(p, extraData)
    end
    req:ask()

    local dat = {}
    for _, p in ipairs(targets) do
      local result = req:getResult(p)
      if result ~= "" then
        dat[p] = {
          cards = result.card.subcards,
          choice = result.interaction_data,
        }
      else
        local cards = table.filter(p:getCardIds("h"), function (id)
          return not p:prohibitDiscard(id)
        end)
        if #cards > 0 then
          dat[p] = {
            cards = room:tableRandomPick(cards, 1),
            choice = "chanchu_support",
          }
        else
          dat[p] = nil
        end
      end
    end

    local moves, cards, support, against = {}, {}, 0, 0
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if dat[p] then
        table.insert(moves, {
          ids = dat[p].cards,
          from = p,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          skillName = chanchu.name,
          moveVisible = true,
          proposer = p,
        })
        table.insert(cards, dat[p].cards[1])
        if dat[p].choice == "chanchu_support" then
          support = support + Fk:getCardById(dat[p].cards[1]).number
        else
          against = against + Fk:getCardById(dat[p].cards[1]).number
        end
      end
    end
    if #moves > 0 then
      room:moveCards(table.unpack(moves))
    end

    room:sendLog{
      type = "#chanchu_result",
      from = player.id,
      arg = support,
      arg2 = against,
      toast = true,
    }
    if player.dead then return end

    if against >= support then
      room:loseHp(player, 1, chanchu.name)
      if player.dead then return end
      local max = 0
      for _, id in ipairs(cards) do
        max = math.max(max, Fk:getCardById(id).number)
      end
      cards = table.filter(cards, function (id)
        return table.contains(room.discard_pile, id) and Fk:getCardById(id).number == max
      end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, chanchu.name, nil, true, player)
      end
    elseif #room:getOtherPlayers(player, false) > 0 then
      targets = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 3,
        targets = room:getOtherPlayers(player, false),
        skill_name = chanchu.name,
        prompt = "#chanchu-choose",
        cancelable = true,
      })
      if #targets == 0 then return end
      room:sortByAction(targets)
      for _, p in ipairs(targets) do
        if not p.dead then
          room:loseHp(p, 1, chanchu.name)
        end
      end
      for _, p in ipairs(targets) do
        if player.dead then return end
        if not p:isNude() then
          cards = room:tableRandomPick(p:getCardIds("he"), 1)
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, chanchu.name, nil, false, player)
        end
      end
    end
  end,
})

return chanchu
