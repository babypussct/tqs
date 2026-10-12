local extension = Package:new("zfxp")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/jin_zfxp/skills")

Fk:loadTranslationTable{
  ["zfxp"] = "国战-紫凤衔佩",
}

local jiananfeng = General:new(extension, "heg__jiananfeng", "wild", 3, 3, General.Female)
jiananfeng:addSkills { "heg__liaoye", "heg__fangzi", "heg__liudu" }
jiananfeng:addCompanions{ "male_generals" }
jiananfeng:addCompanionRule(function(self, other)
  return other:isMale()
end)
Fk:loadTranslationTable{
  ["heg__jiananfeng"] = "贾南风",
  ["#heg__jiananfeng"] = "窥鼎的司晨雉",
  ["illustrator:heg__jiananfeng"] = "小罗没想好",

  ["male_generals"] = "男性武将",
}

General:new(extension, "heg__simajiong", "jin", 3):addSkills { "heg__chuchong", "heg__dufu" }
Fk:loadTranslationTable{
  ["heg__simajiong"] = "司马冏",
  ["simajiong"] = "司马冏",
  ["#heg__simajiong"] = "饕餮吞国",
  ["illustrator:heg__simajiong"] = "张油菜",
}

General:new(extension, "heg__simaying", "jin", 4):addSkills { "heg__chengguan" }
Fk:loadTranslationTable{
  ["heg__simaying"] = "司马颖",
  ["simaying"] = "司马颖",
  ["#heg__simaying"] = "守壳的椒图",
  ["illustrator:heg__simaying"] = "张油菜",
}

local simayue = General:new(extension, "heg__simayue", "jin", 4)
simayue.mainMaxHpAdjustedValue = -1
simayue:addSkills { "heg__huluan", "heg__yinfu" }
Fk:loadTranslationTable{
  ["heg__simayue"] = "司马越",
  ["simayue"] = "司马越",
  ["#heg__simayue"] = "渊虬噬龙",
  ["illustrator:heg__simayue"] = "城与橙与程",
}

General:new(extension, "heg__simayong", "jin", 4):addSkills { "heg__mieyi", "heg__gouni" }
Fk:loadTranslationTable{
  ["heg__simayong"] = "司马颙",
  ["simayong"] = "司马颙",
  ["#heg__simayong"] = "幻蜃祸心",
  ["illustrator:heg__simayong"] = "王志越",
}

General:new(extension, "heg__simayij", "jin", 4):addSkills { "heg__fengguo" }
Fk:loadTranslationTable{
  ["heg__simayij"] = "司马乂",
  ["simayij"] = "司马乂",
  ["#heg__simayij"] = "孤犼擎天",
  ["illustrator:heg__simayij"] = "张油菜",
}

General:new(extension, "heg__simawei", "jin", 4):addSkills { "heg__guorui" }
Fk:loadTranslationTable{
  ["heg__simawei"] = "司马玮",
  ["simawei"] = "司马玮",
  ["#heg__simawei"] = "衔锋的貔貅",
  ["illustrator:heg__simawei"] = "张油菜",
}

return extension
