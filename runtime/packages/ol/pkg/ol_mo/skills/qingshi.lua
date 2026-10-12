local qingshi = fk.CreateSkill {
  name = "qingshic",
}

Fk:loadTranslationTable{
  ["qingshic"] = "倾世",
  [":qingshic"] = "准备阶段，你可以<a href='#RuMoDesc'><font color='red'>入魔</font></a>，令所有角色获得一张单目标伤害牌。" ..
  "当一名角色成为其他角色使用此牌的唯一目标时，你可弃置一张牌，重新指定此牌的目标（无距离限制）。当这些牌：造成伤害后，你摸一张牌；" ..
  "不因使用而进入弃牌堆后，你获得之。准备阶段，若这些牌均离开手牌区，你令所有角色获得一张单目标伤害牌。",

  ["@@qingshic-inhand"] = "倾世",
  ["#qingshic-invoke"] = "倾世：你可入魔，然后令所有角色获得一张单目标伤害牌",
  ["#qingshic-discard"] = "倾世：你可弃一张牌，为 %arg 重新选择目标",
  ["#qingshic-changeTarget"] = "倾世：请为 %arg 重新选择目标",

  ["$qingshic1"] = "血流成河，方不负我倾世的容颜。",
  ["$qingshic2"] = "看你们为我疯魔厮杀，才是这世间最美的风景。",
}

qingshi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Start and
      player:hasSkill(qingshi.name) and
      (
        not player:hasSkill("#rumo", true) or
        not table.find(
          player.room.alive_players,
          function(p)
            return not not table.find(
              p:getCardIds("h"),
              function(id) return Fk:getCardById(id):getMark("@@qingshic-inhand") > 0 end
            )
          end
        )
      )
  end,
  on_cost = function(self, event, target, player, data)
    if not player:hasSkill("#rumo", true) and not player.room:askToSkillInvoke(
        player,
        {
          skill_name = qingshi.name,
          prompt = "#qingshic-invoke",
        }
      ) then
        return false
    end
    event:setCostData(self, {
      tos = player.room:getAlivePlayers(),
      anim_type = player:hasSkill("#rumo", true) and "offensive" or "big"
    })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "#rumo", nil, false, true)

    for _, p in ipairs(event:getCostData(self).tos) do
      if p:isAlive() then
        local damageCards = {}
        for _, id in ipairs(room.draw_pile) do
          local card = Fk:getCardById(id)
          if card.is_damage_card and not card.multiple_targets then
            table.insert(damageCards, id)
          end
        end

        if #damageCards == 0 then
          for _, id in ipairs(room.discard_pile) do
            local card = Fk:getCardById(id)
            if card.is_damage_card and not card.multiple_targets then
              table.insert(damageCards, id)
            end
          end
        end

        if #damageCards == 0 then
          return false
        end

        local randomCard = room:tableRandomPick(damageCards)
        -- room:addTableMarkIfNeed(player, "qingshi-record", randomCard)
        room:obtainCard(p, randomCard, false, fk.ReasonPrey, p, qingshi.name, "@@qingshic-inhand")
      end
    end
  end,
})

qingshi:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      data.use:hasMark("@@qingshic-inhand") and
      data.from ~= player and
      not player:isNude() and
      not data.cancelled and
      #data.use.tos == 1 and
      player:hasSkill(qingshi.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    local sub_tos = data.subTargets
    local extra_data = {}
    for _, p in ipairs(room.alive_players) do
      if not data.from:isProhibited(p, data.card) and
        data.card.skill:modTargetFilter(data.from, p, {}, data.card, extra_data) then
        if sub_tos and #sub_tos > 0 then
          local mod_tos = { p }
          if table.every(sub_tos, function (sub_to)
            if data.card.skill:modTargetFilter(data.from, sub_to, mod_tos, data.card, extra_data) then
              table.insert(mod_tos, sub_to)
              return true
            end
          end) then
            table.insert(tos, p)
          end
        else
          table.insert(tos, p)
        end
      end
    end
    local targets, toDiscard = room:askToChooseCardsAndPlayers(player, {
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = 1,
      targets = tos,
      pattern = ".",
      skill_name = qingshi.name,
      prompt = "#qingshic-discard:::" .. data.card:toLogString(),
      cancelable = true,
      will_throw = true,
    })
    if #targets > 0 and #toDiscard > 0 then
      event:setCostData(self, { tos = targets, cards = toDiscard })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:throwCard(event:getCostData(self).cards, qingshi.name, player, player)
    if data.to ~= to and data:cancelCurrentTarget() then
      data:addTarget(to, nil, true)
    end
  end,
})

qingshi:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    --实测必须实体牌在处理区时才能发动，太没道理故不采用
    return
      data:hasMark("@@qingshic-inhand") and
      data.damageDealt and
      player:hasSkill(qingshi.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, qingshi.name)
  end,
})

qingshi:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qingshi.name) then
      local room = player.room
      local toObtain, toConfirm = {}, {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if info.beforeCard:getMark("@@qingshic-inhand") > 0 then
              if table.contains(room.discard_pile, info.cardId) then
                table.insert(toObtain, info.cardId)
              end
            elseif info.fromArea == Card.Processing then
              if table.contains(room.discard_pile, info.cardId) then
                table.insert(toConfirm, info.cardId)
              end
            end
          end
        end
      end
      if #toConfirm > 0 then
        local start_id = room.logic:getCurrentEvent().id
        room.logic:getEventsByRule(GameEvent.MoveCards, 1, function(e)
          if e.id < start_id then
            for _, move in ipairs(e.data) do
              for _, info in ipairs(move.moveInfo) do
                if table.removeOne(toConfirm, info.cardId) and info.beforeCard:getMark("@@qingshic-inhand") > 0 then
                  table.insert(toObtain, info.cardId)
                end
              end
            end
            return (#toConfirm == 0)
          end
        end, 0)
      end
      toObtain = room.logic:moveCardsHoldingAreaCheck(toObtain)
      if #toObtain > 0 then
        event:setCostData(self, { cards = toObtain })
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, player, fk.ReasonJustMove,
      qingshi.name, nil, true, player)
  end,
})

return qingshi
