local xiongtus = fk.CreateSkill {
  name = "xiongtus",
}

Fk:loadTranslationTable{
  ["xiongtus"] = "凶图",
  [":xiongtus"] = "出牌阶段限一次，你可以展示一名其他角色的一张手牌并选择一项：1.弃置此牌；2.弃置X张牌并对其造成1点伤害" ..
  "（X为本回合未进入过弃牌堆的花色数）。若如此做，本回合此后当你不因此技能造成伤害后，你摸一张牌，且此技能本阶段改为限两次。",

  ["#xiongtus"] = "凶图：展示一名角色一张手牌，你选择弃置此牌，或弃牌并对其造成伤害",
  ["#xiongtus-damage"] = "凶图：点“确定”对 %dest 造成1点伤害，或点“取消”弃置其展示的牌",
  ["#xiongtus-discard"] = "凶图：弃置%arg张牌对 %dest 造成1点伤害，或点“取消”弃置其展示的牌",
  ["@@xiongtus_buff-turn"] = "凶图",

  ["$xiongtus1"] = "明日置酒设宴，还望使君勿辞。",
  ["$xiongtus2"] = "使君病未善平，有常服药酒，可取之。",
  ["$xiongtus3"] = "诸葛恪跋扈自恣，峻请为陛下除之。",
  ["$xiongtus4"] = "诸葛恪民心尽失，此实为大好之机。",
}

xiongtus:addEffect("active", {
  audio_index = { 1, 2 },
  anim_type = "offensive",
  prompt = "#xiongtus",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local limitation = player:getMark("xiongtus_extra-phase") == 0 and 1 or 2
    return player:usedSkillTimes(xiongtus.name, Player.HistoryPhase) < limitation
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = xiongtus.name
    local player = effect.from
    local target = effect.tos[1]
    local card = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = skillName,
    })
    target:showCards(card)

    if player.dead or target.dead then return end
    local suits = { Card.Spade, Card.Heart, Card.Diamond, Card.Club }
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(suits, Fk:getCardById(info.cardId).suit)
            return #suits == 0
          end
        end
      end
    end, Player.HistoryTurn)

    local toThrow = true
    if #suits == 0 then
      toThrow = not room:askToSkillInvoke(
        player,
        {
          skill_name = skillName,
          prompt = "#xiongtus-damage::" .. target.id,
        }
      )
    elseif #player:getCardIds("he") >= #suits then
      toThrow = #room:askToDiscard(
        player,
        {
          min_num = #suits,
          max_num = #suits,
          include_equip = true,
          skill_name = skillName,
          prompt = "#xiongtus-discard::" .. target.id .. ":" .. #suits,
          cancelable = true,
        }
      ) == 0
    end

    if toThrow then
      if table.contains(target:getCardIds("h"), card) then
        room:throwCard(card, skillName, target, player)
      end
    elseif not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skillName,
      }
    end

    if not player:isAlive() then
      return false
    end

    room:setPlayerMark(player, "@@xiongtus_buff-turn", 1)
  end,
})

xiongtus:addEffect(fk.Damage, {
  audio_index = { 3, 4 },
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      data.skillName ~= xiongtus.name and
      player:getMark("@@xiongtus_buff-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, xiongtus.name)
    if player:isAlive() then
      player.room:setPlayerMark(player, "xiongtus_extra-phase", 1)
    end
  end,
})

return xiongtus
