local extension = Package:new("mobile_jsrg")
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/mobile_jsrg/skills")

Fk:loadTranslationTable{
  ["mobile_jsrg"] = "手杀-江山如故",
  ["m_js"] = "手杀江山",
}

General:new(extension, "m_js__liubei", "qun", 4):addSkills { "m_js__jishan", "zhenqiao" }
Fk:loadTranslationTable{
  ["m_js__liubei"] = "起刘备",
  ["#m_js__liubei"] = "负戎荷戈",
  ["illustrator:m_js__liubei"] = "君桓文化",

  ["$zhenqiao_m_js__liubei1"] = "剑出鞘鸣，引得龙吟海内！",
  ["$zhenqiao_m_js__liubei2"] = "鲲鹏之志，志在天下苍生！",
  ["~m_js__liubei"] = "楼桑羽葆，黄粱一梦……",
}

General:new(extension, "m_js__sunjian", "qun", 3, 4):addSkills { "pingtao", "m_js__juelie" }
Fk:loadTranslationTable{
  ["m_js__sunjian"] = "起孙坚",
  ["#m_js__sunjian"] = "拨定烈志",
  ["illustrator:m_js__sunjian"] = "凡果",

  ["$pingtao_m_js__sunjian1"] = "董贼势败在即，诸公何故不前！",
  ["$pingtao_m_js__sunjian2"] = "歃血为盟，誓诛此国贼！",
  ["~m_js__sunjian"] = "若违此誓，某必为万箭穿心……",
}

General:new(extension, "m_js__wangyun", "qun", 3):addSkills { "m_js__shelun", "m_js__fayi" }
Fk:loadTranslationTable{
  ["m_js__wangyun"] = "起王允",
  ["#m_js__wangyun"] = "居功自矜",
  ["illustrator:m_js__wangyun"] = "凡果",

  ["~m_js__wangyun"] = "罢兵不成，新乱又起，老夫当以死谢天下……",
}

return extension
