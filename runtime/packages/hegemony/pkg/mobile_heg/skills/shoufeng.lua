
local shoufeng = fk.CreateSkill{
  name = "m_heg__shoufeng",
}

Fk:loadTranslationTable{
  ["m_heg__shoufeng"] = "授锋",
  [":m_heg__shoufeng"] = "一名角色于其出牌阶段使用首张伤害牌结算后，你可以交给其一张牌，然后获得此伤害牌。",

  ["#m_heg__shoufeng-invoke"] = "授锋：你可以交给 %dest 一张牌，获得此%arg",

  ["$m_heg__shoufeng1"] = "袁门士族魁冠，自居天下之首！",
  ["$m_heg__shoufeng2"] = "四世三公之名，足令群雄称服！",
  ["$m_heg__shoufeng3"] = "天下有识之士，皆我袁门故人！",
  ["$m_heg__shoufeng4"] = "袁门一剑出，必使天下自定！",
}

shoufeng:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(shoufeng.name) and
      data.card.is_damage_card and target.phase == Player.Play and
      player:usedSkillTimes(shoufeng.name, Player.HistoryTurn) == 0 and
      not target.dead and not player:isNude() then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == target and e.data.card.is_damage_card
      end, Player.HistoryPhase)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      prompt = "#m_heg__shoufeng-invoke::" .. target.id ..":"..data.card:toLogString(),
      skill_name = shoufeng.name,
      cancelable = true,
    })
    if #card > 0 then
      event:setCostData(self, { tos = { target }, cards = card })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if target ~= player then
      room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, target, fk.ReasonGive, shoufeng.name, nil, false, player)
    end
    if not player.dead and room:getCardArea(data.card) == Card.Processing then
      room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, shoufeng.name, nil, false, player)
    end
  end,
})

return shoufeng
