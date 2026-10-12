local gongli = fk.CreateSkill {
  name = "shitao__gongli",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shitao__gongli"] = "共砺",
  [":shitao__gongli"] = "锁定技，游戏开始时，你令本局〖钦英〗减少X个可用于弃置的类别的牌（X为全场友武将数）。",

  ["#shitao__gongli-choice"] = "共砺：为“钦英”减少%arg个可弃置类别",

  ["$shitao__gongli1"] = "天下失道，诸君可有意共匡社稷？",
  ["$shitao__gongli2"] = "既志同道合，吾等何不一道？",
}

gongli:addEffect(fk.GameStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gongli.name) and player:hasSkill("qinying", true) and
      table.find(player.room.alive_players, function (p)
        return p.general:startsWith("m_friend__") or p.deputyGeneral:startsWith("m_friend__")
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if p.general:startsWith("m_friend__") then
        n = n + 1
      end
      if p.deputyGeneral:startsWith("m_friend__") then
        n = n + 1
      end
      if n > 2 then break end
    end
    if n == 3 then
      room:setPlayerMark(player, "qinying", {Card.TypeBasic, Card.TypeTrick, Card.TypeEquip})
    else
      local choices = room:askToChoices(player, {
        choices = {"basic", "trick", "equip"},
        min_num = n,
        max_num = n,
        skill_name = gongli.name,
        prompt = "#shitao__gongli-choice:::"..n,
        cancelable = false,
      })
      room:setPlayerMark(player, "qinying", choices)
    end
  end,
})

return gongli
