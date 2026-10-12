
local jiaozhao = fk.CreateSkill {
  name = "ol_ex__jiaozhao",
  dynamic_desc = function(self, player, lang)
    if player:getMark("ol_ex__danxin") > 0 then
      return "ol_ex__jiaozhao_inner"..player:getMark("ol_ex__danxin")
    end
  end,
}

Fk:loadTranslationTable{
  ["ol_ex__jiaozhao"] = "矫诏",
  [":ol_ex__jiaozhao"] = "出牌阶段限一次，你可以将一张牌当本轮没有角色使用过的基本牌或普通锦囊牌使用。",

  [":ol_ex__jiaozhao_inner1"] = "每轮限一次，你可以将一张牌当任意基本牌或普通锦囊牌使用。",
  [":ol_ex__jiaozhao_inner2"] = "每轮限一次，你可以视为使用一张基本牌或普通锦囊牌。",

  ["#ol_ex__jiaozhao"] = "矫诏：将一张牌当任意基本牌或普通锦囊牌使用",
  ["#ol_ex__jiaozhao_update"] = "矫诏：视为使用一张基本牌或普通锦囊牌",

  ["$ol_ex__jiaozhao1"] = "此诏予卿，愿不负帝室之望。",
  ["$ol_ex__jiaozhao2"] = "幸有先帝遗诏，保家族俱荣。",
}

jiaozhao:addEffect("viewas", {
  pattern = ".",
  prompt = function(self, player, selected_cards, selected)
    if player:getMark("ol_ex__danxin") < 2 then
      return "#ol_ex__jiaozhao"
    else
      return "#ol_ex__jiaozhao_update"
    end
  end,
  handly_pile = true,
  filter_pattern = function(self, player, card_name, selected)
    local n = 1
    if player:getMark("ol_ex__danxin") > 1 then
      n = 0
    end
    return {
      min_num = n,
      max_num = n,
      pattern = ".",
    }
  end,
  interaction_helper = function(self, player, selected_cards)
    local all_names = Fk:getAllCardNames("bt")
    local names = player:getViewAsCardNames(jiaozhao.name, all_names, selected_cards,
      player:getMark("ol_ex__danxin") == 0 and player:getTableMark("ol_ex__jiaozhao-round") or {})
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    if player:getMark("ol_ex__danxin") < 2 then
      if #cards ~= 1 then return end
    end
    return Fk:cloneCard(self.interaction.data, nil, nil, jiaozhao.name, cards)
  end,
  enabled_at_play = function(self, player)
    if player:getMark("ol_ex__danxin") == 0 then
      return player:usedSkillTimes(jiaozhao.name, Player.HistoryPhase) == 0
    else
      return player:usedSkillTimes(jiaozhao.name, Player.HistoryRound) == 0
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(jiaozhao.name, Player.HistoryRound) == 0 and
      player:getMark("ol_ex__danxin") > 0
  end,
  enabled_at_nullification = function(self, player, data)
    if player:usedSkillTimes(jiaozhao.name, Player.HistoryRound) == 0 then
      if player:getMark("ol_ex__danxin") == 1 then
        return #player:getHandlyIds() > 0 or not player:isNude()
      elseif player:getMark("ol_ex__danxin") > 1 then
        return true
      end
    end
  end,
})

jiaozhao:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(jiaozhao.name, true) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "ol_ex__jiaozhao-round", data.card.trueName)
  end,
})

jiaozhao:addAcquireEffect(function(self, player, is_start)
  if not is_start then
    local room = player.room
    local names = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.card.type == Card.TypeBasic or use.card:isCommonTrick() then
        table.insertIfNeed(names, use.card.name)
      end
    end, Player.HistoryRound)
    room:setPlayerMark(player, jiaozhao.name, names)
  end
end)

jiaozhao:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "ol_ex__danxin", 0)
end)

return jiaozhao
