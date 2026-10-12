local yanglie = fk.CreateSkill {
  name = "yanglie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yanglie"] = "扬烈",
  [":yanglie"] = "锁定技，准备阶段，你获得所有其他角色区域内各一张牌，然后你失去1点体力。",

  ["$yanglie1"] = "此机，我怎么会错失！",
  ["$yanglie2"] = "你的东西，现在是我的了！",
}

yanglie:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yanglie.name) and
      player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, {tos = player.room:getOtherPlayers(player)})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead and not p:isAllNude() then
        local id = room:askToChooseCard(player, {
          target = p,
          flag = "hej",
          skill_name = yanglie.name,
        })
        room:obtainCard(player, id, false, fk.ReasonPrey, player, yanglie.name)
        if player.dead then return end
      end
    end
    room:loseHp(player, 1, yanglie.name)
  end,
})

return yanglie
