local herong = fk.CreateSkill {
  name = "herong",
}

Fk:loadTranslationTable{
  ["herong"] = "和戎",
  [":herong"] = "出牌阶段限一次，你可展示一名其他角色的一张手牌，然后你选择一张手牌与其交换，若这两张牌："..
  "1.类型相同，防止你下次受到的伤害，你与其各从牌堆获得一张装备牌；2.类型不同，你弃置其两张牌，然后你对其造成1点伤害。",

  ["#herong"] = "和戎：展示一名角色的一张手牌，然后选择一张手牌与其交换，根据类别是否相同执行效果",
  ["#herong-show"] = "和戎：请选择一张手牌与其交换",
  ["#herong-discard"] = "和戎：弃置 %dest 两张牌并对其造成1点伤害",
  ["@@herong"] = "和戎",

  ["$herong1"] = "君不听我言，欲使阖族尽悬刀否？",
  ["$herong2"] = "我和而来，非为战往。",
}

herong:addEffect("active", {
  anim_type = "control",
  prompt = "#herong",
  card_num = 0,
  target_num = 1,
  max_phase_use_time = 1,
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = herong.name,
    })
    local type = Fk:getCardById(card).type
    target:showCards(card)
    if player:isKongcheng() then return end
    local card2 = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = herong.name,
      prompt = "#herong-show",
      cancelable = false,
    })
    if not table.contains(target:getCardIds("h"), card) then return end
    local yes = type == Fk:getCardById(card2[1]).type
    room:swapCards(player, {
      { player, card2 },
      { target, { card } },
    }, herong.name)
    if yes then
      if not player.dead then
        room:setPlayerMark(player, "@@herong", 1)
        card = room:getCardsFromPileByRule(".|.|.|.|.|equip")
        if #card > 0 then
          room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, herong.name, nil, false, player)
        end
      end
      if not target.dead then
        card = room:getCardsFromPileByRule(".|.|.|.|.|equip")
        if #card > 0 then
          room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonJustMove, herong.name, nil, false, target)
        end
      end
    else
      if player.dead or target.dead then return end
      local cards = room:askToChooseCards(player, {
        min = 2,
        max = 2,
        target = target,
        flag = "he",
        skill_name = herong.name,
        prompt = "#herong-discard::"..target.id,
      })
      if #cards > 0 then
        room:throwCard(cards, herong.name, target, player)
        if target.dead then return end
      end
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = herong.name,
      }
    end
  end,
})

herong:addEffect(fk.DetermineDamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@herong") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@herong", 0)
    data:preventDamage()
  end,
})

return herong
