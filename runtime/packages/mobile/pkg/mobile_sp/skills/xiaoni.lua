local xiaoni = fk.CreateSkill {
  name = "xiaoni",
}

Fk:loadTranslationTable{
  ["xiaoni"] = "嚣逆",
  [":xiaoni"] = "①出牌阶段限一次，若你的“达命”值大于0，你可以将一张牌当任意一种【杀】或伤害类锦囊牌使用，并减少此牌目标数点“达命”值。<br>"..
  "②你的手牌上限等于X（X为“达命”值，且至多为你的体力值）。",
  ["#xiaoni"] = "嚣逆：你可以消耗“达命”值(可减至到负值)将一张牌当伤害牌使用！",

  ["$xiaoni1"] = "织席贩履之辈，果无用人之能乎？",
  ["$xiaoni2"] = "古今天下，岂有重屠沽之流而轻贤达者乎？",
}

local changeDaming = function (player, n)
  local room = player.room
  local mark = type(player:getMark("@daming")) == "string" and 0 or player:getMark("@daming")
  mark = mark + n
  room:setPlayerMark(player, "@daming", mark == 0 and "0" or mark)
end

xiaoni:addEffect("viewas", {
  prompt = "#xiaoni",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("btd")
    local names = table.filter(all_names, function (name)
      local card = Fk:cloneCard(name)
      card.skillName = xiaoni.name
      return
        player:canUse(card) and
        (
          card.trueName == "slash" or
          (card.type == Card.TypeTrick and card.is_damage_card) or card.name == "lightning"
        )
    end)
    if #names == 0 then return end
    return UI.ComboBox { choices = names }
  end,
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = xiaoni.name
    return card
  end,
  enabled_at_play = function(self, player)
    return
      player:usedSkillTimes(xiaoni.name, Player.HistoryPhase) < 1 and
      tonumber(player:getMark("@daming")) > 0
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
      local mark = type(player:getMark("@daming")) == "string" and 0 or player:getMark("@daming")
      return math.max(0, math.min(mark, player.hp))
    end
  end,
})

return xiaoni
