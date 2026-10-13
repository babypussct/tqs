local skill = fk.CreateSkill {
  name = "borrow_arrows_skill",
}

Fk:loadTranslationTable{
  ["borrow_arrows_skill"] = "草船借箭",
  ["#borrow_arrows-use"] = "%src 对你使用%arg，是否使用一张【草船借箭】抵消？",
}

skill:addEffect("cardskill", {
  can_use = Util.FalseFunc,
  on_effect = function(self, room, effect)
    if effect.responseToEvent then
      effect.responseToEvent.isCancellOut = true
      effect.responseToEvent.extra_data = effect.responseToEvent.extra_data or {}
      effect.responseToEvent.extra_data.borrow_arrows = effect.from
    end
  end,
})

local spec = {
  global = true,
  priority = 0,
  can_trigger = function (self, event, target, player, data)
    if data.to == player and
      ((event == fk.PreCardEffect and data.card.trueName == "slash") or
      (event == fk.BeforeCardEffect and data.card.type == Card.TypeTrick and data.card.is_damage_card)) and
      not data.isCancellOut and not data:isNullified() and
      not data:isUnoffsetable(player) and not data:isDisresponsive(player) then
      if table.find(player:getHandlyIds(), function (id)
        return Fk:getCardById(id).name == "borrow_arrows"
      end) then
        return true
      end
      for _, s in ipairs(table.connect(player.player_skills, rawget(player, "_fake_skills"))) do
        ---@cast s ViewAsSkill
        if s.pattern and Exppattern:Parse("borrow_arrows"):matchExp(s.pattern) and
          (not table.contains(player.room.disabled_packs, "certamen_cards") or string.find(s.pattern, "borrow_arrows")) and
          s:enabledAtResponse(player)
        then
          return true
        end
      end
    end
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    room:addSkill(skill.name)
    local use = room:askToUseCard(player, {
      pattern = "borrow_arrows",
      skill_name = "",
      prompt = "#borrow_arrows-use:"..data.from.id.."::"..data.card:toLogString(),
      cancelable = true,
      event_data = data,
    })
    if use then
      room:useCard(use)
    end
  end,
}

--闪前
skill:addEffect(fk.PreCardEffect, spec)

--无懈后
skill:addEffect(fk.BeforeCardEffect, spec)

skill:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if player.room:getCardArea(data.card) == Card.Processing and not player.dead then
      local to
      player.room.logic:getCurrentEvent():searchEvents(GameEvent.CardEffect, 1, function (e)
        local effect = e.data
        if effect.extra_data then
          to = effect.extra_data.borrow_arrows
          return to and not to.dead
        end
      end)
      if to == player then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, skill.name, nil, true, player)
  end,
})

return skill
