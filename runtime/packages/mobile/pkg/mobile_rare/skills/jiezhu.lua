local jiezhu = fk.CreateSkill {
  name = "jiezhu",
}

Fk:loadTranslationTable{
  ["jiezhu"] = "竭逐",
  [":jiezhu"] = "每回合限一次，你可以将手牌弃置至与你当前手牌数最接近且场上没有的更低值，视为使用一张指定至多X名角色为目标，" ..
  "无距离限制的【杀】（X为弃置牌数）。此【杀】结算结束后，若此【杀】目标数为X且对所有目标造成伤害，" ..
  "你将手牌摸至与你当前手牌数最接近且场上没有的更高值。",

  ["#jiezhu-viewas"] = "竭逐：你可弃置%arg张牌，视为使用可指定%arg个目标且无距离限制的【杀】",

  ["$jiezhu1"] = "趁魏军退走，我等可急令进军。",
  ["$jiezhu2"] = "虽攻敌不足，然退守有余矣。",
}

jiezhu:addEffect("viewas", {
  pattern = "slash",
  prompt = function (self, player)
    local handNumMap = {}
    table.forEach(Fk:currentRoom().alive_players, function(p)
      handNumMap[p:getHandcardNum()] = true
    end)

    local yourHandNum = player:getHandcardNum()
    local lowerSingleNum = yourHandNum - 1
    for i = lowerSingleNum, -1, -1 do
      if not handNumMap[i] then
        lowerSingleNum = i
        break
      end
    end

    return "#jiezhu-viewas:::" .. (yourHandNum - lowerSingleNum)
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "slash",
    subcards = {}
  },
  card_filter = function (self, player, to_select, selected)
    local handNumMap = {}
    table.forEach(Fk:currentRoom().alive_players, function(p)
      handNumMap[p:getHandcardNum()] = true
    end)

    local yourHandNum = player:getHandcardNum()
    local lowerSingleNum = yourHandNum - 1
    for i = lowerSingleNum, -1, -1 do
      if not handNumMap[i] then
        lowerSingleNum = i
        break
      end
    end

    return
      #selected < yourHandNum - lowerSingleNum and
      not player:prohibitDiscard(to_select) and
      Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
  view_as = function (self, player, cards)
    if #cards == 0 then
      return
    end

    local slash = Fk:cloneCard("slash")
    slash:addFakeSubcards(cards)
    slash.skillName = jiezhu.name .. "_tag"
    return slash
  end,
  before_use = function (self, player, use)
    ---@type string
    local skillName = jiezhu.name
    table.removeOne(use.card.skillNames, skillName .. "_tag")
    use.card.skillName = skillName
    use.extra_data = use.extra_data or {}
    use.extra_data.jiezhuUser = player
    use.extra_data.jiezhuNum = #use.card.fake_subcards

    player.room:throwCard(use.card.fake_subcards, skillName, player, player)
  end,
  enabled_at_play = function (self, player)
    local handNumMap = {}
    table.forEach(Fk:currentRoom().alive_players, function(p)
      handNumMap[p:getHandcardNum()] = true
    end)

    local lowerSingleNum = player:getHandcardNum() - 1
    for i = lowerSingleNum, -1, -1 do
      if not handNumMap[i] then
        lowerSingleNum = i
        break
      end
    end

    return player:usedSkillTimes(jiezhu.name) == 0 and lowerSingleNum > -1
  end,
  enabled_at_response = Util.FalseFunc,
})

jiezhu:addEffect("targetmod", {
  extra_target_func = function (self, player, skill, card)
    return
      card and
      table.contains(card.skillNames, jiezhu.name .. "_tag") and
      #card.fake_subcards - 1 or
      0
  end,
  bypass_distances = function (self, player, skill, card)
    return card and table.contains(card.skillNames, jiezhu.name .. "_tag")
  end,
})

jiezhu:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return
      (data.extra_data or {}).jiezhuUser == player and
      data.extra_data.jiezhuNum == #data.tos and
      table.every(data.tos, function(p) return (data.damageDealt or {})[p] ~= nil end)
  end,
  on_use = function (self, event, target, player, data)
    local handNumMap = {}
    table.forEach(Fk:currentRoom().alive_players, function(p)
      handNumMap[p:getHandcardNum()] = true
    end)

    local yourHandNum = player:getHandcardNum()
    local biggerSingleNum = yourHandNum + 1
    for i = biggerSingleNum, 999 do
      if not handNumMap[i] then
        biggerSingleNum = i
        break
      end
    end

    player:drawCards(biggerSingleNum - yourHandNum, jiezhu.name)
  end,
})

return jiezhu
