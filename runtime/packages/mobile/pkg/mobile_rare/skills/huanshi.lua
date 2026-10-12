local huanshi = fk.CreateSkill {
  name = "huanshiz",
  tags = { Skill.Quest },
  related_skills = { "jianlv" },
}

Fk:loadTranslationTable{
  ["huanshiz"] = "还施",
  [":huanshiz"] = "使命技，你每回合使用首张【杀】伤害+1；你于非濒死状态时无法使用但可重铸【酒】。<br />" ..
  "成功：当你造成或受到伤害后，若伤害值等于你的体力值，你获得技能〖兼虑〗。",

  ["#huanshiz_active"] = "还施：你可重铸一张【酒】",

  ["$huanshiz1"] = "当效父之胆，拒犯我之贼！",
  ["$huanshiz2"] = "美酒虽好，不可误我政事。",
  ["$huanshiz3"] = "养育之恩虽重，血脉之源难断！",
}

huanshi:addEffect("active", {
  audio_index = 2,
  prompt = "#huanshiz_active",
  card_num = 1,
  target_num = 0,
  can_use = function (self, player)
    return not player.dying
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "analeptic"
  end,
  on_use = function (self, room, effect)
    room:recastCard(effect.cards, effect.from, huanshi.name)
  end,
})

huanshi:addEffect(fk.CardUsing, {
  audio_index = 1,
  can_trigger = function (self, event, target, player, data)
    if not (target == player and data.card.trueName == "slash" and player:hasSkill(huanshi.name)) then
      return false
    end

    local room = player.room
    local firstSlashRecord = player:getMark("huanshiz_record-turn")
    if firstSlashRecord == 0 then
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == player and use.card.trueName == "slash" then
          firstSlashRecord = e.id
          room:setPlayerMark(player, "huanshiz_record-turn", firstSlashRecord)
          return true
        end
      end, Player.HistoryTurn)
    end

    return firstSlashRecord == room.logic:getCurrentEvent().id
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

huanshi:addEffect("prohibit", {
  prohibit_use = function (self, player, card)
    return
      card and
      card.trueName == "analeptic" and
      player:hasSkill(huanshi.name) and
      not player.dying
  end,
})

local huanshiQuestSpec = {
  audio_index = 3,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(huanshi.name) and data.damage == player.hp
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    ---@type string
    local skillName = huanshi.name
    local room = player.room

    if player.general == "zhujic" then
      player.general = "shijic"
      room:broadcastProperty(player, "general")
    elseif player.deputyGeneral == "zhujic" then
      player.deputyGeneral = "shijic"
      room:broadcastProperty(player, "deputyGeneral")
    end

    room:updateQuestSkillState(player, skillName)
    room:invalidateSkill(player, skillName)
    room:handleAddLoseSkills(player, "jianlv")
  end,
}

huanshi:addEffect(fk.Damage, huanshiQuestSpec)

huanshi:addEffect(fk.Damaged, huanshiQuestSpec)

return huanshi
