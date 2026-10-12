local polus = fk.CreateSkill {
  name = "polus",
}

Fk:loadTranslationTable{
  ["polus"] = "破虏",
  [":polus"] = "当你杀死一名角色后或死亡后，你可以令任意名角色各摸X张牌（X为你发动过此技能的次数+1）。",

  ["#polus-choose"] = "破虏：你可以令任意名角色各摸%arg张牌",

  ["$polus"] = "斩敌复城，扬我江东军威！",
}

polus:addEffect(fk.Deathed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player then
      return player:hasSkill(polus.name, false, true)
    else
      return player:hasSkill(polus.name) and data.killer == player
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player,{
      min_num = 1,
      max_num = 10,
      targets = room.alive_players,
      prompt = "#polus-choose:::" .. player:usedSkillTimes(polus.name, Player.HistoryGame) + 1,
      skill_name = polus.name,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      if p:isAlive() then
        p:drawCards(player:usedSkillTimes(polus.name, Player.HistoryGame), polus.name)
      end
    end
  end,
})

return polus
