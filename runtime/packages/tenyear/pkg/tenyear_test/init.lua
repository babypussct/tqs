local extension = Package:new("tenyear_test")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_test/skills")

Fk:loadTranslationTable{
  ["tenyear_test"] = "十周年-测试服",
}

General:new(extension, "luwenyi", "wu", 3, 3, General.Female):addSkills { "caiyun", "qieyan" }
Fk:loadTranslationTable{
  ["luwenyi"] = "陆文漪",
  ["#luwenyi"] = "卷中避世",

  --["~luwenyi"] = "",
}

General:new(extension, "cuizhi", "shu", 4, 4, General.Female):addSkills { "ranlv", "juexun" }
Fk:loadTranslationTable{
  ["cuizhi"] = "崔芷",
  ["#cuizhi"] = "烈烛烬明",

  --["~cuizhi"] = "",
}

General:new(extension, "sunhe", "wu", 4):addSkills { "guanchong", "chanchu" }
Fk:loadTranslationTable{
  ["sunhe"] = "孙和",
  ["#sunhe"] = "位废南鲁",

  --["~sunhe"] = "",
}

General:new(extension, "ty__feiyi", "shu", 3):addSkills { "qiansu", "xingbang", "fanhuo" }
Fk:loadTranslationTable{
  ["ty__feiyi"] = "费祎",
  ["#ty__feiyi"] = "宽济尽忠",

  --["~ty__feiyi"] = "",
}

General:new(extension, "ty__jiangwan", "shu", 3):addSkills { "fangzheng", "juzhen" }
Fk:loadTranslationTable{
  ["ty__jiangwan"] = "蒋琬",
  ["#ty__jiangwan"] = "社稷之器",

  --["~ty__jiangwan"] = "",
}

General:new(extension, "ty__wangyuanji", "wei", 3, 3, General.Female):addSkills { "ty__shiyu", "shuaijian" }
Fk:loadTranslationTable{
  ["ty__wangyuanji"] = "王元姬",
  ["#ty__wangyuanji"] = "素业谦冲",

  --["~ty__wangyuanji"] = "",
}

General:new(extension, "ty__sunjun", "wu", 5):addSkills { "ty__beizhu" }
Fk:loadTranslationTable{
  ["ty__sunjun"] = "孙峻",
  ["#ty__sunjun"] = "骄矜险害",

  --["~ty__sunjun"] = "",
}

General:new(extension, "ty__zhangzhao", "wu", 3):addSkills { "zuozheng", "hongmin" }
Fk:loadTranslationTable{
  ["ty__zhangzhao"] = "张昭",
  ["#ty__zhangzhao"] = "威德翕赫",

  --["~ty__zhangzhao"] = "",
}

General:new(extension, "ty__qiaogong", "wu", 4):addSkills { "huaishu", "ty__yizhu" }
Fk:loadTranslationTable{
  ["ty__qiaogong"] = "桥公",
  ["#ty__qiaogong"] = "崧岳执柯",

  --["~ty__qiaogong"] = "",
}

General:new(extension, "ty__lvboshe", "qun", 8):addSkills { "shiyan", "kuijue" }
Fk:loadTranslationTable{
  ["ty__lvboshe"] = "吕伯奢",
  ["#ty__lvboshe"] = "恩罹横灾",

  --["~ty__lvboshe"] = "",
}

General:new(extension, "ty__luoxian", "shu", 5):addSkills { "xishi", "qingshou" }
Fk:loadTranslationTable{
  ["ty__luoxian"] = "罗宪",
  ["#ty__luoxian"] = "忠烈果毅",

  --["~ty__luoxian"] = "",
}

General:new(extension, "wangfurenl", "wu", 4, 4, General.Female):addSkills { "zaozen", "zhuiyiw" }
Fk:loadTranslationTable{
  ["wangfurenl"] = "王笙",
  ["#wangfurenl"] = "承嗣尊后",

  --["~wangfurenl"] = "",
}

General:new(extension, "liuzhen", "wei", 3):addSkills { "wujue", "zhengul" }
Fk:loadTranslationTable{
  ["liuzhen"] = "刘桢",
  ["#liuzhen"] = "妙绝时人",

  --["~liuzhen"] = "",
}

General:new(extension, "lixians", "shu", 4, 4, General.Female):addSkills { "chidai", "yijiel" }
Fk:loadTranslationTable{
  ["lixians"] = "李娴",
  ["#lixians"] = "义忠烈妇",

  --["~lixians"] = "",
}

General:new(extension, "ty__zhangzhongjing", "qun", 3):addSkills { "ty__binglun", "zuotang" }
Fk:loadTranslationTable{
  ["ty__zhangzhongjing"] = "张仲景",
  ["#ty__zhangzhongjing"] = "",

  --["~ty__zhangzhongjing"] = "",
}

return extension
