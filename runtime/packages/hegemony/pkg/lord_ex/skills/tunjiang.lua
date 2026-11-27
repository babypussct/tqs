
local tunjiang = fk.CreateSkill {
  name = "ld__tunjiang",
}

Fk:loadTranslationTable {
  ["ld__tunjiang"] = "屯江",
  [":ld__tunjiang"] = "结束阶段，若你于此回合未使用牌指定过其他角色为目标，你可以摸X张牌（X为场上势力数）。",

  ["$ld__tunjiang1"] = "皇叔勿惊，吾与关将军已到。",
  ["$ld__tunjiang2"] = "江夏冲要之地，孩儿愿往守之。",
}

local H = require "packages.hegemony.util"

tunjiang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tunjiang.name) and player.phase == Player.Finish and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        return e.data.from == player and
          table.find(e.data.tos, function (p)
            return p ~= player
          end) ~= nil
      end, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local num = 0
    for _, v in pairs(H.getKingdomPlayersNum(player.room)) do
      if v and v > 0 then
        num = num + 1
      end
    end
    player:drawCards(num, tunjiang.name)
  end,
})

local AI = Fk.Ltk.AI
tunjiang:addAI(AI.reuse("biyue", AI.InvokeStrategy))

return tunjiang
