
local yizhi = fk.CreateSkill{
  name = "yizhi",
  tags = { Skill.DeputyPlace },
  related_skills = { "ld__guanxing" },
}

Fk:loadTranslationTable{
  ["yizhi"] = "遗志",
  [":yizhi"] = "副将技，你计算体力上限时减少一个单独的阴阳鱼。若你的主将的武将牌处于明置状态且拥有〖观星〗，则将此〖观星〗描述中的X改为5，"..
  "否则你视为拥有〖观星〗。",
}

local spec = {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    local yes = false
    for _, sname in ipairs(Fk.generals[player.general]:getSkillNameList()) do
      if Fk.skills[sname].trueName == "guanxing" then
        yes = true
        break
      end
    end
    local ret = player:hasShownSkill(yizhi.name) and not (yes and player.general ~= "anjiang")
    player.room:handleAddLoseSkills(player, ret and "ld__guanxing" or "-ld__guanxing", nil, false, true)
  end
}

yizhi:addEffect(fk.GeneralRevealed, spec)
yizhi:addEffect(fk.GeneralHidden, spec)
yizhi:addEffect(fk.EventLoseSkill, spec)
yizhi:addEffect(fk.EventAcquireSkill, spec)

return yizhi
