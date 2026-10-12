
local guju = fk.CreateSkill {
  name = "guju",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["guju"] = "骨疽",
  [":guju"] = "锁定技，当有“傀”的角色受到伤害后，你摸一张牌。",

  ["@guju"] = "骨疽",

  ["$guju1"] = "我能看到，你的灵魂在颤抖。",
  ["$guju2"] = "你死后，我将超度你的亡魂。"
}

guju:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@puppet") > 0 and player:hasSkill(guju.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, guju.name)
    if player:hasSkill("baijia", true) and player:usedSkillTimes("baijia", Player.HistoryGame) == 0 then
      room:addPlayerMark(player, "@guju", 1)
    end
  end,
})

guju:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@guju", 0)
end)

return guju
