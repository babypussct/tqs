local extension = Package:new("ol_test")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_test/skills")

Fk:loadTranslationTable{
  ["ol_test"] = "OL-测试服",
}

General:new(extension, "dongtuna", "qun", 4):addSkills { "jianman" }
Fk:loadTranslationTable{
  ["dongtuna"] = "董荼那",
  ["#dongtuna"] = "铅刀拿云",
  ["designer:dongtuna"] = "大宝",
  ["illustrator:dongtuna"] = "monkey",

  ["~dongtuna"] = "孟获小儿，安敢杀我！",
}

General:new(extension, "budugen", "qun", 4):addSkills { "kouchao" }
Fk:loadTranslationTable{
  ["budugen"] = "步度根",
  ["#budugen"] = "秋城雁阵",

  ["~budugen"] = "",
}

General:new(extension, "ol__yangfeng", "qun", 4):addSkills { "jiawei", "qujia" }
Fk:loadTranslationTable{
  ["ol__yangfeng"] = "杨奉",
  --["#ol__yangfeng"] = "",

  ["~ol__yangfeng"] = "刘使君，我乃陛下亲随呀！",
}

General:new(extension, "ol__caizhenji", "wei", 3, 3, General.Female):addSkills { "kedi", "cunze" }
Fk:loadTranslationTable{
  ["ol__caizhenji"] = "蔡贞姬",
  --["#ol__caizhenji"] = "",

  ["~ol__caizhenji"] = "",
}

General:new(extension, "ol__qiaoxuan", "qun", 4):addSkills { "tingji", "xuanliu" }
Fk:loadTranslationTable{
  ["ol__qiaoxuan"] = "桥玄",
  ["#ol__qiaoxuan"] = "秉文握武",

  ["~ol__qiaoxuan"] = "瞒小子，你可听到鹿鸣呦呦？",
}

General:new(extension, "ol__fanyufeng", "qun", 3, 3, General.Female):addSkills { "zhuoyue", "qiaowu" }
Fk:loadTranslationTable{
  ["ol__fanyufeng"] = "樊氏",
  --["#ol__fanyufeng"] = "",

  ["~ol__fanyufeng"] = "",
}

General:new(extension, "ol__zhengxuan", "qun", 3):addSkills { "shixing", "dejiao" }
Fk:loadTranslationTable{
  ["ol__zhengxuan"] = "郑玄",
  ["#ol__zhengxuan"] = "弘道传德",

  ["~ol__zhengxuan"] = "汝等，汝等当慎行，慎行啊……",
}

General:new(extension, "tangtang", "qun", 3, 3, General.Female):addSkills { "zexing", "zhiyit" }
Fk:loadTranslationTable{
  ["tangtang"] = "唐棠",
  ["#tangtang"] = "伊侍佐佑",

  ["~tangtang"] = "",
}

General:new(extension, "pangji", "qun", 3):addSkills { "biguo", "douyu" }
Fk:loadTranslationTable{
  ["pangji"] = "逄纪",
  --["#pangji"] = "",

  ["~pangji"] = "",
}

General:new(extension, "huangfusong", "qun", 4):addSkills { "yanjing", "fenyue" }
Fk:loadTranslationTable{
  ["huangfusong"] = "皇甫嵩",
  --["#huangfusong"] = "",

  ["~huangfusong"] = "",
}

General:new(extension, "ol__sunhanhua", "wu", 3, 3, General.Female):addSkills { "huaguang", "xuanbai" }
Fk:loadTranslationTable{
  ["ol__sunhanhua"] = "孙寒华",
  --["#ol__sunhanhua"] = "",

  ["~ol__sunhanhua"] = "",
}

General:new(extension, "ol__xielingyu", "wu", 3, 3, General.Female):addSkills { "ol__yuandi", "ol__xinyou" }
Fk:loadTranslationTable{
  ["ol__xielingyu"] = "谢灵毓",
  --["#ol__xielingyu"] = "",

  ["~ol__xielingyu"] = "孙郎……孙郎……",
}

General:new(extension, "ol__sunlingluan", "wu", 3, 3, General.Female).hidden = true
Fk:loadTranslationTable{
  ["ol__sunlingluan"] = "孙翎鸾",
  --["#ol__sunlingluan"] = "",

  ["~ol__sunlingluan"] = "",
}

General:new(extension, "ol__gongsunkang", "qun", 4).hidden = true
Fk:loadTranslationTable{
  ["ol__gongsunkang"] = "公孙康",
  --["#ol__gongsunkang"] = "",

  ["~ol__gongsunkang"] = "",
}

General:new(extension, "huangfugui", "qun", 4):addSkills { "fujingh", "ol__quxian" }
Fk:loadTranslationTable{
  ["huangfugui"] = "皇甫规",
  --["#huangfugui"] = "",

  ["~huangfugui"] = "",
}

General:new(extension, "wangai", "wei", 4, 4, General.Female):addSkills { "qinli" }
Fk:loadTranslationTable{
  ["wangai"] = "王皑",
  --["#wangai"] = "",

  ["~wangai"] = "",
}

General:new(extension, "ol__xushao", "qun", 4):addSkills { "shilunx", "zhuoming" }
Fk:loadTranslationTable{
  ["ol__xushao"] = "许劭",
  --["#ol__xushao"] = "",

  ["~ol__xushao"] = "",
}

return extension
