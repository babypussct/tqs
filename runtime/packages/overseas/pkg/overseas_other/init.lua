local extension = Package:new("overseas_other")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_other/skills")

Fk:loadTranslationTable{
  ["overseas_other"] = "国际服-其他",
  ["os_evil"] = "魔",
}

General:new(extension, "os_evil__quyi", "qun", 4):addSkills { "ex__tieji", "os__chongqiq", "os__fanquan" }
Fk:loadTranslationTable{
  ["os_evil__quyi"] = "魔麴义",
}

General:new(extension, "os_evil__zhouyu", "wu", 4):addSkills { "os__juyan", "os_ex__lihuo", "yingjian", "os__yiran" }
Fk:loadTranslationTable{
  ["os_evil__zhouyu"] = "魔周瑜",
}

return extension
