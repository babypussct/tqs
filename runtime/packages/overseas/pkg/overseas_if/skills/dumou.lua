local dumou = fk.CreateSkill {
  name = "os__dumou",
}

Fk:loadTranslationTable {
  ["os__dumou"] = "督鍪",
  [":os__dumou"] = "你每阶段首次获得与失去牌后，你可以选择一项：1.展示牌堆顶的一张牌并令一名角色获得之；" ..
  "2.重铸一名角色三张牌（不足则全部重铸）。每回合结束时，本回合因此获得牌唯一最多的角色失去1点体力。",

  ["#os__dumou-ask"] = "督鍪：你可以选择一项，本回合结束时因此获得牌唯一最多的角色失去1点体力",
  ["os__dumou_show"] = "展示牌堆顶一张牌",
  ["os__dumou_recast"] = "重铸一名角色的三张牌",
  ["#os__dumou_obtain"] = "督鍪：令一名角色获得%arg",
  ["@os__dumou-turn"] = "督鍪",

  ["$os__dumou1"] = "大军浮江百万，今欲亮其锋！",
  ["$os__dumou2"] = "选锋择将，练我东吴雄师！",
}

dumou:addAuxActiveSkill("#os__dumou_active", {
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  interaction = UI.OptionBox { options = { "os__dumou_show", "os__dumou_recast" }, direct_send = true },
  refresh_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    local choices
    if #selected_targets == 0 then
      choices = { "os__dumou_show" }
    elseif not selected_targets[1]:isNude() then
      choices = { "os__dumou_recast" }
    end
    return choices
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards, card, extra_data)
    return #selected == 0 and not to_select:isNude()
  end,
})

dumou:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(dumou.name) and
      player:usedSkillTimes(dumou.name, Player.HistoryPhase) == 0 and
      player:getMark("os__dumou-phase") == 0 then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) then
              player.room:setPlayerMark(player, "os__dumou-phase", 1)
              return true
            end
          end
        end
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              player.room:setPlayerMark(player, "os__dumou-phase", 1)
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#os__dumou_active",
      prompt = "#os__dumou-ask",
    })
    if success and dat then
      event:setCostData(self, { choice = dat.interaction, tos = dat.targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self)
    local choice, to = dat.choice, dat.tos[1]
    if choice == "os__dumou_show" then
      local cards = room:getNCards(1)
      room:turnOverCardsFromDrawPile(player, cards, dumou.name)
      if not player:isAlive() then return end
      to = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        cancelable = false,
        skill_name = dumou.name,
        prompt = "#os__dumou_obtain:::" .. Fk:getCardById(cards[1]):toLogString()
      })[1]
      room:obtainCard(to, cards, true, fk.ReasonPrey, player, dumou.name)
      if not to.dead then
        room:addPlayerMark(to, "@os__dumou-turn", 1)
      end
    else
      local cards = room:askToChooseCards(player, {
        target = to,
        min = 3,
        max = 3,
        skill_name = dumou.name,
        flag = "he",
      })
      cards = room:recastCard(cards, to, dumou.name)
      if not to.dead then
        room:addPlayerMark(to, "@os__dumou-turn", #cards)
      end
    end
  end,
})

dumou:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(dumou.name) then return end
    local n = 0
    local max
    for _, p in ipairs(player.room.alive_players) do
      local record = p:getMark("@os__dumou-turn")
      if record > n then
        n = record
        max = p
      elseif record == n then
        max = nil
      end
    end
    if max then
      event:setCostData(self, { tos = { max } })
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player.room:loseHp(to, 1, dumou.name)
  end,
})

return dumou
