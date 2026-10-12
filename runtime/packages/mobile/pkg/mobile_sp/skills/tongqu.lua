local tongqu = fk.CreateSkill {
  name = "tongqu",
}

Fk:loadTranslationTable{
  ["tongqu"] = "通渠",
  [":tongqu"] = "游戏开始时，你获得一枚“渠”标记；准备阶段，你可以失去1点体力令一名没有“渠”标记的角色获得“渠”标记。有“渠”的角色摸牌阶段额外摸一张牌，"..
  "然后将一张牌交给另一名有“渠”的角色或弃置一张牌，若以此法给出的是装备牌则其使用之。有“渠”的角色进入濒死状态时移除其“渠”。",

  ["@@tongqu"] = "通渠",
  ["#tongqu-choose"] = "通渠：你可以失去1点体力，令一名角色获得“渠”标记",
  ["#tongqu-give"] = "通渠：将一张牌交给一名有“渠”的角色，或弃置一张牌",
  ["#tongqu-use"] = "通渠：请使用%arg",

  ["$tongqu1"] = "兴凿修渠，依水屯军！",
  ["$tongqu2"] = "开渠疏道，以备军实！",
}

tongqu:addAuxActiveSkill("#tongqu_active", {
  card_num = 1,
  min_target_num = 0,
  max_target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:getMark("@@tongqu") > 0
  end,
  feasible = function (self, player, selected, selected_cards)
    if #selected_cards == 1 then
      if #selected == 0 then
        return not player:prohibitDiscard(Fk:getCardById(selected_cards[1]))
      elseif #selected == 1 then
        return true
      end
    end
  end,
})

tongqu:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tongqu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@tongqu", 1)
  end,
})

tongqu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(tongqu.name) and
      player.phase == Player.Start and
      table.find(player.room.alive_players, function(p) return p:getMark("@@tongqu") == 0 end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:getMark("@@tongqu") == 0
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = tongqu.name,
      prompt = "#tongqu-choose",
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, tongqu.name)
    room:setPlayerMark(event:getCostData(self).tos[1], "@@tongqu", 1)
  end,
})

tongqu:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@tongqu") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1
  end,
})

tongqu:addEffect(fk.AfterDrawNCards, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@tongqu") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player:isNude() then
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "#tongqu_active",
        prompt = "#tongqu-give",
        cancelable = false,
      })
      dat = dat or { cards = {}, targets = {} }

      if #dat.cards == 0 then
        local canDiscard = table.filter(
          player:getCardIds("he"),
          function(id)
            return not player:prohibitDiscard(Fk:getCardById(id))
          end
        )

        if #canDiscard > 0 then
          dat.cards = room:tableRandomPick(canDiscard, 1)
        elseif #dat.targets == 0 then
          local tongquTargets = table.filter(room.alive_players, function(p) return p:getMark("@@tongqu") > 0 end)
          if #tongquTargets == 0 then
            return false
          end

          dat.targets = room:tableRandomPick(tongquTargets, 1)
          dat.cards = room:tableRandomPick(player:getCardIds("he"), 1)
        end
      end

      if #dat.targets == 1 then
        local to = dat.targets[1]
        local id = dat.cards[1]
        room:obtainCard(to, id, false, fk.ReasonGive, player, tongqu.name)

        if not table.contains(to:getCardIds("h"), id) or to.dead then return end
        local card = Fk:getCardById(id)
        if card.type == Card.TypeEquip and to:canUse(card) then
          if to:canUseTo(card, to) then
            room:useCard({
              from = to,
              tos = {to},
              card = card,
            })
          else
            room:askToUseRealCard(to, {
              pattern = {id},
              skill_name = tongqu.name,
              prompt = "#tongqu-use:::"..card:toLogString(),
              cancelable = false,
            })
          end
        end
      else
        room:throwCard(dat.cards, tongqu.name, player, player)
      end
    end
  end,
})

tongqu:addEffect(fk.EnterDying, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@tongqu") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@tongqu", 0)
  end,
})

return tongqu
