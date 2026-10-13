local rule = fk.CreateSkill {
  name = "#1v2_brawl&",
}

-- FIXME: 需要武将和图像分离的机制
-- 权宜之计，防止获得禁用武将的技能
rule:addEffect(fk.EventAcquireSkill, {
  can_refresh = function (self, event, target, player, data)
    if target == player then
      local general = Fk.generals[player.general]
      if general and table.contains(general:getSkillNameList(), data.skill:getSkeleton().name) then
        return not Fk:canUseGeneral(player.general)
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room.logic:getCurrentEvent():addCleaner(function()
      room:handleAddLoseSkills(player, "-"..data.skill:getSkeleton().name, nil, false, true)
    end)
  end,
})

return rule
