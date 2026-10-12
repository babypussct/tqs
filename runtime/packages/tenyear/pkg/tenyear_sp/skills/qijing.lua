local qijing = fk.CreateSkill {
  name = "qijing",
  tags = { Skill.Wake },
  related_skills = { "cuixin" },
}

Fk:loadTranslationTable{
  ["qijing"] = "奇径",
  [":qijing"] = "觉醒技，每个回合结束时，若你的手牌副区域均已开发，你减1点体力上限，获得技能〖摧心〗，然后将座次移动至相邻的两名其他角色之间并"..
  "执行一个额外回合。",

  ["#qijing-choose"] = "奇径：选择一名角色，你移动座次成为其下家",

  ["$qijing1"] = "今神兵于天降，贯奕世之长虹！",
  ["$qijing2"] = "辟罗浮之险径，捣伪汉之黄龙！"
}

qijing:addEffect(fk.TurnEnd, {
  priority = 2,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qijing.name) and player:usedSkillTimes(qijing.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("tuoyu1") > 0 and player:getMark("tuoyu2") > 0 and player:getMark("tuoyu3") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return false end
    room:handleAddLoseSkills(player, "cuixin")
    local tos = table.filter(room.alive_players, function (p)
      return p ~= player and p:getNextAlive(true) ~= player
    end)
    if #tos > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 1,
        prompt = "#qijing-choose",
        skill_name = qijing.name,
        cancelable = true,
        no_indicate = true,
      })
      if #to > 0 then
        room:moveSeatToNext(player, to[1], false, room.current ~= player)
        if room.current == player then
          local roundEvent = room.logic:getCurrentEvent():findParent(GameEvent.Round)
          if roundEvent then
            for i, p in ipairs(roundEvent.data.turn_table) do
              if player.seat == p.seat + 1 then
                table.insert(roundEvent.data.turn_table, i + 1, player)
                break
              end
            end
          end
        end
      end
    end
    player:gainAnExtraTurn(true, qijing.name)
  end,
})

return qijing
