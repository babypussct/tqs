local duoren = fk.CreateSkill {
  name = "os__duoren",
}

Fk:loadTranslationTable{
  ["os__duoren"] = "夺刃",
  [":os__duoren"] = "一名其他角色死亡后，若你对其造成过伤害或其对你造成过伤害，你可以失去所有不为你武将牌上的技能，"..
  "然后<a href='memorialize'>追思</a>该角色，获得其武将牌上除主公技以外的所有技能。",

  ["$os__duoren1"] = "便以汝血，封汝之刀！",
  ["$os__duoren2"] = "血婆娑之剑，从不会沾无辜之血。",
}

duoren:addEffect(fk.Deathed, {
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(duoren.name) and
      #player.room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data
        return (damage.from == player and damage.to == target) or (damage.from == target and damage.to == player)
      end, Player.HistoryGame) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = {}
    local generalSkills = Fk.generals[player.general]:getSkillNameList(true)
    if player.deputyGeneral ~= "" then
      table.insertTable(generalSkills, Fk.generals[player.deputyGeneral]:getSkillNameList(true))
    end
    for _, s in ipairs(player:getSkillNameList()) do
      if not table.contains(generalSkills, s) and not Fk.skill_skels[s].mode_skill then
        table.insert(skills, "-"..s)
      end
    end
    if not table.contains(room:getBanner("memorializedPlayers") or {}, target.id) then
      local banner = room:getBanner("memorializedPlayers") or {}
      table.insertIfNeed(banner, target.id)
      room:setBanner("memorializedPlayers", banner)
      table.insertTable(skills, Fk.generals[target.general]:getSkillNameList())
      if target.deputyGeneral ~= "" then
        table.insertTable(skills, Fk.generals[target.deputyGeneral]:getSkillNameList())
      end
    end
    room:handleAddLoseSkills(player, table.concat(skills, "|"))
  end,
})

return duoren
