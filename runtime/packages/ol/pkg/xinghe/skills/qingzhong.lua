local qingzhong = fk.CreateSkill{
  name = "qingzhong",
}

Fk:loadTranslationTable{
  ["qingzhong"] = "清忠",
  [":qingzhong"] = "出牌阶段开始时，你可以摸两张牌，然后本阶段结束时，你与一名手牌数最少的角色交换手牌。",

  ["#qingzhong-choose"] = "清忠：选择一名手牌数最少的角色，与其交换手牌",

  ["$qingzhong1"] = "执政为民，当尽我所能。",
  ["$qingzhong2"] = "吾自幼流离失所，更能体恤百姓之苦。",
}

qingzhong:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingzhong.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, qingzhong.name)
  end,
})
qingzhong:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:usedSkillTimes(qingzhong.name, Player.HistoryPhase) > 0 then
      local x = player:getHandcardNum()
      return table.find(player.room.alive_players, function(p)
        return p ~= player and p:getHandcardNum() <= x
      end)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local x, y = player:getHandcardNum(), 0
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if p ~= player then
        y = p:getHandcardNum()
        if x > y then
          x = y
          targets = { p }
        elseif x == y then
          table.insert(targets, p)
        end
      end
    end
    if #targets == 0 then return end
    targets = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = qingzhong.name,
      prompt = "#qingzhong-choose",
      cancelable = ( x == player:getHandcardNum()),
    })

    if #targets > 0 then
      room:swapAllCards(player, {player, targets[1]}, qingzhong.name)
    end
  end,
})

return qingzhong
