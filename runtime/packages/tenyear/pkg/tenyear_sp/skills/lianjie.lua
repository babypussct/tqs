local lianjie = fk.CreateSkill {
  name = "lianjie",
}

Fk:loadTranslationTable{
  ["lianjie"] = "连捷",
  [":lianjie"] = "当你使用手牌指定目标后，若此牌点数不大于你的其他手牌，你可以将一名角色手牌中一张点数最小的牌"..
  "置于牌堆底（每回合每名角色限一次），若如此做，你将手牌摸至体力上限，本回合使用以此法摸到的牌无距离次数限制。",

  ["#lianjie-choose"] = "连捷：将一名角色点数最小的手牌置于牌堆底，你摸牌至体力上限",
  ["#lianjie-chooseCard"] = "连捷：请选择其中一张点数最小的手牌置于牌堆底",
  ["@@lianjie-inhand-turn"] = "连捷",

  ["$lianjie1"] = "才战凉州罢，挥帜复河湟。",
  ["$lianjie2"] = "犯大汉天威者，虽远必诛！",
}

lianjie:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianjie.name) and data.firstTarget and
      data.use:isUsingHandcard(player) and not player:isKongcheng() and
      not table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).number < data.card.number
      end) and
      data.card.number > 0 and data.card.number < 14 and
      table.find(player.room.alive_players, function (p)
        return not p:isKongcheng() and not table.contains(player:getTableMark("lianjie-turn"), p.id)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng() and not table.contains(player:getTableMark("lianjie-turn"), p.id)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = lianjie.name,
      prompt = "#lianjie-choose",
      cancelable = true,
    })
    if #to > 0 then
      local card
      if to[1] == player then
        local cards = table.filter(player:getCardIds("h"), function (id)
          return table.every(player:getCardIds("h"), function (id2)
            return Fk:getCardById(id).number <= Fk:getCardById(id2).number
          end)
        end)

        if #cards > 1 then
          card = room:askToCards(
            player,
            {
              min_num = 1,
              max_num = 1,
              pattern = tostring(Exppattern{ id = cards }),
              skill_name = lianjie.name,
              cancelable = false,
              prompt = "#lianjie-chooseCard",
            }
          )[1]
        end
      end

      event:setCostData(self, { tos = to, card = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = event:getCostData(self).card
    room:addTableMark(player, "lianjie-turn", to.id)

    if not card then
      if not to:isAlive() or to:isKongcheng() then
        return false
      end

      card = room:tableRandomPick(table.filter(to:getCardIds("h"), function (id)
        return table.every(to:getCardIds("h"), function (id2)
          return Fk:getCardById(id).number <= Fk:getCardById(id2).number
        end)
      end))
    end

    room:moveCards {
      ids = { card },
      from = to,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = lianjie.name,
      proposer = player,
      moveVisible = true,
      drawPilePosition = -1
    }
    if player.dead then return end
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, lianjie.name, nil, "@@lianjie-inhand-turn")
    end
  end,
})

lianjie:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and #Card:getIdList(data.card) == 1 and
      Fk:getCardById(Card:getIdList(data.card)[1], true):getMark("@@lianjie-inhand-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
  end
})

lianjie:addEffect("targetmod", {
  bypass_times = function(self, player, skill_name, scope, card, to)
    return card and card:getMark("@@lianjie-inhand-turn") > 0
  end,
  bypass_distances = function(self, player, skill_name, card)
    return card and card:getMark("@@lianjie-inhand-turn") > 0
  end,
})

lianjie:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    return ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 0,
      max_num = 1,
      skill_name = self.skill_name,
      benefit_func = function (logic, p)
        logic:moveCardTo(table.random(p:getCardIds("h")), Card.DrawPile, nil, fk.ReasonJustMove)
        local n = ai.player.maxHp - ai.player:getHandcardNum()
        if p == ai.player then
          n = n + 1
        end
        if n > 0 then
          logic:drawCards(ai.player, n)
        end
      end,
    })
  end,
})

return lianjie
