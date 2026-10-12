local jiannan = fk.CreateSkill{
  name = "jiannan",
}

Fk:loadTranslationTable{
  ["jiannan"] = "间难",
  [":jiannan"] = "出牌阶段开始时，你可以摸两张牌。若如此做，此阶段一名角色失去所有“间难”牌或最后的手牌后，若没有角色处于濒死状态，"..
  "你令一名角色执行一项：1.弃置两张牌；2.摸两张牌；3.重铸所有装备牌；4.将一张锦囊牌置于牌堆顶或失去1点体力。每回合每个选项限一次。",

  ["@jiannan-turn"] = "间难",
  ["@@jiannan-inhand-phase"] = "间难",
  ["jiannan_active"] = "间难",
  ["#jiannan-choose"] = "间难：令一名角色执行一项",
  ["jiannan1"] = "弃置两张牌",
  ["jiannan2"] = "摸两张牌",
  ["jiannan3"] = "重铸所有装备牌",
  ["jiannan4"] = "放置锦囊牌或失去体力",
  ["#jiannan-put"] = "间难：请将一张锦囊牌置于牌堆顶，否则失去1点体力",

  ["$jiannan1"] = "上既临危遘难，臣当尽节卫主。",
  ["$jiannan2"] = "事君不避难，凛身危困间。",
}

jiannan:addAuxActiveSkill("jiannan_active", {
  interaction = function(self, player)
    local choices, all_choices = {}, {}
    for i = 1, 4 do
      table.insert(all_choices, "jiannan".. i)
      if not table.contains(player:getTableMark("jiannan-turn"), i) then
        table.insert(choices, "jiannan".. i)
      end
    end
    return UI.OptionBox { options = choices, all_options = all_choices, direct_send = true }
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
})

jiannan:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jiannan.name) and player.phase == Player.Play
  end,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@jiannan-turn")
    player:drawCards(2, jiannan.name, nil, "@@jiannan-inhand-phase")
  end,
})

jiannan:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(jiannan.name) and player:usedSkillTimes(jiannan.name, Player.HistoryPhase) > 0 and
      #player:getTableMark("jiannan-turn") < 4 and
      not table.find(player.room.alive_players, function (p)
        return p.dying
      end) then
      for _, move in ipairs(data) do
        if move.from then
          if move.from:isKongcheng() then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                return true
              end
            end
          elseif not table.find(move.from:getCardIds("h"), function(id)
            return Fk:getCardById(id, true):getMark("@@jiannan-inhand-phase") > 0
          end) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand and info.beforeCard:getMark("@@jiannan-inhand-phase") > 0 then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "jiannan_active",
      prompt = "#jiannan-choose",
      cancelable = false,
    })
    if not (success and dat) then
      dat = {}
      dat.targets = {player}
      dat.interaction = table.filter({1, 2, 3, 4}, function (i)
        return not table.contains(player:getTableMark("jiannan-turn"), i)
      end)
    end
    room:doIndicate(player, dat.targets)
    room:addPlayerMark(player, "@jiannan-turn")
    local to = dat.targets[1]
    local choice = tonumber(dat.interaction[8])
    room:addTableMark(player, "jiannan-turn", choice)
    if choice == 1 then
      room:askToDiscard(to, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = jiannan.name,
        cancelable = false,
      })
    elseif choice == 2 then
      to:drawCards(2, jiannan.name, nil, "@@jiannan-inhand-phase")
    elseif choice == 3 then
      local cards = table.filter(to:getCardIds("he"), function (id)
        return Fk:getCardById(id).type == Card.TypeEquip
      end)
      if #cards > 0 then
        room:recastCard(cards, to, jiannan.name, "@@jiannan-inhand-phase")
      end
    elseif choice == 4 then
      local card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = jiannan.name,
        pattern = ".|.|.|.|.|trick",
        prompt = "#jiannan-put",
        cancelable = true,
      })
      if #card > 0 then
        room:moveCards({
          ids = card,
          from = to,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = jiannan.name,
          moveVisible = true,
          drawPilePosition = 1,
        })
      else
        room:loseHp(to, 1, jiannan.name)
      end
    end
  end,
})

return jiannan
