local osChijie = fk.CreateSkill {
  name = "os__chijie"
}

Fk:loadTranslationTable{
  ["os__chijie"] = "持节",
  [":os__chijie"] = "游戏开始时，你可将你的势力改为现存的一个势力。",

  ["#os__chijie-choose"] = "持节：你可更改你的势力",

  ["$os__chijie1"] = "按照女王的命令，选择目标吧！",
}

osChijie:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osChijie.name)
  end,
  on_cost = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    table.insert(kingdoms, "Cancel")
    local choice = player.room:askToChoice(
      player,
      {
        choices = kingdoms,
        skill_name = osChijie.name,
        prompt = "#os__chijie-choose",
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    player.room:changeKingdom(player, event:getCostData(self), true)
  end,
})

return osChijie
