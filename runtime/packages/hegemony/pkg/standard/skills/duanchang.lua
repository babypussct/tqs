local duanchang = fk.CreateSkill{
  name = "hs__duanchang",
  tags = {Skill.Compulsory},
}
duanchang:addEffect(fk.Death, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duanchang.name, false, true) and data.killer and not data.killer.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.killer
    if not to or to.dead then return end
    local choices = {}
    if not to.general:startsWith("blank_") then
      table.insert(choices, to.general ~= "anjiang" and to.general or "mainGeneral")
    end
    if not to.deputyGeneral:startsWith("blank_") then
      table.insert(choices, to.deputyGeneral ~= "anjiang" and to.deputyGeneral or "deputyGeneral")
    end
    if #choices == 0 then return false end
    local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = duanchang.name,
        prompt = "#hs__duanchang-ask::" .. to.id,
      })
    room:addTableMark(to, "@hs__duanchang", choice)
    local _g = (choice == "mainGeneral" or choice == to.general) and to.general or to.deputyGeneral
    if _g ~= "anjiang" then
      local skills = {}
      for _, skill_name in ipairs(Fk.generals[_g]:getSkillNameList(true)) do
        table.insertIfNeed(skills, skill_name)
      end
      if #skills > 0 then
        room:handleAddLoseSkills(to, "-"..table.concat(skills, "|-"), nil, true, false)
      end
    else
      _g = choice == "mainGeneral" and to:getMark("__heg_general") or to:getMark("__heg_deputy")
      local general = Fk.generals[_g]
      for _, s in ipairs(general:getSkillNameList()) do
        local skill = Fk.skills[s]
        to:loseFakeSkill(skill)
      end
      room:addTableMark(to, "_hs__duanchang_anjiang", _g)
    end
  end,
})
duanchang:addEffect(fk.GeneralShown, {
  can_refresh = function(self, event, target, player, data)
    if target == player and type(player:getMark("_hs__duanchang_anjiang")) == "table" then
      for _, v in pairs(data) do
        if table.contains(player:getMark("_hs__duanchang_anjiang"), v) then return true end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local skills = {}
    for _, v in pairs(data) do
      if table.contains(player:getMark("_hs__duanchang_anjiang"), v) then
        for _, skill_name in ipairs(Fk.generals[v]:getSkillNameList(true)) do
          table.insertIfNeed(skills, skill_name)
        end
        if #skills > 0 then
          player.room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, true, false)
        end
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["hs__duanchang"] = "断肠",
  [":hs__duanchang"] = "锁定技，当你死亡时，你令杀死你的角色失去一张武将牌上的所有技能。",

  ["#hs__duanchang-ask"] = "断肠：令 %dest 失去一张武将牌上的所有技能",
  ["@hs__duanchang"] = "断肠",

  ["$hs__duanchang1"] = "流落异乡愁断肠。",
  ["$hs__duanchang2"] = "日东月西兮徒相望，不得相随兮空断肠。",
}

return duanchang
