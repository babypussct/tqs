local rule = fk.CreateSkill {
  name = "#rougelike1v1_rule",
}

local RougeUtil = require "packages.ol.pkg.ol_gamemode.rougelike1v1.util"

Fk:loadTranslationTable {
  ["#rougelike1v1_rule"] = "单骑无双",
}

rule:addEffect(fk.GameStart, {
  priority = 0.001,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    -- 回合结束时，增加虎符，进行消费
    local room = player.room
    local players = room.alive_players
    local req = Request:new(players, "AskForChoices")
    req.focus_text = "rougelike1v1"
    req.receive_decode = false
    local _talents = room:tableRandomPick(RougeUtil.talents, 3 * #players)
    local talents = table.map(_talents, function(t) return t[2] end)
    for i, p in ipairs(players) do
      local choices = table.slice(talents, 3 * (i - 1) + 1, 3 * (i - 1) + 4)
      req:setData(p, {
        choices, choices, {1, 1}, false, "rougelike1v1", "#rouge-init-talent", true, true
      })
      req:setDefaultReply(p, choices[1])
      --RougeUtil.attachTalentToPlayer(p, "rouge_chenqibubei1") -- for test
    end
    for _, p in ipairs(players) do
      local result = req:getResult(p)[1]
      for _, t in ipairs(_talents) do
        if t[2] == result then
          room:sendLog {
            type = "#rouge_init_talent",
            from = p.id,
            arg = t[2],
          }
          t[3](t[2], p)
          break
        end
      end
    end
  end,
})

rule:addEffect(fk.TurnEnd, {
  priority = 0.003,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getCurrentExtraTurnReason() == "game_rule"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    -- 回合结束时，增加虎符，进行消费
    local room = player.room
    local round = room:getBanner("RoundCount")
    if round > 3 then
      for _, p in ipairs(room.alive_players) do
        RougeUtil.changeMoney(p, 2)
      end
    else
      if round == 1 and player.seat == 1 then
        RougeUtil.changeMoney(player, 2)
        RougeUtil.changeMoney(player:getNextAlive(), 3)
      else
        for _, p in ipairs(room.alive_players) do
          RougeUtil.changeMoney(p, 1)
        end
      end
    end
    RougeUtil:askForShopping(room.players)
  end,
})

rule:addEffect(fk.TurnEnd, {
  priority = 0.001,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getCurrentExtraTurnReason() == "game_rule"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    RougeUtil:askForShopping(player.room.players)
  end,
})

return rule
