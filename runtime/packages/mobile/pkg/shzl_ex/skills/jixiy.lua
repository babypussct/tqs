local jixiy = fk.CreateSkill{
  name = "jixiy",
  tags = { Skill.Wake },
  related_skills = { "mobile__wangzun" },
}

Fk:loadTranslationTable{
  ["jixiy"] = "觊玺",
  [":jixiy"] = "觉醒技，回合结束后，若你连续三个自己的回合未失去过体力，你加1点体力上限，回复1点体力，然后选择一项：1.获得技能〖妄尊〗；"..
  "2.摸两张牌，然后获得主公的主公技。",

  ["jixiy1"] = "获得技能“妄尊”",
  ["jixiy2"] = "摸两张牌，获得主公的主公技",

  ["$jixiy1"] = "朕是开国之君，哈哈哈哈哈哈……",
  ["$jixiy2"] = "受命于天，既寿永昌。",
}

jixiy:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jixiy.name) and
      player:usedSkillTimes(jixiy.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local room = player.room
    local dat = {}
    local turn_events = room.logic:getEventsByRule(GameEvent.Turn, 3, function (e)
      if e.data.who == player then
        if e.end_id < 0 then
          table.insert(dat, {e.id, room.logic.current_event_id + 1})  --当前回合的end_id还是-1……
        else
          table.insert(dat, {e.id, e.end_id})
        end
        return true
      end
    end, 1)
    if #turn_events < 3 then return end
    return #room.logic:getEventsByRule(GameEvent.LoseHp, 1, function (e)
      if e.data.who == player and table.find(dat, function (ids)
        return e.id > ids[1] and e.id < ids[2]
      end) then
        return true
      end
    end, dat[1][1]) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = jixiy.name,
      }
    end
    if player.dead then return end
    local choice = room:askToChoice(player, {
      choices = {"jixiy1", "jixiy2"},
      skill_name = jixiy.name,
    })
    if choice == "jixiy1" then
      room:handleAddLoseSkills(player, "mobile__wangzun")
    else
      player:drawCards(2, jixiy.name)
      if player.dead then return end
      local skills = {}
      for _, p in ipairs(room.alive_players) do
        if p ~= player and p.role == "lord" then
          for _, s in ipairs(p:getSkillNameList()) do
            if Fk.skills[s]:hasTag(Skill.Lord) and not player:hasSkill(s, true)  then
              table.insert(skills, s)
            end
          end
        end
      end
      if #skills > 0 then
        room:handleAddLoseSkills(player, table.concat(skills, "|"))
      end
    end
  end,
})

return jixiy
