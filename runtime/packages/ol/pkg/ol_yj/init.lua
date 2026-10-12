local extension = Package:new("ol_yj")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_yj/skills")

Fk:loadTranslationTable {
  ["ol_yj"] = "OL-一将",
}

General:new(extension, "ol__gaoshun", "qun", 4):addSkills { "ol__xianzhen", "ol_jinjiu"}
Fk:loadTranslationTable{
  ["ol__gaoshun"] = "高顺",
  ["#ol__gaoshun"] = "攻无不克", 
  ["illustrator:ol__gaoshun"] = "蛋费鸡丁",
  ["~ol__gaoshun"] = "可叹主公知而不用啊！",
}

General:new(extension, "ol__yujin", "wei", 4):addSkills { "ol__zhenjun" }
Fk:loadTranslationTable{
  ["ol__yujin"] = "于禁",
  ["#ol__yujin"] = "弗克其终",
  ["illustrator:ol__yujin"] = "makail",

  ["~ol__yujin"] = "洪水滔天，大势已去……",
}

General:new(extension, "ol__masu", "shu", 3):addSkills { "ol__sanyao", "ty_ex__zhiman" }
Fk:loadTranslationTable{
  ["ol__masu"] = "马谡",
  ["#ol__masu"] = "军略之才器",
  ["designer:ol__masu"] = "豌豆帮帮主",
  ["illustrator:ol__masu"] = "鬼画府",

  ["$ty_ex__zhiman_ol__masu1"] = "覆军杀将非良策也，当服其心以求长远。",
  ["$ty_ex__zhiman_ol__masu2"] = "欲平南中之叛，当以攻心为上。",
  ["~ol__masu"] = "悔不听王平之言，铸此大错……",
}

General:new(extension, "ol__guohuai", "wei", 3):addSkills { "ol__jingce" }
Fk:loadTranslationTable{
  ["ol__guohuai"] = "郭淮",
  ["#ol__guohuai"] = "垂问秦雍",
  ["illustrator:ol__guohuai"] = "张帅",

  ["~ol__guohuai"] = "穷寇莫追……",
}

General:new(extension, "ol__caozhen", "wei", 4):addSkills { "ol__sidi" }
Fk:loadTranslationTable{
  ["ol__caozhen"] = "曹真",
  ["#ol__caozhen"] = "荷国天督",
  ["illustrator:ol__caozhen"] = "biou09",

  ["~ol__caozhen"] = "三马共槽，养虎为患哪！",
}

General:new(extension, "ol__zhoucang", "shu", 4):addSkills { "ol__zhongyong" }
Fk:loadTranslationTable{
  ["ol__zhoucang"] = "周仓",
  ["#ol__zhoucang"] = "披肝沥胆",
  ["illustrator:ol__zhoucang"] = "NOVART",

  ["~ol__zhoucang"] = "鞍前马后，我必舍身。",
}

General:new(extension, "ol__guyong", "wu", 3):addSkills { "shenxing", "ol__bingyi" }
Fk:loadTranslationTable{
  ["ol__guyong"] = "顾雍",
  ["#ol__guyong"] = "庙堂的玉磐",
  ["designer:ol__guyong"] = "玄蝶既白",
  ["illustrator:ol__guyong"] = "Sky",

  ["$shenxing_ol__guyong1"] = "上兵伐谋，三思而行。",
  ["$shenxing_ol__guyong2"] = "精益求精，慎之再慎。",
  ["~ol__guyong"] = "此番患疾，吾必不起……",
}

General:new(extension, "ol__quancong", "wu", 4):addSkill("ol__yaoming")
Fk:loadTranslationTable{
  ["ol__quancong"] = "全琮",
  ["#ol__quancong"] = "钱唐侯",
  ["illustrator:ol__quancong"] = "种风彦",

  ["~ol__quancong"] = "患难可共进，生死不同当。",
}

General:new(extension, "ol__jikang", "wei", 3):addSkills { "ol__qingxian", "ol__juexiang" }
Fk:loadTranslationTable{
  ["ol__jikang"] = "嵇康",
  ["#ol__jikang"] = "峻峰孤松",
  ["illustrator:ol__jikang"] = "凝聚永恒",

  ["~ol__jikang"] = "曲终人散，空留余音……",
}

General:new(extension, "ol__xinxianying", "wei", 3, 3, General.Female):addSkills { "ol__zhongjian", "ol__caishi" }
Fk:loadTranslationTable{
  ["ol__xinxianying"] = "辛宪英",
  ["#ol__xinxianying"] = "名门智女",
  ["designer:ol__xinxianying"] = "如释帆飞",
  ["illustrator:ol__xinxianying"] = "凝聚永恒",

  ["~ol__xinxianying"] = "料人如神，而难自知啊……",
}

return extension
