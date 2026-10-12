local extension = Package:new("hegemony_nos")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/hegemony_nos/skills")

Fk:loadTranslationTable{
  ["hegemony_nos"] = "国战经典版",
  ["nos_heg"] = "国战·旧",
}

local yuejin = General:new(extension, "nos_heg__yuejin", "wei", 4)
yuejin:addSkill("nos_heg__xiaoguo")
yuejin:addCompanions("ld__lidian")
Fk:loadTranslationTable{
  ["nos_heg__yuejin"] = "乐进",
  ["#nos_heg__yuejin"] = "奋强突固",
  ["illustrator:nos_heg__yuejin"] = "巴萨小马",

  ["~nos_heg__yuejin"] = "箭疮发作，吾命休矣。",
}

General(extension, "nos_heg__ganfuren", "shu", 3, 3, General.Female):addSkills{ "nos_heg__shushen", "nos_heg__shenzhi" }
Fk:loadTranslationTable{
  ["nos_heg__ganfuren"] = "甘夫人",
  ["#nos_heg__ganfuren"] = "昭烈皇后",
  ["illustrator:nos_heg__ganfuren"] = "琛·美弟奇",
  ["designer:nos_heg__ganfuren"] = "淬毒",

  ["~nos_heg__ganfuren"] = "请替我照顾好阿斗……",
}

local luxun = General:new(extension, "nos_heg__luxun", "wu", 3)
luxun:addSkills{ "hs__qianxun", "nos_heg__duoshi" }
luxun:addCompanions{ "nos_heg__lukang" }
Fk:loadTranslationTable{
  ["nos_heg__luxun"] = "陆逊",
  ["#nos_heg__luxun"] = "擎天之柱",
	["illustrator:nos_heg__luxun"] = "depp",

  ["~nos_heg__luxun"] = "我的未竟之业……",
}

General:new(extension, "nos_heg__sunshangxiang", "wu", 3, 3, General.Female):addSkills{ "xiaoji", "jieyin" }
Fk:loadTranslationTable{
  ["nos_heg__sunshangxiang"] = "孙尚香",
  ["#nos_heg__sunshangxiang"] = "弓腰姬",
  ["illustrator:nos_heg__sunshangxiang"] = "KayaK",

  ["~nos_heg__sunshangxiang"] = "不！还不可以死！",
}

local lvbu = General:new(extension, "nos_heg__lvbu", "qun", 5)
lvbu:addSkills{ "wushuang" }
lvbu:addCompanions{ "hs__diaochan" }
Fk:loadTranslationTable{
  ["nos_heg__lvbu"] = "吕布",
  ["#nos_heg__lvbu"] = "武的化身",
	["illustrator:nos_heg__lvbu"] = "LiuHeng",

  ["~nos_heg__lvbu"] = "不可能！",
}

General:new(extension, "nos_heg__panfeng", "qun", 4):addSkills{ "nos_heg__kuangfu" }
Fk:loadTranslationTable{
  ["nos_heg__panfeng"] = "潘凤",
  ["#nos_heg__panfeng"] = "联军上将",
	["illustrator:nos_heg__panfeng"] = "地狱许",

  ["~nos_heg__panfeng"] = "潘凤又被华雄斩了。",
}

local caohong = General:new(extension, "nos_heg__caohong", "wei", 4)
caohong:addSkills{ "nos_heg__huyuan", "nos_heg__heyi" }
caohong:addCompanions("hs__caoren")
Fk:loadTranslationTable{
  ["nos_heg__caohong"] = "曹洪",
  ["#nos_heg__caohong"] = "魏之福将",
  ["illustrator:nos_heg__caohong"] = "LiuHeng",
  ["designer:nos_heg__caohong"] = "韩旭（淬毒）",
  ["cv:nos_heg__caohong"] = "绯川陵彦",

  ["~nos_heg__caohong"] = "曹公，可安好……",
}

local xusheng = General:new(extension, "nos_heg__xusheng", "wu", 4)
xusheng:addSkills{ "nos_heg__yicheng" }
xusheng:addCompanions("hs__dingfeng")
Fk:loadTranslationTable{
  ["nos_heg__xusheng"] = "徐盛",
  ["#nos_heg__xusheng"] = "江东的铁壁",
  ["designer:nos_heg__xusheng"] = "淬毒",
  ["illustrator:nos_heg__xusheng"] = "刘周",

  ["~nos_heg__xusheng"] = "",
}

General:new(extension, "nos_heg__chenwudongxi", "wu", 4):addSkills{ "ty__duanxie", "ty__fenming" }
Fk:loadTranslationTable{
  ["nos_heg__chenwudongxi"] = "陈武董袭",
  ["#nos_heg__chenwudongxi"] = "壮怀激烈",
  ["designer:nos_heg__chenwudongxi"] = "淬毒",
  ["illustrator:nos_heg__chenwudongxi"] = "君桓文化",

  ["~nos_heg__chenwudongxi"] = "杀身卫主，死而无憾！",
}

General:new(extension, "nos_heg__zhangren", "qun", 4):addSkills{ "chuanxin", "nos_heg__fengshi" }
Fk:loadTranslationTable{
  ["nos_heg__zhangren"] = "张任",
  ["#nos_heg__zhangren"] = "索命神射",
  ["designer:nos_heg__zhangren"] = "淬毒",
  ["illustrator:nos_heg__zhangren"] = "君桓文化",

  ["~nos_heg__zhangren"] = "本将军败于诸葛，无憾……",
}

local bianfuren = General:new(extension, "nos_heg__bianfuren", "wei", 3)
bianfuren:addCompanions("hs__caocao")
bianfuren:addSkills{ "nos_heg__wanwei", "nos_heg__yuejian" }
Fk:loadTranslationTable{
  ["nos_heg__bianfuren"] = "卞夫人",
  ["#nos_heg__bianfuren"] = "奕世之雍容",
  ["illustrator:nos_heg__bianfuren"] = "罔両",

  ["~nos_heg__bianfuren"] = "子桓，兄弟之情，不可轻忘……",
}

General:new(extension, "nos_heg__lvfan", "wu", 3):addSkills{ "nos_heg__diaodu", "diancai" }
Fk:loadTranslationTable{
  ["nos_heg__lvfan"] = "吕范",
  ["#nos_heg__lvfan"] = "忠笃亮直",
  ["designer:nos_heg__lvfan"] = "韩旭",
  ["illustrator:nos_heg__lvfan"] = "铭zmy",

  ["~nos_heg__lvfan"] = "闻主公欲授大司马之职，容臣不能……谢恩了……",
}

local lukang = General:new(extension, "nos_heg__lukang", "wu", 3)
lukang:addSkills{ "nos_heg__keshou", "nos_heg__zhuwei" }
lukang:addCompanions("hs__luxun")
Fk:loadTranslationTable{
  ["nos_heg__lukang"] = "陆抗",
  ["#nos_heg__lukang"] = "孤柱扶厦",
  ["illustrator:nos_heg__lukang"] = "zoo",

  ["~nos_heg__lukang"] = "吾既亡矣，又能存几时……",
}

return extension
