local xiaoni = fk.CreateSkill {
  name = "os__xiaoni",
}

Fk:loadTranslationTable{
  ["os__xiaoni"] = "嚣逆",
  [":os__xiaoni"] = "出牌阶段限一次，若“达命”值大于0，你可以将一张牌当任意一种【杀】或伤害类锦囊牌使用，并减少此牌目标数点“达命”值。"..
  "你的手牌上限为“达命”值与体力值较小的一项；你使用【杀】次数上限为“达命”值与体力值较大的一项。",
  ["#os__xiaoni"] = "嚣逆：你可以消耗“达命”值(可减至到负值)将一张牌当伤害牌使用！",

  ["$os__xiaoni1"] = "刘玄德？哼！不过一老卒而已。",
  ["$os__xiaoni2"] = "以吾之才，安得如此小吏之职！",
}

local changeDaming = function (player, n)
  local room = player.room
  local mark = type(player:getMark("@os__daming")) == "string" and 0 or player:getMark("@os__daming")
  mark = mark + n
  room:setPlayerMark(player, "@os__daming", mark == 0 and "0" or mark)
end

xiaoni:addEffect("viewas", {
  prompt = "#os__xiaoni",
  interaction_helper = function(self, player, selected_cards)
    local all_names = table.filter(Fk:getAllCardNames("btd"), function (name)
      local card = Fk:cloneCard(name)
      return card.is_damage_card or card.name == "lightning"
    end)
    local names = player:getViewAsCardNames(xiaoni.name, all_names, selected_cards)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data, nil, nil, xiaoni.name, cards)
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(xiaoni.name, Player.HistoryPhase) < 1 and
      tonumber(player:getMark("@os__daming")) > 0
  end,
})

xiaoni:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return player == target and table.contains(data.card.skillNames, xiaoni.name)
  end,
  on_refresh = function(self, event, target, player, data)
    changeDaming(player, -#data.tos)
  end,
})

xiaoni:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:hasSkill(xiaoni.name) then
      local mark = type(player:getMark("@os__daming")) == "string" and 0 or player:getMark("@os__daming")
      return math.max(0, math.min(mark, player.hp))
    end
  end,
})

xiaoni:addEffect("targetmod", {
  fix_times_func = function (self, player, skill, scope, card, to)
    if card and player:hasSkill(xiaoni.name) and card.trueName == "slash" then
      local mark = type(player:getMark("@os__daming")) == "string" and 0 or player:getMark("@os__daming")
      return math.max(mark, player.hp)
    end
  end
})

return xiaoni
