local qianfux = fk.CreateSkill{
  name = "ol__qianfux",
  tags = { Skill.Switch },
  max_branches_use_time = {
    ["yang"] = {
      [Player.HistoryPhase] = 1
    },
    ["yin"] = {
      [Player.HistoryPhase] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["ol__qianfux"] = "迁附",
  [":ol__qianfux"] = "转换技，出牌阶段各限一次，阳：你可以将一张黑色牌当【过河拆桥】使用；阴，你可以将一张红色牌当【火攻】使用。"..
  "结算结束后，你可以将因此弃置的牌置于牌堆顶。",
}

qianfux:addEffect("viewas", {
  anim_type = "switch",
  pattern = "snatch,dismantlement",
  prompt = function(self, player)
    return "#qianfux-"..player:getSwitchSkillState(qianfux.name, false, true)
  end,
  handly_pile = true,
  filter_pattern = function (self, player, card_name)
    return {
      max_num = 1,
      min_num = 1,
      pattern = (player:getSwitchSkillState(qianfux.name, false) == fk.SwitchYang) and ".|.|black" or ".|.|red",
    }
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card
    if player:getSwitchSkillState(qianfux.name, false) == fk.SwitchYang then
      card = Fk:cloneCard("dismantlement")
    else
      card = Fk:cloneCard("fire_attack")
    end
    card.skillName = qianfux.name
    card:addSubcard(cards[1])
    return card
  end,
  history_branch = function(self, player, data)
    return player:getSwitchSkillState(qianfux.name, nil, true)
  end,
  after_use = function (self, player, use)
    if player.dead then return end
    local room = player.room
    local cards = {}
    local effect_event = room.logic:getEventsByRule(GameEvent.CardEffect, 1, function (e)
      return e.data.card == use.card
    end, nil, Player.HistoryPhase)
    if effect_event then
      effect_event[1]:searchEvents(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(room.discard_pile, info.cardId) then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end)
    end
    if #cards > 0 and room:askToSkillInvoke(player, {
      skill_name = qianfux.name,
      prompt = "#qianfux-invoke",
    }) then
      room:moveCards({
        ids = cards,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = qianfux.name,
      })
    end
  end,
  enabled_at_play = function (self, player)
    return player.phase == Player.Play and qianfux:withinBranchTimesLimit(player, player:getSwitchSkillState(qianfux.name, nil, true), Player.HistoryPhase)
  end,
  enabled_at_response = Util.FalseFunc,
}, { check_skill_limit = true })

qianfux:addEffect(fk.AfterCardsMove, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(qianfux.name, true) and player:isKongcheng()) then return end
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-ol__qianfux")
  end,
})

return qianfux
