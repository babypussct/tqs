local shishou = fk.CreateSkill {
  name = "shishoul",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shishoul"] = "侍守",
  [":shishoul"] = "锁定技，当其他角色执行了“佐佑”的一项后，你执行“佐佑”的另一项。",

  ["$shishoul1"] = "此乃天子御驾，尔等谁敢近前！",
  ["$shishoul2"] = "吾等侍卫在侧，必保陛下无虞！",
}

local function DoZuoyou(player, status)
  local room = player.room
  if status == "yang" then
    player:drawCards(3, "zuoyou")
    if not player.dead and not player:isKongcheng() then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = false,
        skill_name = "zuoyou",
        cancelable = false,
      })
    end
  else
    if room:isGameMode("2v2_mode") then
      room:changeShield(player, 1)
    elseif player:getHandcardNum() > 0 then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = "zuoyou",
        cancelable = false,
      })
      if not player.dead then
        room:changeShield(player, 1)
      end
    end
  end
end
shishou:addEffect(fk.AfterSkillEffect, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shishou.name) and data.skill.name == "zuoyou" and
      player:getMark("zuoyou-phase") ~= player.id
  end,
  on_use = function(self, event, target, player, data)
    local status = player:getSwitchSkillState("zuoyou") == fk.SwitchYang and "yang" or "yin"
    DoZuoyou(player, status)
  end,
})

return shishou
