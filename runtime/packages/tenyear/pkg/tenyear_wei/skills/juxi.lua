local juxi = fk.CreateSkill {
  name = "juxi",
}

Fk:loadTranslationTable{
  ["juxi"] = "举袭",
  [":juxi"] = "出牌阶段限一次，若你手牌中无可使用的伤害牌，你可视为使用一张本回合未以此法使用过的伤害牌，"..
    "若本阶段此牌名进入弃牌堆，此技能视为未发动。",

  ["#juxi"] = "举袭：视为使用任意伤害牌，同名牌进入弃牌堆后，可再次发动此技能",

  ["$juxi1"] = "雪吞箭囊空，犹挽虚弦射苍穹！",
  ["$juxi2"] = "英雄怎可，徒手而亡！",
}

juxi:addAcquireEffect(function(self, player, is_start)
  local names = {}
  for _, name in ipairs(Fk:getAllCardNames("bt")) do
    local card = Fk.all_card_types[name]
    if card.is_damage_card then
      table.insertIfNeed(names, card.name)
    end
  end
  player.room:setPlayerMark(player, juxi.name, names)
end)

juxi:addLoseEffect(function(self, player, is_death)
  local room = player.room
  room:addTableMark(player, juxi.name, 0)
  room:addTableMark(player, "juxi-turn", 0)
  room:setPlayerMark(player, "juxi-phase", 0)
end)

juxi:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#juxi",
  pattern = ".",
  max_phase_use_time = 1,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  interaction_helper = function(self, player)
    local all_names = player:getMark(juxi.name)
    local names = player:getViewAsCardNames(juxi.name, all_names, {}, player:getTableMark("juxi-turn"))
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if Fk.all_card_types[self.interaction.data] == nil then return nil end
    return Fk:cloneCard(self.interaction.data, nil, nil, juxi.name)
  end,
  before_use = function(self, player, use)
    local room = player.room
    local name = use.card.trueName
    if name == "slash" then
      use.extraUse = true
    end
    room:addTableMark(player, "juxi-turn", name)
    room:setPlayerMark(player, "juxi-phase", name)
  end,
  enabled_at_play = function(self, player)
    return player:usedEffectTimes(juxi.name, Player.HistoryPhase) < 1 and
      table.every(player:getCardIds("h"), function(id)
        local card = Fk:getCardById(id)
        return not card.is_damage_card or #card:getAvailableTargets(player) == 0
      end)
  end,
  enabled_at_response = Util.FalseFunc,
})

juxi:addEffect(fk.AfterCardsMove, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(juxi.name, true) then
      local name = player:getMark("juxi-phase")
      if name ~= 0 then
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId, true).trueName == name then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:setSkillUseHistory(juxi.name, 0, Player.HistoryPhase)
    player.room:setPlayerMark(player, "juxi-phase", 0)
  end,
})

juxi:addEffect("targetmod", {
  bypass_times = function(self, player, skillName, scope, card)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, juxi.name)
  end,
})

return juxi
