local zhenliang = fk.CreateSkill {
  name = "ol__zhenliang",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["ol__zhenliang"] = "贞良",
  [":ol__zhenliang"] = "转换技，"..
  "阳：出牌阶段限一次，你可以选择攻击范围内的一名其他角色，弃置一张与“任”颜色相同的牌，对其造成1点伤害；" ..
  "阴：当你于回合外使用或打出的牌进入弃牌堆时，若此牌与“任”颜色相同，你可以令一名角色摸一张牌。",

  [":ol__zhenliang_yang"] = "转换技，"..
  "<font color=\"#E0DB2F\">阳：出牌阶段限一次，你可以选择攻击范围内的一名其他角色，弃置一张与“任”颜色相同的牌，对其造成1点伤害；</font>" ..
  "阴：当你于回合外使用或打出的牌进入弃牌堆时，若此牌与“任”颜色相同，你可以令一名角色摸一张牌。",
  [":ol__zhenliang_yin"] = "转换技，阳：出牌阶段限一次，你可以选择攻击范围内的一名其他角色，弃置一张与“任”颜色相同的牌，对其造成1点伤害；" ..
  "<font color=\"#E0DB2F\">阴：当你于回合外使用或打出的牌进入弃牌堆时，若此牌与“任”颜色相同，你可以令一名角色摸一张牌。</font>",

  ["#ol__zhenliang"] = "贞良：弃一张“任”颜色的牌，对攻击范围内的一名角色造成1点伤害",
  ["#ol__zhenliang-choose"] = "贞良：你可以令一名角色摸一张牌",

  ["$ol__zhenliang1"] = "董贼狼子野心，进京必为后患。",
  ["$ol__zhenliang2"] = "废长立幼，岂是吾等臣子可为？",
}

zhenliang:addEffect("active", {
  prompt = "#ol__zhenliang",
  anim_type = "switch",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedEffectTimes(zhenliang.name, Player.HistoryPhase) == 0 and
      player:getSwitchSkillState(zhenliang.name) == fk.SwitchYang and
      #player:getPile("ol__luzhi_duty") > 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select) and
      table.find(player:getPile("ol__luzhi_duty"), function (id)
        return Fk:getCardById(to_select):compareColorWith(Fk:getCardById(id))
      end)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and player:inMyAttackRange(to_select, nil, selected_cards)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, zhenliang.name, player, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = zhenliang.name,
      }
    end
  end,
})

zhenliang:addEffect(fk.AfterCardsMove, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhenliang.name) and player.room:getCurrent() ~= player and
      player:getSwitchSkillState(zhenliang.name) == fk.SwitchYin and
      #player:getPile("ol__luzhi_duty") > 0 then
      for _, move in ipairs(data) do
        if move.from == nil and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResponse) then
          local move_event = player.room.logic:getCurrentEvent()
          local use_event = move_event.parent
          if use_event ~= nil and (use_event.event == GameEvent.UseCard or use_event.event == GameEvent.RespondCard) then
            local use = use_event.data
            if use.from == player then
              for _, info in ipairs(move.moveInfo) do
                if table.contains(Card:getIdList(use.card), info.cardId) and
                  table.contains(player.room.discard_pile, info.cardId) and
                  table.find(player:getPile("ol__luzhi_duty"), function (id)
                    return Fk:getCardById(info.cardId):compareColorWith(Fk:getCardById(id))
                  end) then
                  return true
                end
              end
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = zhenliang.name,
      prompt = "#ol__zhenliang-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(1, zhenliang.name)
  end,
})

local AI = Fk.Ltk.AI
zhenliang:addAI(AI.reuse("zuoding", AI.ChoosePlayersStrategy))

return zhenliang
