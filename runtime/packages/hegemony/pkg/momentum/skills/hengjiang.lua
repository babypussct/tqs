local hengjiang = fk.CreateSkill{
  name = "hengjiang",
}

Fk:loadTranslationTable{
  ["hengjiang"] = "横江",
  [":hengjiang"] = "当你受到1点伤害后，若当前回合角色手牌上限大于0，你可以令其本回合手牌上限-X（X为其装备区内牌数且至少为1）。" ..
  "然后本回合结束时，若其本回合弃牌阶段内没有弃置过其牌，你将手牌摸至体力上限。",

  ["@hengjiang-turn"] = "横江",

  ["$hengjiang1"] = "霸必奋勇杀敌，一雪夷陵之耻！",
  ["$hengjiang2"] = "江横索寒，阻敌绝境之中！",
}

hengjiang:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hengjiang.name) and
      player.room:getCurrent() and not player.room:getCurrent().dead and player.room:getCurrent():getMaxCards() > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = hengjiang.name,
      prompt = "#hengjiang-invoke::" .. room:getCurrent().id
    }) then
      event:setCostData(self, { tos = { room:getCurrent() } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getCurrent()
    if to ~= nil and not to.dead then
      room:addPlayerMark(to, "@hengjiang-turn", math.max(1, #to:getCardIds("e")))
      room:addPlayerMark(to, MarkEnum.MinusMaxCardsInTurn, math.max(1, #to:getCardIds("e")))
    end
  end
})

hengjiang:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(_, _, target, player, _)
    if player.dead or player:usedSkillTimes(hengjiang.name) == 0 then return false end
    local room = player.room
    local discard_ids = {}
    room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
      if e.data.phase == Player.Discard then
        table.insert(discard_ids, {e.id, e.end_id})
      end
      return false
    end, Player.HistoryTurn)
    if #discard_ids > 0 then
      if #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        local in_discard = false
        for _, ids in ipairs(discard_ids) do
          if #ids == 2 and e.id > ids[1] and e.id < ids[2] then
            in_discard = true
            break
          end
        end
        if in_discard then
          for _, move in ipairs(e.data) do
            if move.from == target and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  return true
                end
              end
            end
          end
        end
        return false
      end, Player.HistoryTurn) > 0 then
        return false
      end
    end
    return true
  end,
  on_use = function(_, _, _, player, _)
    if player:getHandcardNum() < player.maxHp then
      player:drawCards(player.maxHp - player:getHandcardNum() , hengjiang.name)
    end
  end,
})

return hengjiang
