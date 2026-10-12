local weitong = fk.CreateSkill {
  name = "weitong",
  tags = { Skill.Lord, Skill.Permanent },
}

Fk:loadTranslationTable{
  ["weitong"] = "卫统",
  [":weitong"] = "持恒技，主公技，若场上有存活的其他魏势力角色，则你的〖潜龙〗于游戏开始时获得的道心值改为60点。",

  ["$weitong1"] = "手无实权难卫统，朦胧成睡，睡去还惊。",
}

weitong:addEffect("targetmod", {
})

return weitong
