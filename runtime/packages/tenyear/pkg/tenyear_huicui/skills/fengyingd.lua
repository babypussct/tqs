local fengying = fk.CreateSkill {
  name = "fengyingd",
}

Fk:loadTranslationTable{
  ["fengyingd"] = "风影",
  [":fengyingd"] = "一名角色的回合开始时，记录弃牌堆中的黑色基本牌和黑色普通锦囊牌牌名。你可以将一张点数不大于“绞”标记数的手牌"..
  "当一张记录的本回合未以此法使用过的牌使用（无距离次数限制）。",

  ["#fengyingd"] = "风影：将一张点数不大于“绞”标记数的手牌当一张记录的牌使用",
  ["@$fengyingd-turn"] = "风影",

  ["$fengyingd1"] = "可怜东篱寒累树，孤影落秋风。",
  ["$fengyingd2"] = "西风落，西风落，宫墙不堪破。",
}

fengying:addEffect("viewas", {
  anim_type = "special",
  pattern = ".",
  prompt = "#fengyingd",
  handly_pile = true,
  filter_pattern = function(self, player, card_name, selected)
    local x = player:getMark("@dongguiren_jiao")
    if x > 0 then
      return {
        min_num = 1,
        max_num = 1,
        pattern = ".|1~" .. tostring(math.min(13, x)) .. "|.|^equip",
      }
    end
  end,
  interaction_helper = function(self, player, selected_cards)
    local all_names = player:getTableMark("@$fengyingd-turn")
    local names = player:getViewAsCardNames(fengying.name, all_names, selected_cards)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, fengying.name, cards)
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    player.room:removeTableMark(player, "@$fengyingd-turn", use.card.name)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@dongguiren_jiao") > 0 and
      #player:getViewAsCardNames(fengying.name, player:getTableMark("@$fengyingd-turn"), nil, nil,
        {bypass_distances = true, bypass_times = true}) > 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:getMark("@dongguiren_jiao") > 0 and
    #player:getViewAsCardNames(fengying.name, player:getTableMark("@$fengyingd-turn"), nil, nil,
      {bypass_distances = true, bypass_times = true}) > 0
  end,
  enabled_at_nullification = function(self, player, data)
    if player:getMark("@dongguiren_jiao") > 0 and #player:getHandlyIds() > 0 then
      for _, name in ipairs(player:getTableMark("@$fengyingd-turn")) do
        if Fk:cloneCard(name).trueName == "nullification" then
          return true
        end
      end
    end
  end,
})

fengying:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(fengying.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(room.discard_pile) do
      local card = Fk:getCardById(id)
      if card.color == Card.Black and (card.type == Card.TypeBasic or card:isCommonTrick()) then
        table.insertIfNeed(names, card.name)
      end
    end
    room:setPlayerMark(player, "@$fengyingd-turn", #names > 0 and names or 0)
  end,
})

fengying:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@$fengyingd-turn", 0)
end)

fengying:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, fengying.name)
  end,
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, fengying.name)
  end,
})

return fengying
