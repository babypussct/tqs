local extension = Package:new("zqdl")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/jin_zqdl/skills")

Fk:loadTranslationTable{
  ["zqdl"] = "国战-紫气东来",
}

local simayi = General:new(extension, "heg__simayi", "jin", 4)
simayi:addSkills { "heg__yingshis", "heg__shunfu" }
simayi:addCompanions{ "ol_heg__zhangchunhua" }
Fk:loadTranslationTable{
  ["heg__simayi"] = "司马懿",
  ["#heg__simayi"] = "应期佐命",
  ["illustrator:heg__simayi"] = "小罗没想好",

  ["~heg__simayi"] = "虎入骷冢，司马难兴。",
}

local zhangchunhua = General:new(extension, "heg__zhangchunhua", "jin", 3, 3, General.Female)
zhangchunhua:addSkills { "heg__ejue", "heg__shangshi" }
zhangchunhua:addCompanions{ "heg__simayi" }
Fk:loadTranslationTable{
  ["heg__zhangchunhua"] = "张春华",
  ["#heg__zhangchunhua"] = "锋刃染霜",
  ["illustrator:heg__zhangchunhua"] = "小罗没想好",

  ["~heg__zhangchunhua"] = "冷眸残情，孤苦为一人。",
}

local simashi = General:new(extension, "heg__simashi", "jin", 4)
simashi:addSkills { "heg__yimie", "heg__ruilve" }
simashi:addCompanions{ "ol_heg__xiahouhui", "ol_heg__yanghuiyu" }
Fk:loadTranslationTable{
  ["heg__simashi"] = "司马师",
  ["#heg__simashi"] = "睚眥侧目",
  ["illustrator:heg__simashi"] = "拉布拉卡",

  ["~heg__simashi"] = "子上，这是为兄给你打下的江山……",
}

local simazhao = General:new(extension, "heg__simazhao", "jin", 3)
simazhao:addSkills { "heg__zhaoran", "heg__beiluan" }
simazhao:addCompanions{ "ol_heg__wangyuanji" }
Fk:loadTranslationTable{
  ["heg__simazhao"] = "司马昭",
  ["#heg__simazhao"] = "天下畏威",
  ["illustrator:heg__simazhao"] = "君桓文化",

  ["~heg__simazhao"] = "司马三代，一梦成空……",
}

General:new(extension, "heg__simazhou", "jin", 4):addSkills { "heg__pojing" }
Fk:loadTranslationTable{
  ["heg__simazhou"] = "司马伷",
  ["#heg__simazhou"] = "温恭的狻猊",
  ["illustrator:heg__simazhou"] = "凝聚永恒",

  ["~heg__simazhou"] = "恩赐重物，病身难消受……",
}

General:new(extension, "heg__simaliang", "jin", 4):addSkills { "heg__gongzhi", "heg__shejus" }
Fk:loadTranslationTable{
  ["heg__simaliang"] = "司马亮",
  ["#heg__simaliang"] = "蒲牢惊啼",
  ["illustrator:heg__simaliang"] = "小罗没想好",
}

General:new(extension, "heg__simalun", "jin", 4):addSkills { "heg__zhulan", "heg__luanchang" }
Fk:loadTranslationTable{
  ["heg__simalun"] = "司马伦",
  ["simalun"] = "司马伦",
  ["#heg__simalun"] = "螭吻裂冠",
  ["illustrator:heg__simalun"] = "荆芥",
}

General:new(extension, "heg__shibao", "jin", 4):addSkill("heg__zhuosheng")
Fk:loadTranslationTable{
  ["heg__shibao"] = "石苞",
  ["#heg__shibao"] = "经国之才",
  ["illustrator:heg__shibao"] = "凝聚永恒",

  ["~heg__shibao"] = "寒门出身，难以擢升。",
}

local yanghuiyu = General:new(extension, "heg__yanghuiyu", "jin", 3, 3, General.Female)
yanghuiyu:addSkills { "heg__ciwei", "heg__caiyuan" }
yanghuiyu:addCompanions{ "heg__simashi", "ol_heg__simashi" }
Fk:loadTranslationTable{
  ["heg__yanghuiyu"] = "羊徽瑜",
  ["#heg__yanghuiyu"] = "克明礼教",
  ["illustrator:heg__yanghuiyu"] = "Jzeo",

  ["~heg__yanghuiyu"] = "韶华易老，佳容不再……",
}

local wangyuanji = General:new(extension, "heg__wangyuanji", "jin", 3, 3, General.Female)
wangyuanji:addSkills { "heg__yanxi", "heg__shiren" }
wangyuanji:addCompanions("heg__simazhao")
Fk:loadTranslationTable{
  ["heg__wangyuanji"] = "王元姬",
  ["#heg__wangyuanji"] = "垂心万物",
  ["illustrator:heg__wangyuanji"] = "六道目",

  ["~heg__wangyuanji"] = "祖父已逝，哀凄悲戚。",
}

General:new(extension, "heg__weiguan", "jin", 3):addSkills { "heg__chengxi", "heg__jiantong" }
Fk:loadTranslationTable{
  ["heg__weiguan"] = "卫瓘",
  ["#heg__weiguan"] = "忠允清识",
  ["illustrator:heg__weiguan"] = "Karneval",

  ["~heg__weiguan"] = "辞荣善终，不可求……",
}

General:new(extension, "heg__jiachong", "jin", 3):addSkills { "heg__chujue", "heg__jianzhi" }
Fk:loadTranslationTable{
  ["heg__jiachong"] = "贾充",
  ["#heg__jiachong"] = "悖逆篡弑",
  ["illustrator:heg__jiachong"] = "游漫美绘",

  ["~heg__jiachong"] = "任元褒，吾与汝势不两立！",
}

local guohuaij = General:new(extension, "heg__guohuaij", "jin", 3, 3, General.Female)
guohuaij:addSkills { "heg__zhefu", "heg__yidu" }
guohuaij:addCompanions("heg__jiachong")
Fk:loadTranslationTable{
  ["heg__guohuaij"] = "郭槐",
  ["#heg__guohuaij"] = "嫉贤妒能",
  ["illustrator:heg__guohuaij"] = "凝聚永恒",

  ["~heg__guohuaij"] = "我死后，切勿从粲、午之言。",
}

General:new(extension, "heg__wangjun", "jin", 4):addSkill("heg__chengliu")
Fk:loadTranslationTable{
  ["heg__wangjun"] = "王濬",
  ["#heg__wangjun"] = "顺流长驱",
  ["illustrator:heg__wangjun"] = "荆芥",

  ["~heg__wangjun"] = "吾功大无匹，但为浑父子所抑而已。",
}

General:new(extension, "heg__malong", "jin", 4):addSkills{ "heg__zhuanzhan", "heg__xunjim" }
Fk:loadTranslationTable{
  ["heg__malong"] = "马隆",
  ["#heg__malong"] = "困局诡阵",
  ["illustrator:heg__malong"] = "荆芥",

  ["~heg__malong"] = "惟愿长守边境，不使百姓为虏所扰。",
}

return extension
