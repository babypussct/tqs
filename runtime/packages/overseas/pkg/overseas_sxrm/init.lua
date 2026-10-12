local extension = Package("overseas_sxrm")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_sxrm/skills")

Fk:loadTranslationTable{
  ["overseas_sxrm"] = "国际服-蚀心入魔",
  ["os_sx"] = "国际蚀心",
}

General:new(extension, "os_sx__caocao", "wei", 3):addSkills { "os__kuxin", "os__sigu", "os__kuimu" }
Fk:loadTranslationTable{
  ["os_sx__caocao"] = "疑曹操",
  ["#os_sx__caocao"] = "一目窥九州",
  ["illustrator:os_sx__caocao"] = "小罗没想好",

  ["!os_sx__caocao"] = "再追生之哀乐，唯此时方尽知之！",
  ["~os_sx__caocao"] = "孤尝疑有生之荣，未尝疑有死之哀……",
}

General:new(extension, "os_sx__huatuo", "qun", 4):addSkills { "os__miehai" }
Fk:loadTranslationTable{
  ["os_sx__huatuo"] = "疑华佗",
  ["#os_sx__huatuo"] = "上医医国",
  ["illustrator:os_sx__huatuo"] = "鬼画府",

  ["~os_sx__huatuo"] = "疑患不除，汝无药可医！",
}

General:new(extension, "os_sx__fuhuanghou", "qun", 3, 4, General.Female):addSkills { "os__mitu", "os__qianliu" }
Fk:loadTranslationTable{
  ["os_sx__fuhuanghou"] = "疑伏寿",
  ["#os_sx__fuhuanghou"] = "白绫蔽月",
  ["illustrator:os_sx__fuhuanghou"] = "鬼画府",

  ["~os_sx__fuhuanghou"] = "曹贼疑心，甚重，甚重……",
}

General:new(extension, "os_sx__lvmeng", "wu", 3, 4):addSkills { "kongzhi", "os__bizha" }
Fk:loadTranslationTable {
  ["os_sx__lvmeng"] = "慢吕蒙",
  ["#os_sx__lvmeng"] = "病入膏肓",
  ["illustrator:os_sx__lvmeng"] = "小罗没想好",
}

General:new(extension, "os_sx__luxun", "wu", 3, 4):addSkills { "os__chanyu", "os__congfeng" }
Fk:loadTranslationTable {
  ["os_sx__luxun"] = "慢陆逊",
  ["#os_sx__luxun"] = "孺子为将",
  ["illustrator:os_sx__luxun"] = "小罗没想好",
}

return extension
