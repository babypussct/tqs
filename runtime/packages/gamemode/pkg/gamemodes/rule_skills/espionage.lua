local rule = fk.CreateSkill {
  name = "#espionage&",
}

Fk:loadTranslationTable{
  ["@@present"] = "<font color='yellow'>赠</font>",
}

rule:addEffect(fk.GamePrepared, {
  global = true,
  can_refresh = function (self, event, target, player, data)
    return player.seat == 1 and not table.contains(player.room.disabled_packs, "espionage_cards")
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, card in ipairs(Fk.packages["espionage_cards"].cards) do
      if card.extra_data and card.extra_data.presentcard == 1 then
        room:setCardMark(card, "@@present", 1)
      end
    end
    for _, p in ipairs(room.alive_players) do
      room:handleAddLoseSkills(p, "present_skill&", nil, false, true)
    end
  end,
})

return rule
