local polu = fk.CreateSkill {
  name = "ol_fd__polu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_fd__polu"] = "破虏",
  [":ol_fd__polu"] = "锁定技，当友方角色杀死一名敌方角色后或你死亡后，友方角色各摸X张牌（X为你发动此技能次数）。",

  ["$ol_fd__polu1"] = "宝剑出鞘，踏平贼营！",
  ["$ol_fd__polu2"] = "乱世清君侧，挥师复江山。",
}

polu:addEffect(fk.Deathed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player then
      return player:hasSkill(polu.name, false, true) and #player:getFriends(false) > 0
    else
      return player:hasSkill(polu.name) and target:isEnemy(player) and data.killer and data.killer:isFriend(player)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local friends = player:getFriends(target ~= player)
    room:sortByAction(friends)
    event:setCostData(self, {tos = friends})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getFriends(target ~= player)
    room:sortByAction(targets)
    local n = player:usedSkillTimes(polu.name, Player.HistoryGame)
    for _, p in ipairs(targets) do
      if not p.dead then
        p:drawCards(n, polu.name)
      end
    end
  end,
})

return polu
