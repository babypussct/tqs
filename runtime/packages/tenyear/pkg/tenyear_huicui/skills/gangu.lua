local gangu = fk.CreateSkill {
  name = "gangu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["gangu"] = "干蛊",
  [":gangu"] = "锁定技，每回合限一次，当有其他角色失去体力后，你摸三张牌，然后若你的体力值不为全场最少，失去1点体力。",

  ["$gangu1"] = "承志奉祠，达于行伍之事。",
  ["$gangu2"] = "干父之蛊，全辽裔未竟之业。",
}

gangu:addEffect(fk.HpLost, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(gangu.name) and
      player:usedSkillTimes(gangu.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, gangu.name)
    if not player.dead and
      table.find(room:getOtherPlayers(player, false), function (p)
        return p.hp < player.hp
      end) then
      room:loseHp(player, 1, gangu.name)
    end
  end,
})

return gangu
