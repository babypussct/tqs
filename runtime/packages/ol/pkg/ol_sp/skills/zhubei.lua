local zhubei = fk.CreateSkill{
  name = "zhubei",
}

Fk:loadTranslationTable{
  ["zhubei"] = "逐北",
  [":zhubei"] = "出牌阶段限两次，你可以选择一名其他角色，令其将至少X张牌当【杀】或【决斗】对你使用（不能选择本阶段以此法选择过的牌名，"..
  "X为所有角色本回合使用基本牌数+1）。若你以此法受到伤害后，你可以获得伤害牌；若你未以此法受到伤害，你回复1点体力，然后可以与其交换手牌。",

  ["#zhubei"] = "逐北：令一名角色将至少%arg张牌当【杀】或【决斗】对你使用",
  ["#zhubei-use"] = "逐北：请将至少%arg张牌当【杀】或【决斗】对 %src 使用",
  ["#zhubei-swap"] = "逐北：是否与 %dest 交换手牌？",
  ["#zhubei_dalay-invoke"] = "逐北：是否获得造成伤害的牌？",
  ["@zhubei-turn"] = "逐北",

  ["$zhubei1"] = "虎踞青兖，欲补薄暮苍天！",
  ["$zhubei2"] = "欲止戈，必先执戈！",
}

zhubei:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player)
    return "#zhubei:::"..player:getMark("@zhubei-turn")
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return (player:getMark("zhubei_slash-phase") == 0 or player:getMark("zhubei_duel-phase") == 0) and
      player:usedSkillTimes(zhubei.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choices = {}
    for _, name in ipairs({"slash", "duel"}) do
      if not table.contains(player:getTableMark("zhubei_names-phase"), name) then
        table.insert(choices, name)
      end
    end
    local use = room:askToUseVirtualCard(target, {
      name = choices,
      skill_name = zhubei.name,
      prompt = "#zhubei-use:"..player.id.."::"..(player:getMark("@zhubei-turn")),
      cancelable = false,
      extra_data = {
        exclusive_targets = {player.id},
        bypass_distances = true,
        bypass_times = true,
      },
      card_filter = {
        n = { player:getMark("@zhubei-turn"), 999 },
      },
      skip = true,
    })
    if use then
      room:addTableMark(player, "zhubei_names-phase", use.card.trueName)
      use.extra_data = use.extra_data or {}
      use.extra_data.zhubei_data = { from = player, to = target }
      room:useCard(use)
    else
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = zhubei.name,
        }
        if player.dead then return end
      end
      if not target.dead and not (player:isKongcheng() and target:isKongcheng()) and
        room:askToSkillInvoke(player, {
          skill_name = zhubei.name,
          prompt = "#zhubei-swap::"..target.id,
        }) then
        room:swapAllCards(player, { player, target }, zhubei.name)
      end
    end
  end,
})

zhubei:addEffect(fk.CardUseFinished, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhubei.name) and not (data.damageDealt and data.damageDealt[player]) and
      data.extra_data and data.extra_data.zhubei_data and data.extra_data.zhubei_data.from == player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = zhubei.name,
      }
      if player.dead then return end
    end
    local to = data.extra_data.zhubei_data.to
    if not to.dead and not (player:isKongcheng() and to:isKongcheng()) and
      room:askToSkillInvoke(player, {
        skill_name = zhubei.name,
        prompt = "#zhubei-swap::"..to.id,
      }) then
      room:swapAllCards(player, { player, to }, zhubei.name)
    end
  end,
})

zhubei:addEffect(fk.Damaged, {
  anim_type = "masochism",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhubei.name) and data.card then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not use_event then return end
      local use = use_event.data
      return use.extra_data and use.extra_data.zhubei_data and use.extra_data.zhubei_data.from == player
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room:getCardArea(data.card) == Card.Processing and room:askToSkillInvoke(player, {
      skill_name = zhubei.name,
      prompt = "#zhubei_dalay-invoke",
    }) then
      room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, zhubei.name, nil, true, player)
    end
  end,
})

zhubei:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return player == target and player:hasSkill(zhubei.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@zhubei-turn", 1)
  end,
})

zhubei:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(zhubei.name) and player.room:getCurrent() == player and data.card.type == Card.TypeBasic
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@zhubei-turn", 1)
  end,
})

zhubei:addAcquireEffect(function(self, player, is_start)
  local room = player.room
  if room:getCurrent() == player then
    room:setPlayerMark(player, "@zhubei-turn", 1)
  end
end)

zhubei:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@zhubei-turn", 0)
  room:setPlayerMark(player, "zhubei_names-phase", 0)
end)

return zhubei
