local osZhanyi = fk.CreateSkill {
  name = "os__zhanyi"
}

Fk:loadTranslationTable{
  ["os__zhanyi"] = "战意",
  [":os__zhanyi"] = "出牌阶段限一次，你可弃置一张牌并失去1点体力，根据牌的种类获得以下效果直到出牌阶段结束，" ..
  "基本牌：你可以将一张基本牌当成任意基本牌使用，你使用的第一张基本牌的伤害值或回复值基数+1；锦囊牌：你摸三张牌，" ..
  "你使用的锦囊牌不能被抵消；装备牌：当你使用【杀】指定一名角色为目标后，其弃置两张牌，你选择其中一张获得之。",

  ["#os__zhanyi"] = "战意：弃置一张牌并失去1点体力，根据弃置牌的种类获得效果",
  ["@os__zhanyi-phase"] = "战意",
  ["os__zhanyi_viewas&"] = "战意",
  ["#os__zhanyi-get"] = "战意：获得%dest弃置的一张牌",

  ["$os__zhanyi1"] = "以战养战，视敌而战。",
  ["$os__zhanyi2"] = "战，可以破敌。意，可以守御。",
}

osZhanyi:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#os__zhanyi",
  can_use = function(self, player)
    return player:usedSkillTimes(osZhanyi.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and not player:prohibitDiscard(to_select)
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osZhanyi.name
    local player = effect.from
    local cardType = Fk:getCardById(effect.cards[1]):getTypeString()
    room:throwCard(effect.cards, skillName, player, player)
    if not player:isAlive() then
      return
    end
    room:loseHp(player, 1, skillName)
    if player.dead then return end

    room:setPlayerMark(player, "@os__zhanyi-phase", cardType)
    if cardType == "basic" then
      room:handleAddLoseSkills(player, "os__zhanyi_viewas&", nil, false, true)
      room.logic:getCurrentEvent():findParent(GameEvent.Phase):addCleaner(function()
        room:handleAddLoseSkills(player, "-os__zhanyi_viewas&", nil, false, true)
      end)
    elseif cardType == "trick" then
      player:drawCards(3, skillName)
    end
  end,
})

osZhanyi:addEffect(fk.CardUsing, {
  is_delay_effect = true,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player ~= target or player:getMark("@os__zhanyi-phase") == 0 then
      return false
    end

    if player:getMark("@os__zhanyi-phase") == "basic" then
      return data.card.type == Card.TypeBasic and player:getMark("_os__zhanyi_additional-phase") == 0
    elseif player:getMark("@os__zhanyi-phase") == "trick" then
      return data.card.type == Card.TypeTrick
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@os__zhanyi-phase") == "basic" then
      data.additionalDamage = (data.additionalDamage or 0) + 1
      data.additionalRecover = (data.additionalRecover or 0) + 1
      room:addPlayerMark(player, "_os__zhanyi_additional-phase")
    else
      data.unoffsetableList = table.simpleClone(room.players)
    end
  end,
})

osZhanyi:addEffect(fk.TargetSpecified, {
  is_delay_effect = true,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      player == target and
      player:getMark("@os__zhanyi-phase") == "equip" and
      data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osZhanyi.name
    local room = player.room
    local to = data.to
    local cids = room:askToDiscard(
      to,
      {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = skillName,
        cancelable = false,
      }
    )
    if player.dead then return end
    cids = table.filter(cids, function(id) return room:getCardArea(id) == Card.DiscardPile end)
    if #cids > 0 then
      local cards = room:askToChooseCard(
        player,
        {
          target = to,
          flag = { card_data = { { "pile_discard", cids } } },
          skill_name = skillName,
        }
      )
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, skillName, nil, true, player)
    end
  end,
})

return osZhanyi
