local extension = Package:new("tenyear_heg")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/tenyear_heg/skills")

Fk:loadTranslationTable{
  ["tenyear_heg"] = "国战-十周年专属",
  ["ty_heg"] = "新服国战",
  ["ty_heg_zongheng"] = "<b>纵横：</b><br>当拥有“纵横”效果技能发动结算完成后，可以令技能目标角色获得对应修订描述后的技能，直到其下回合结束。",
}

General:new(extension, "ty_heg__huaxin", "wei", 3):addSkills{ "ty_heg__wanggui", "ty_heg__xibing" }
Fk:loadTranslationTable{
  ["ty_heg__huaxin"] = "华歆",
  ["#ty_heg__huaxin"] = "渊清玉洁",
  ["designer:ty_heg__huaxin"] = "韩旭",
  ["illustrator:ty_heg__huaxin"] = "秋呆呆",
  ["~ty_heg__huaxin"] = "大举发兵，劳民伤国。",
}

General:new(extension, "ty_heg__luyusheng", "wu", 3, 3, General.Female):addSkills{"ty_heg__zhente", "ty_heg__zhiwei"}
Fk:loadTranslationTable{
  ["ty_heg__luyusheng"] = "陆郁生",
  ["#ty_heg__luyusheng"] = "义姑",
  ["designer:ty_heg__luyusheng"] = "韩旭",
  ["illustrator:ty_heg__luyusheng"] = "君桓文化",
  ["~ty_heg__luyusheng"] = "父亲，郁生甚是想念……",
}

General:new(extension, "ty_heg__zongyu", "shu", 3):addSkills{ "ty_heg__qiao", "ty_heg__chengshang" }
Fk:loadTranslationTable{
  ["ty_heg__zongyu"] = "宗预",
  ["#ty_heg__zongyu"] = "九酝鸿胪",
  ["designer:ty_heg__zongyu"] = "韩旭",
  ["illustrator:ty_heg__zongyu"] = "铁杵文化",
  ["~ty_heg__zongyu"] = "吾年逾七十，唯少一死耳……",
}

local miheng = General:new(extension, "ty_heg__miheng", "qun", 3)
miheng:addCompanions("hs__kongrong")
miheng:addSkills{"ty_heg__kuangcai", "ty_heg__shejian"}
Fk:loadTranslationTable{
  ["ty_heg__miheng"] = "祢衡",
  ["#ty_heg__miheng"] = "狂傲奇人",
  ["designer:ty_heg__miheng"] = "韩旭",
  ["illustrator:ty_heg__miheng"] = "MuMu",
  ["~ty_heg__miheng"] = "恶口……终致杀身……",
}

General:new(extension, "ty_heg__fengxiw", "wu", 3):addSkills{"ty_heg__yusui", "ty_heg__boyan"}
Fk:loadTranslationTable{
  ["ty_heg__fengxiw"] = "冯熙",
  ["#ty_heg__fengxiw"] = "东吴苏武",
  ["designer:ty_heg__fengxiw"] = "韩旭",
  ["illustrator:ty_heg__fengxiw"] = "匠人绘",
  ["~ty_heg__fengxiw"] = "乡音未改双鬓苍，身陷北国有义求。",
}

General:new(extension, "ty_heg__dengzhi", "shu", 3):addSkills{"ty_heg__jianliang", "ty_heg__weimeng"}
Fk:loadTranslationTable{
  ["ty_heg__dengzhi"] = "邓芝",
  ["#ty_heg__dengzhi"] = "绝境的外交家",
  ["designer:ty_heg__dengzhi"] = "韩旭",
  ["illustrator:ty_heg__dengzhi"] = "凝聚永恒",
  ["~ty_heg__dengzhi"] = "伯约啊，我帮不了你了……",
}

General:new(extension, "ty_heg__xunchen", "qun", 3):addSkills{"ty_heg__fenglve", "ty_heg__anyong"}
Fk:loadTranslationTable{
  ["ty_heg__xunchen"] = "荀谌",
  ["#ty_heg__xunchen"] = "三公谋主",
  ["designer:ty_heg__xunchen"] = "韩旭",
  ["illustrator:ty_heg__xunchen"] = "凝聚永恒",
  ["~ty_heg__xunchen"] = "为臣当不贰，贰臣不当为。",
}

General:new(extension, "ty_heg__yanghu", "wei", 3):addSkills{ "ty_heg__deshao", "ty_heg__mingfa" }
Fk:loadTranslationTable{
  ["ty_heg__yanghu"] = "羊祜",
  ["#ty_heg__yanghu"] = "制纮同轨",
  ["designer:ty_heg__yanghu"] = "韩旭",
  ["illustrator:ty_heg__yanghu"] = "匠人绘",
  ["~ty_heg__yanghu"] = "臣死之后，杜元凯可继之……",
}

General:new(extension, "ty_heg__jianggan", "wei", 3):addSkills{ "ty_heg__weicheng", "ty_heg__daoshu" }
Fk:loadTranslationTable{
  ["ty_heg__jianggan"] = "蒋干",
  ["#ty_heg__jianggan"] = "锋谪悬信",
  ["designer:ty_heg__jianggan"] = "韩旭",
  ["illustrator:ty_heg__jianggan"] = "biou09",
  ["~ty_heg__jianggan"] = "丞相，再给我一次机会啊！",
}

General:new(extension, "ty_heg__nanhualaoxian", "qun", 4):addSkills{ "ty_heg__gongxiu", "ty_heg__jinghe" }
Fk:loadTranslationTable{
  ["ty_heg__nanhualaoxian"] = "南华老仙",
  ["#ty_heg__nanhualaoxian"] = "仙人指路",
  ["designer:ty_heg__nanhualaoxian"] = "韩旭",
  ["illustrator:ty_heg__nanhualaoxian"] = "君桓文化",
  ["~ty_heg__nanhualaoxian"] = "道亦有穷时……",
}

local lvlingqi = General:new(extension, "ty_heg__lvlingqi", "qun", 4,4,General.Female)
lvlingqi.mainMaxHpAdjustedValue = -1
lvlingqi:addSkills{ "ty_heg__guowu", "ty_heg__zhuangrong", "ty_heg__shenwei" }
Fk:loadTranslationTable{
  ["ty_heg__lvlingqi"] = "吕玲绮",
  ["#ty_heg__lvlingqi"] = "无双虓姬",
  ["designer:ty_heg__lvlingqi"] = "xat1k",
  ["illustrator:ty_heg__lvlingqi"] = "君桓文化",
  ["~ty_heg__lvlingqi"] = "父亲，女儿好累……",
}

local yangwan = General:new(extension, "ty_heg__yangwan", "shu", 3, 3, General.Female)
yangwan:addSkills{ "ty_heg__youyan", "ty_heg__zhuihuan" }
yangwan:addCompanions("hs__machao")
Fk:loadTranslationTable{
  ["ty_heg__yangwan"] = "杨婉",
  ["#ty_heg__yangwan"] = "融沫之鲡",
  ["illustrator:ty_heg__yangwan"] = "木美人",
  ["~ty_heg__yangwan"] = "遇人不淑……",
}

General:new(extension, "ty_heg__zhouyi", "wu", 3, 3, General.Female):addSkills{ "ty_heg__zhukou", "ty_heg__duannian", "ty_heg__lianyou" }
Fk:loadTranslationTable{
  ["ty_heg__zhouyi"] = "周夷",
  ["#ty_heg__zhouyi"] = "靛情雨黛",
  ["designer:ty_heg__zhouyi"] = "韩旭",
  ["illustrator:ty_heg__zhouyi"] = "Tb罗根",
  ["~ty_heg__zhouyi"] = "江水寒，萧瑟起……",
}

return extension
