local yuzhic = fk.CreateSkill {
  name = "yuzhic",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yuzhic"] = "逾制",
  [":yuzhic"] = "锁定技，当你成为【杀】的目标时，你需选择一项：1.弃置一张装备区内的牌，视为使用【闪】，失去此选项至你的回合开始；2.此【杀】伤害+1。",

  ["#yuzhic-discard"] = "逾制：弃置一张装备视为使用【闪】，否则此【杀】伤害+1",

  ["$yuzhic1"] = "父王息怒！拙姎实不知上律！",
  ["$yuzhic2"] = "妾性尚简，今日所衣非常衣！",
}

yuzhic:addEffect(fk.TargetConfirming, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuzhic.name) and
      data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(yuzhic.name) > 0 or #player:getCardIds("e") == 0 then
      data.use.additionalDamage = (data.use.additionalDamage or 0) + 1
    else
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = yuzhic.name,
        pattern = ".|.|.|equip",
        prompt = "#yuzhic-discard",
        cancelable = true,
      })
      if #card > 0 then
        room:setPlayerMark(player, yuzhic.name, 1)
        room:throwCard(card, yuzhic.name, player, player)
        data.currentExtraData = data.currentExtraData or {}
        data.currentExtraData.yuzhic = true
      else
        data.use.additionalDamage = (data.use.additionalDamage or 0) + 1
      end
    end
  end,
})

yuzhic:addEffect(fk.AskForCardUse, {
  priority = 1.1,
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none") and
      not player:prohibitUse(Fk:cloneCard("jink")) and 
      (data.extraData == {} or data.extraData.not_passive ~= true)
      and data.eventData and
      data.eventData.card and
      data.eventData.card.trueName == "slash" and
      (data.eventData.currentExtraData or {}).yuzhic
  end,
  on_use = function (self, event, target, player, data)
    local new_card = Fk:cloneCard("jink")
    new_card.skillName = yuzhic.name
    local result = {
      from = player,
      card = new_card,
      tos = {},
    }
    data.result = result
    return true
  end,
})

yuzhic:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, yuzhic.name, 0)
  end
})

return yuzhic
