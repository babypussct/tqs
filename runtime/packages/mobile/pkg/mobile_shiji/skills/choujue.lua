local choujue = fk.CreateSkill {
  name = "mobile__choujue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__choujue"] = "仇决",
  [":mobile__choujue"] = "锁定技，当你杀死一名角色后，你加1点体力上限，摸两张牌，你本回合〖却敌〗可发动次数+1。",

  ["$mobile__choujue1"] = "血海深仇，便在今日来报！",
  ["$mobile__choujue2"] = "取汝之头，以祭先父！",
}

choujue:addEffect(fk.Deathed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(choujue.name) and data.killer == player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "choujue_buff-turn", 1)
    room:changeMaxHp(player, 1)
    if player.dead then return end
    player:drawCards(2, choujue.name)
  end,
})

return choujue
