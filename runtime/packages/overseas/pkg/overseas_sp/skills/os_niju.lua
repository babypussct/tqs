local osNiju = fk.CreateSkill {
  name = "os__niju",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable {
  ["os__niju"] = "逆拒",
  [":os__niju"] = "主公技，当你的拼点牌亮出后，可以令任一张拼点牌的点数+X或-X，然后若两张拼点牌点数相同，你摸X张牌（X为其他群势力角色数）。",

  ["os__niju_plus"] = "%dest拼点牌点数+%arg",
  ["os__niju_minus"] = "%dest拼点牌点数-%arg",
}

osNiju:addEffect(fk.PindianCardsDisplayed, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return
        (player == data.from or data.results[player]) and
        player:hasSkill(osNiju.name) and
        table.find(player.room.alive_players, function(p) return p ~= player and p.kingdom == "qun" end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local num = #table.filter(room.alive_players, function(p) return p ~= player and p.kingdom == "qun" end)
    local choices = { "os__niju_plus::" .. data.from.id .. ":" .. num, "os__niju_minus::" .. data.from.id .. ":" .. num }
    for p, _ in pairs(data.results) do
      table.insert(choices, "os__niju_plus::" .. p.id .. ":" .. num)
      table.insert(choices, "os__niju_minus::" .. p.id .. ":" .. num)
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = osNiju.name,
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osNiju.name
    local choice = event:getCostData(self):split(":")
    local num = tonumber(choice[4])
    local drawnum = num or 0
    if choice[1] == "os__niju_minus" then num = -num end
    local toId = tonumber(choice[3])
    player.room:changePindianNumber(data, player.room:getPlayerById(toId), num, skillName)
    local from = data.fromCard.number
    for _, r in pairs(data.results) do
      if r.toCard.number ~= from then
        return false
      end
    end
    player:drawCards(drawnum, skillName)
  end,
})

return osNiju
