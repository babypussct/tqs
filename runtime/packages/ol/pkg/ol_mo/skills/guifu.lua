local guifu = fk.CreateSkill{
  name = "guifu",
}

Fk:loadTranslationTable{
  ["guifu"] = "诡伏",
  [":guifu"] = "每轮开始时或你体力值变化后，你获得一张不计入手牌上限的【闪】。当技能或牌造成伤害后，你记录此技能或牌名。"..
    "你可以将因此技能获得的【闪】当记录的牌名使用（不计入次数限制，每回合每种牌名限一次）。",

  ["#guifu"] = "诡伏：将一张“诡伏”【闪】当一种记录的牌使用",
  ["@@guifu-inhand"] = "诡伏",
  ["@[guifu]"] = "诡伏",
  ["guifu_mark_string"] = "%d技%d牌",

  ["$guifu1"] = "天命在我，何须急于一时。",
  ["$guifu2"] = "天数已定，如渊潜龙！",
}

guifu:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#guifu",
  pattern = ".",
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("@@guifu-inhand") > 0
  end,
  interaction_helper = function(self, player, selected_cards)
    local all_names = player:getTableMark("guifu_card_record")
    local names = player:getViewAsCardNames(guifu.name, all_names, selected_cards, player:getTableMark("guifu-turn"))
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, guifu.name, cards)
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    player.room:addTableMark(player, "guifu-turn", use.card.trueName)
  end,
  enabled_at_play = function(self, player)
    return #player:getViewAsCardNames(guifu.name, player:getTableMark("guifu_card_record"), nil, player:getTableMark("guifu-turn")) > 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and
      #player:getViewAsCardNames(guifu.name, player:getTableMark("guifu_card_record"), nil, player:getTableMark("guifu-turn")) > 0
  end,
  enabled_at_nullification = Util.FalseFunc,
})

guifu:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, guifu.name)
  end,
})

guifu:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(guifu.name) 
    and table.contains(data.card.skillNames, guifu.name) 
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

guifu:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(guifu.name) and (data.card or (Fk.skills[data.skillName] and Fk.skills[data.skillName]:isPlayerSkill()))
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@[guifu]")
    if mark == 0 then
      mark = { value = {} }
    end
    if data.card then
      if room:addTableMarkIfNeed(player, "guifu_card_record", data.card.trueName) then
        table.insert(mark.value, data.card.trueName)
        room:setPlayerMark(player, "@[guifu]", mark)
      end
    elseif Fk.skill_skels[data.skillName] then
      if Fk.skills[data.skillName] then
        if room:addTableMarkIfNeed(player, "guifu_skill_record", data.skillName) then
          table.insert(mark.value, data.skillName)
          room:setPlayerMark(player, "@[guifu]", mark)
        end
      end
    end
  end,
})

---@param player ServerPlayer
local guifuOnUse = function(_, _, _, player, _)
  local room = player.room
  --实测优先从牌堆底开始检索，然后弃牌堆，暗置获得
  local x = #room.draw_pile
  if x > 0 then
    for i = x, 1, -1 do
      local id = room.draw_pile[i]
      if Fk:getCardById(id).trueName == "jink" then
        room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonJustMove, guifu.name, nil, false, player, "@@guifu-inhand")
        return
      end
    end
  end
  local card = room:getCardsFromPileByRule("jink", 1, "discardPile")
  if #card > 0 then
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, guifu.name, nil, false, player, "@@guifu-inhand")
  end
end

guifu:addEffect(fk.RoundStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guifu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = guifuOnUse,
})

guifu:addEffect(fk.HpRecover, {
  anim_type = "drawcard",
  on_cost = Util.TrueFunc,
  on_use = guifuOnUse,
})

guifu:addEffect(fk.HpChanged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and data.num <= 0 and player:hasSkill(guifu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = guifuOnUse,
})

guifu:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@guifu-inhand") > 0
  end,
})

Fk:addQmlMark{
  name = "guifu",
  qml = function(name, value, player)
    return {
      url = "packages/ol/qml/guifu.qml",
      prop = {
        name = name,
        value = value.value,
      },
    }
  end,
  how_to_show = function(name, value, p)
    if type(value) ~= "table" then return " " end
    local val = value.value
    local template = Fk:translate("guifu_mark_string")
    local n = #val
    local nskills = #table.filter(val, function(str)
      return Fk.skills[str] ~= nil
    end)
    return template:format(nskills, n - nskills)
  end,
}

guifu:addLoseEffect(function(self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "guifu_card_record", 0)
  room:setPlayerMark(player, "guifu_skill_record", 0)
  room:setPlayerMark(player, "guifu-turn", 0)
  room:setPlayerMark(player, "@[guifu]", 0)
end)

return guifu
