local zhenyu = fk.CreateSkill{
  name = "zhenyu",
}

Fk:loadTranslationTable{
  ["zhenyu"] = "镇御",
  [":zhenyu"] = "当你需要使用基本牌时，你可以横置一名角色，然后视为使用之。若如此做，此技能失效直到每轮结束或你从手牌中使用了以此法使用的基本牌。",

  ["#zhenyu"] = "镇御：横置一名角色，视为使用一张基本牌",
  ["#zhenyu-choose"] = "镇御：选择一名角色横置",
  ["@zhenyu-round"] = "镇御",

  ["$zhenyu1"] = "敌如浪、城如礁，碎之如雪！",
  ["$zhenyu2"] = "纵有千军来犯，吾亦不退半分！",
}

zhenyu:addEffect("viewas", {
  anim_type = "control",
  prompt = "#zhenyu",
  pattern = ".|.|.|.|.|basic",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = ".",
    subcards = {},
  },
  interaction_helper = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(zhenyu.name, all_names, {})
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  view_as = function(self, player, cards)
    if Fk.all_card_types[self.interaction.data] == nil then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, zhenyu.name)
  end,
  before_use = function(self, player, use)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p.chained
    end)
    if #targets == 0 then return end
    room:setPlayerMark(player, "@zhenyu-round", use.card.trueName)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = zhenyu.name,
      prompt = "#zhenyu-choose",
      cancelable = false,
    })[1]
    to:setChainState(true)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@zhenyu-round") == 0 and
      table.find(Fk:currentRoom().alive_players, function(p)
        return not p.chained
      end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:getMark("@zhenyu-round") == 0 and
      table.find(Fk:currentRoom().alive_players, function(p)
        return not p.chained
      end)
  end,
})

zhenyu:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      player:getMark("@zhenyu-round") == data.card.trueName and data:isUsingHandcard(player)
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@zhenyu-round", 0)
  end,
})

zhenyu:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@zhenyu-round", 0)
end)

return zhenyu
