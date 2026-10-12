
local yingyang = fk.CreateSkill{
  name = "yingyang",
}
yingyang:addEffect(fk.PindianCardsDisplayed, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yingyang.name) and (player == data.from or data.results[player])
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = { "yingyang_plus3", "yingyang_sub3", "Cancel" },
      skill_name = yingyang.name
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:changePindianNumber(data, player, event:getCostData(self).choice:endsWith("plus3") and 3 or -3, yingyang.name)
  end,
})

Fk:loadTranslationTable{
  ["yingyang"] = "鹰扬",
  [":yingyang"] = "当你的拼点牌亮出后，你可令其点数+3或-3。",

  ["yingyang_plus3"] = "令你的拼点牌点数+3",
  ["yingyang_sub3"] = "令你的拼点牌点数-3",

  ["$yingyang1"] = "此战，我必取胜！",
  ["$yingyang2"] = "相斗之趣，吾常胜之。",
}

return yingyang
