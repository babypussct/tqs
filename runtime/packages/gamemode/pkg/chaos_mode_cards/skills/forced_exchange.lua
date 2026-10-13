local skill = fk.CreateSkill {
  name = "forced_exchange_skill",
}

local function addGrain(room, player, num)
  room:addPlayerMark(player, "@!!chaos_grain-noclear", num)
  room:sendLog{
    type = "#chaos_grain_gain",
    from = player.id,
    arg = num,
    arg2 = "@!!chaos_grain-noclear",
    arg3 = player:getMark("@!!chaos_grain-noclear"),
  }
end

local function removeGrain(room, player, num)
  room:removePlayerMark(player, "@!!chaos_grain-noclear", num)
  room:sendLog{
    type = "#chaos_grain_lose",
    from = player.id,
    arg = num,
    arg2 = "@!!chaos_grain-noclear",
    arg3 = player:getMark("@!!chaos_grain-noclear"),
  }
end

skill:addEffect("cardskill", {
  prompt = "#forced_exchange_skill",
  target_num = 1,
  mod_target_filter = function(self, _, to_select, _, _, _)
    return not to_select:isKongcheng()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if from:getMark("@!!chaos_grain-noclear") < 2 then return end
    removeGrain(room, from, 2)
    addGrain(room, to, 2)
    local card_data = {}
    if not to:isKongcheng() and to ~= from then
      table.insert(card_data, { "$Hand", to.player_cards[Player.Hand] })
    end
    if #to.player_cards[Player.Equip] > 0 then
      table.insert(card_data, { "$Equip", to.player_cards[Player.Equip] })
    end
    if #card_data == 0 then return end
    local id = room:askToChooseCard(from, { target = to, flag = { card_data = card_data }, skill_name = skill.name })
    room:obtainCard(from, id, false, fk.ReasonPrey, from, skill.name)
  end,
})

return skill
