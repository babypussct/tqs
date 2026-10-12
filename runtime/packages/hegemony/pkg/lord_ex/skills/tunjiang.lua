local tunjiang = fk.CreateSkill {
  name = "ld__tunjiang",
}

Fk:loadTranslationTable {
  ["ld__tunjiang"] = "屯江",
  [":ld__tunjiang"] = "结束阶段，若你于此回合的出牌阶段内使用过牌且未指定过其他角色为目标，你可摸X张牌（X为场上势力数）。",

  ["$ld__tunjiang1"] = "皇叔勿惊，吾与关将军已到。",
  ["$ld__tunjiang2"] = "江夏冲要之地，孩儿愿往守之。",
}

local H = require "packages.hegemony.util"

tunjiang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(tunjiang.name) and player.phase == Player.Finish) then return false end
    local targets, play_ids = {}, {}
    local ret = false
    local logic = player.room.logic
    logic:getEventsOfScope(GameEvent.Phase, 1, function(e)
      if e.data.phase == Player.Play then
        table.insert(play_ids, { e.id, e.end_id })
      end
      return false
    end, Player.HistoryTurn)
    logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local in_play = false
      for _, ids in ipairs(play_ids) do
        if #ids == 2 and e.id > ids[1] and e.id < ids[2] then
          in_play = true
          break
        end
      end
      if in_play then
        local use = e.data
        if use.from == player then
          ret = true
          for _, id in ipairs(use:getAllTargets()) do
            table.insertIfNeed(targets, id)
          end
          if #targets > 1 then return true end
        end
      end
    end, Player.HistoryTurn)
    return ret and (#targets == 0 or (#targets == 1 and targets[1] == player))
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

return tunjiang
