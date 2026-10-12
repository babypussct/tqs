local hongyi = fk.CreateSkill {
  name = "hongyi",
}

Fk:loadTranslationTable{
  ["hongyi"] = "弘仪",
  [":hongyi"] = "出牌阶段限一次，你可以指定一名其他角色，当其于你的下个回合开始之前造成伤害时，其判定，若结果为："..
  "红色，受伤角色摸一张牌；黑色，令伤害值-1。",

  ["#hongyi-active"] = "弘仪：选择一名其他角色，其造成伤害时判定，判红受伤角色摸牌，判黑伤害-1",
  ["@@hongyi"] = "弘仪",

  ["$hongyi1"] = "克明礼教，约束不端之行。",
  ["$hongyi2"] = "训成弘操，以扬正明之德。",
}

hongyi:addEffect("active", {
  anim_type = "control",
  prompt = "#hongyi-active",
  max_card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(hongyi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local targetRecorded = player:getTableMark("hongyi_targets")
    if table.insertIfNeed(targetRecorded, target.id) then
      room:addPlayerMark(target, "@@hongyi")
      room:setPlayerMark(player, "hongyi_targets", targetRecorded)
    end
  end,
})

hongyi:addEffect(fk.DamageCaused, {
  is_delay_effect = true,
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@hongyi") ~= 0 and player:isAlive()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local judge = {
      who = target,
      reason = hongyi.name,
      pattern = {
        [".|.|black,red"] = "good",
        [".|.|red"] = "red",
        [".|.|black"] = "black",
        ["else"] = "bad",
      },
    }
    room:judge(judge)
    if not judge.results then return false end
    if table.contains(judge.results, "red") and data.to and data.to:isAlive() then
      room:drawCards(data.to, 1, hongyi.name)
    elseif table.contains(judge.results, "black") then
      data:changeDamage(-1)
    end
  end,
})

local hongyiClearSpec = {
  can_refresh = function(self, event, target, player, data)
    return player == target and type(player:getMark("hongyi_targets")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("hongyi_targets")
    if type(targets) == "table" then
      for _, pid in ipairs(targets) do
        room:removePlayerMark(room:getPlayerById(pid), "@@hongyi")
      end
    end
    room:setPlayerMark(player, "hongyi_targets", 0)
  end,
}

hongyi:addEffect(fk.TurnStart, hongyiClearSpec)

hongyi:addLoseEffect(function(self, player)
  if hongyiClearSpec.can_refresh(self, nil, player, player) then
    hongyiClearSpec.on_refresh(self, nil, nil, player)
  end
end)

return hongyi
