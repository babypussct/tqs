local juetu = fk.CreateSkill{
  name = "juetu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["juetu"] = "绝途",
  [":juetu"] = "锁定技，弃牌阶段开始时，若你有手牌，你改为保留每种花色的手牌各一张，将其余手牌置入弃牌堆。然后你令一名角色弃置一张手牌，"..
  "若你手牌中没有此花色的牌，你对其造成1点伤害。",

  ["#juetu-invoke"] = "绝途：保留每种花色的手牌各一张，其余手牌置入弃牌堆",
  ["#juetu-choose"] = "绝途：令一名角色弃置一张手牌，若你手牌中无此花色的牌则对其造成伤害",
  ["#juetu-discard"] = "绝途：弃置一张手牌，若 %src 手牌无此花色则对你造成伤害",

  ["$juetu1"] = "此天子銮驾，尔可有异心耶？",
  ["$juetu2"] = "断途绝路，莫使凉州人追来。",
}

juetu:addAuxActiveSkill("juetu_active", {
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if table.contains(player:getCardIds("h"), to_select) and
      Fk:getCardById(to_select).suit ~= Card.NoSuit then
      if #selected == 0 then
        return true
      else
        return table.every(selected, function(id)
          return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(id), true)
        end)
      end
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    local suits = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    table.removeOne(suits, Card.NoSuit)
    return #selected_cards == #suits
  end,
})

juetu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(juetu.name) and
      player.phase == Player.Discard and
      not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    if table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).suit == Card.NoSuit or
      table.find(player:getCardIds("h"), function (id2)
        return Fk:getCardById(id):compareSuitWith(Fk:getCardById(id2))
      end) ~= nil
    end) then
      local success, dat = player.room:askToUseActiveSkill(player, {
        skill_name = "juetu_active",
        prompt = "#juetu-invoke",
        cancelable = false,
      })
      if not (success and dat) then
        dat = {}
        dat.cards = {}
        for _, id in ipairs(player:getCardIds("h")) do
          if Fk:getCardById(id).suit ~= Card.NoSuit and
            not table.find(dat.cards, function (id2)
              return Fk:getCardById(id):compareSuitWith(Fk:getCardById(id2))
            end) then
            table.insert(dat.cards, id)
          end
        end
      end
      local cards = table.filter(player:getCardIds("h"), function (id)
        return not table.contains(dat.cards, id)
      end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, juetu.name, nil, true, player)
        if player.dead then return end
      end
    end
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng()
    end)
    if not table.find(player:getCardIds("h"), function (id)
        return not player:prohibitDiscard(id)
      end) then
      table.removeOne(targets, player)
    end
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = juetu.name,
      prompt = "#juetu-choose",
      cancelable = false,
    })[1]
    local card = room:askToDiscard(to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = juetu.name,
      prompt = "#juetu-discard:"..player.id,
      cancelable = false,
      skip = true,
    })
    if #card == 0 then return end
    local suitRecord = Fk:getCardById(card[1]).suit
    room:throwCard(card, juetu.name, to, to)

    if
      (
        suitRecord == Card.NoSuit or
        not table.find(player:getCardIds("h"), function (id)
          return Fk:getCardById(id).suit == suitRecord
        end)
      ) and
      to:isAlive()
    then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = juetu.name,
      }
    end
  end,
})

return juetu
