local gongli = fk.CreateSkill {
  name = "cuijun__gongli",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["cuijun__gongli"] = "共砺",
  [":cuijun__gongli"] = "锁定技，游戏开始时，你令〖顺逸〗增加X个可触发的花色（X为全场友武将数）。",

  ["#cuijun__gongli-choice"] = "共砺：为“顺逸”增加%arg个可触发花色",

  ["$cuijun__gongli1"] = "一味不能合伊鼎之甘，独木岂能致邓林之茂？",
  ["$cuijun__gongli2"] = "良友结，则辅仁之道弘矣。",
}

local U = require "packages.utility.utility"

gongli:addEffect(fk.GameStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gongli.name) and player:hasSkill("shunyi", true) and
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
      room:setPlayerMark(player, "shunyi", {Card.Spade, Card.Heart, Card.Club, Card.Diamond})
    else
      local choices = room:askToChoices(player, {
        choices = {"log_spade", "log_club", "log_diamond"},
        min_num = n,
        max_num = n,
        skill_name = gongli.name,
        prompt = "#cuijun__gongli-choice:::"..n,
        cancelable = false,
      })
      choices = table.map(choices, function (s)
        return U.ConvertSuit(s, "sym", "int")
      end)
      local mark = {Card.Heart}
      table.insertTable(mark, choices)
      room:setPlayerMark(player, "shunyi", mark)
    end
  end,
})

return gongli
