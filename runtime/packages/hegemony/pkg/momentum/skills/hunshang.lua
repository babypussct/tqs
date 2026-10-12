local hunshang = fk.CreateSkill{
  name = "hunshang",
  tags = {Skill.DeputyPlace, Skill.Compulsory},
  related_skills = { "heg_sunce__yingzi", "heg_sunce__yinghun" },
}
hunshang:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hunshang.name) and
      player.phase == Player.Start and player.hp == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "heg_sunce__yingzi|heg_sunce__yinghun")
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(player, "-heg_sunce__yingzi|-heg_sunce__yinghun", nil, true, false)
    end)
  end,
})

Fk:loadTranslationTable{
  ["hunshang"] = "魂殇",
  [":hunshang"] = "副将技，锁定技，此武将牌减少半个阴阳鱼；准备阶段，若你的体力值为1，你拥有技能〖英姿〗和〖英魂〗至本回合结束。",
}

return hunshang
