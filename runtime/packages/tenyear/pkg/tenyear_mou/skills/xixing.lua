local xixing = fk.CreateSkill {
  name = "xixing",
}

Fk:loadTranslationTable{
  ["xixing"] = "悉性",
  [":xixing"] = "出牌阶段限一次，你可以观看一名其他角色的手牌并获得其中一张牌，然后若你使用的下一张牌对其造成伤害，此技能视为未发动过。",

  ["#xixing"] = "悉性：观看一名角色的手牌并获得其中一张牌",
  ["#xixing-prey"] = "悉性：获得 %dest 一张牌",

  ["$xixing1"] = "正受性无术，恐不明本末。",
  ["$xixing2"] = "左将军英才盖世，可为良禽栖木。",
}

xixing:addEffect("active", {
  anim_type = "control",
  max_phase_use_time = 1,
  prompt = "#xixing",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xixing.name, Player.HistoryPhase) == 0
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
      flag = { card_data = {{ target.general, target:getCardIds("h") }} },
      skill_name = xixing.name,
      prompt = "#xixing-prey::"..target.id,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, xixing.name, nil, false, player)
    if player.dead or target.dead then return end
    room:setPlayerMark(player, "xixing-phase", target)
  end,
})

xixing:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("xixing-phase") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.xixing = {player, player:getMark("xixing-phase")}
    player.room:setPlayerMark(player, "xixing-phase", 0)
  end,
})

xixing:addEffect(fk.CardUseFinished, {
  can_refresh = function (self, event, target, player, data)
    return data.damageDealt and data.extra_data and data.extra_data.xixing and
      data.extra_data.xixing[1] == player and data.damageDealt[data.extra_data.xixing[2]]
  end,
  on_refresh = function (self, event, target, player, data)
    player:setSkillUseHistory(xixing.name, 0, Player.HistoryPhase)
  end,
})

return xixing
