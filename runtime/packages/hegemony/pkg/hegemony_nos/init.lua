local extension = Package:new("hegemony_nos")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/hegemony_nos/skills")

Fk:loadTranslationTable{
  ["hegemony_nos"] = "国战经典版",
  ["nos_heg"] = "国战·旧",
}

local generals = {}  --绕过变量上限的东西

generals.nos_heg__yuejin = General:new(extension, "nos_heg__yuejin", "wei", 4)
generals.nos_heg__yuejin:addSkill("nos_heg__xiaoguo")
generals.nos_heg__yuejin:addCompanions("ld__lidian")
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

generals.nos_heg__luxun = General:new(extension, "nos_heg__luxun", "wu", 3)
generals.nos_heg__luxun:addSkills{ "hs__qianxun", "nos_heg__duoshi" }
generals.nos_heg__luxun:addCompanions{ "nos_heg__lukang" }
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

generals.nos_heg__lvbu = General:new(extension, "nos_heg__lvbu", "qun", 5)
generals.nos_heg__lvbu:addSkills{ "wushuang" }
generals.nos_heg__lvbu:addCompanions{ "hs__diaochan" }
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

generals.nos_heg__caohong = General:new(extension, "nos_heg__caohong", "wei", 4)
generals.nos_heg__caohong:addSkills{ "nos_heg__huyuan", "nos_heg__heyi" }
generals.nos_heg__caohong:addCompanions("hs__caoren")
Fk:loadTranslationTable{
  ["nos_heg__caohong"] = "曹洪",
  ["#nos_heg__caohong"] = "魏之福将",
  ["illustrator:nos_heg__caohong"] = "LiuHeng",
  ["designer:nos_heg__caohong"] = "韩旭（淬毒）",
  ["cv:nos_heg__caohong"] = "绯川陵彦",

  ["~nos_heg__caohong"] = "曹公，可安好……",
}

generals.nos_heg__xusheng = General:new(extension, "nos_heg__xusheng", "wu", 4)
generals.nos_heg__xusheng:addSkills{ "nos_heg__yicheng" }
generals.nos_heg__xusheng:addCompanions("hs__dingfeng")
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
  ["illustrator:nos_heg__chenwudongxi"] = "彭宇",

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

generals.nos_heg__bianfuren = General:new(extension, "nos_heg__bianfuren", "wei", 3)
generals.nos_heg__bianfuren:addCompanions("hs__caocao")
generals.nos_heg__bianfuren:addSkills{ "nos_heg__wanwei", "nos_heg__yuejian" }
Fk:loadTranslationTable{
  ["nos_heg__bianfuren"] = "卞夫人",
  ["#nos_heg__bianfuren"] = "奕世之雍容",
  ["illustrator:nos_heg__bianfuren"] = "HEI-LEI",

  ["~nos_heg__bianfuren"] = "子桓，兄弟之情，不可轻忘……",
}

General:new(extension, "nos_heg__lvfan", "wu", 3):addSkills{ "nos_heg__diaodu", "diancai" }
Fk:loadTranslationTable{
  ["nos_heg__lvfan"] = "吕范",
  ["#nos_heg__lvfan"] = "忠笃亮直",
  ["designer:nos_heg__lvfan"] = "韩旭",
  ["illustrator:nos_heg__lvfan"] = "鬼画府",

  ["~nos_heg__lvfan"] = "闻主公欲授大司马之职，容臣不能……谢恩了……",
}

generals.nos_heg__lukang = General:new(extension, "nos_heg__lukang", "wu", 3)
generals.nos_heg__lukang:addSkills{ "nos_heg__keshou", "nos_heg__zhuwei" }
generals.nos_heg__lukang:addCompanions("hs__luxun")
Fk:loadTranslationTable{
  ["nos_heg__lukang"] = "陆抗",
  ["#nos_heg__lukang"] = "孤柱扶厦",
  ["illustrator:nos_heg__lukang"] = "zoo",

  ["~nos_heg__lukang"] = "吾既亡矣，又能存几时……",
}

General:new(extension, "nos_heg__zhuling", "wei", 4):addSkills{ "nos_heg__juejue", "nos_heg__fangyuan" }
Fk:loadTranslationTable{
  ["nos_heg__zhuling"] = "朱灵",
  ["#nos_heg__zhuling"] = "五子之亚",
  ["illustrator:nos_heg__zhuling"] = "NOVART",

  ["~nos_heg__zhuling"] = "母亲，弟弟，我来了……",
}

General:new(extension, "nos_heg__liuba", "shu", 3):addSkills{ "nos_heg__tongdu", "nos_heg__qingyin" }
Fk:loadTranslationTable{
  ["nos_heg__liuba"] = "刘巴",
  ["#nos_heg__liuba"] = "清河一鲲",
  ["illustrator:nos_heg__liuba"] = "君桓文化",
  ["designer:nos_heg__liuba"] = "逍遥鱼叔",

  ["~nos_heg__liuba"] = "家国将逢巨变，奈何此身先陨。",
}

General:new(extension, "nos_heg__wujing", "wu", 4):addSkills{ "nos_heg__diaogui", "ld__fengyang" }
Fk:loadTranslationTable{
  ["nos_heg__wujing"] = "吴景",
  ["#nos_heg__wujing"] = "汗马鎏金",
  ["illustrator:nos_heg__wujing"] = "匠人绘",
  ["designer:nos_heg__wujing"] = "逍遥鱼叔",
  ["cv:nos_heg__wujing"] = "虞晓旭",

  ["~nos_heg__wujing"] = "憾未能见，我江东一统天下之时……",
}

generals.nos_heg__zhugeke = General:new(extension, "nos_heg__zhugeke", "wu", 3)
generals.nos_heg__zhugeke:addCompanions("hs__dingfeng")
generals.nos_heg__zhugeke:addSkills{ "ld__aocai", "nos_heg__duwu" }
Fk:loadTranslationTable{
  ["nos_heg__zhugeke"] = "诸葛恪",
  ["#nos_heg__zhugeke"] = "兴家赤族",
  ["illustrator:nos_heg__zhugeke"] = "大佬荣",
  ["designer:nos_heg__zhugeke"] = "逍遥鱼叔",

  ["~nos_heg__zhugeke"] = "重权震主，是我疏忽了……",
}

generals.nos_heg__yanbaihu = General:new(extension, "nos_heg__yanbaihu", "qun", 4)
generals.nos_heg__yanbaihu.deputyMaxHpAdjustedValue = -1
generals.nos_heg__yanbaihu:addSkills{ "nos_heg__zhidao", "nos_heg__jilix" }
Fk:loadTranslationTable{
  ["nos_heg__yanbaihu"] = "严白虎",
  ["#nos_heg__yanbaihu"] = "豺牙落涧",
  ["designer:nos_heg__yanbaihu"] = "逍遥鱼叔",
  ["illustrator:nos_heg__yanbaihu"] = "NOVART",

  ["~nos_heg__yanbaihu"] = "江东，有我…一半…",
}

generals.nos_heg__mengda = General:new(extension, "nos_heg__mengda", "shu", 4)
generals.nos_heg__mengda.subkingdom = "wei"
generals.nos_heg__mengda:addSkills{ "nos_heg__qiuan", "nos_heg__liangfan" }
Fk:loadTranslationTable{
  ["nos_heg__mengda"] = "孟达",
  ["#nos_heg__mengda"] = "怠军反复",
  ["illustrator:nos_heg__mengda"] = "匠人绘",
  ["designer:nos_heg__mengda"] = "韩旭",

  ["~nos_heg__mengda"] = "吾一生寡信，今报应果然来矣…",
}

generals.nos_heg__zhanglu = General:new(extension, "nos_heg__zhanglu", "qun", 3)
generals.nos_heg__zhanglu.subkingdom = "wei"
generals.nos_heg__zhanglu:addSkills{ "nos_heg__bushi", "nos_heg__midao" }
Fk:loadTranslationTable{
  ["nos_heg__zhanglu"] = "张鲁",
  ["#nos_heg__zhanglu"] = "政宽教惠",
  ["illustrator:nos_heg__zhanglu"] = "銘zmy",

  ["~nos_heg__zhanglu"] = "唉，义不敌武，道难御兵……",
}

generals.nos_heg__mifangfushiren = General:new(extension, "nos_heg__mifangfushiren", "shu", 4)
generals.nos_heg__mifangfushiren.subkingdom = "wu"
generals.nos_heg__mifangfushiren:addSkills{ "nos_heg__fengshih" }
Fk:loadTranslationTable{
  ["nos_heg__mifangfushiren"] = "糜芳傅士仁",
  ["#nos_heg__mifangfushiren"] = "逐驾迎尘",
  ["designer:nos_heg__mifangfushiren"] = "Loun老萌",
  ["illustrator:nos_heg__mifangfushiren"] = "游漫美绘",

  ["~nos_heg__mifangfushiren"] = "虞翻小儿，你安敢辱我！",
}

generals.nos_heg__liuqi = General:new(extension, "nos_heg__liuqi", "qun", 3)
generals.nos_heg__liuqi.subkingdom = "shu"
generals.nos_heg__liuqi:addSkills{ "nos_heg__wenji", "nos_heg__tunjiang" }
Fk:loadTranslationTable{
  ["nos_heg__liuqi"] = "刘琦",
  ["#nos_heg__liuqi"] = "居外而安",
  ["illustrator:nos_heg__liuqi"] = "NOVART",
  ["designer:nos_heg__liuqi"] = "荼蘼（韩旭）",

  ["~nos_heg__liuqi"] = "父亲，孩儿来，见你了。",
}

generals.nos_heg__tangzi = General:new(extension, "nos_heg__tangzi", "wei", 4)
generals.nos_heg__tangzi.subkingdom = "wu"
generals.nos_heg__tangzi:addSkills{ "nos_heg__xingzhao" }
Fk:loadTranslationTable{
  ["nos_heg__tangzi"] = "唐咨",
  ["#nos_heg__tangzi"] = "得时识风",
  ["illustrator:nos_heg__tangzi"] = "NOVART",
  ["designer:nos_heg__tangzi"] = "荼蘼（韩旭）",

  ["~nos_heg__tangzi"] = "偷工减料，要不得啊…",
}

generals.nos_heg__wenqin = General:new(extension, "nos_heg__wenqin", "wei", 4)
generals.nos_heg__wenqin:addSkills{ "nos_heg__jinfa" }
generals.nos_heg__wenqin.subkingdom = "wu"
Fk:loadTranslationTable{
  ["nos_heg__wenqin"] = "文钦",
  ["#nos_heg__wenqin"] = "勇而无算",
  ["illustrator:nos_heg__wenqin"] = "匠人绘",
  ["designer:nos_heg__wenqin"] = "逍遥鱼叔",

  ["~nos_heg__wenqin"] = "公休，汝这是何意，呃……",
}

generals.nos_heg__sufei = General:new(extension, "nos_heg__sufei", "qun", 4)
generals.nos_heg__sufei.subkingdom = "wu"
generals.nos_heg__sufei:addCompanions("hs__ganning")
generals.nos_heg__sufei:addSkills{ "nos_heg__lianpian" }
Fk:loadTranslationTable{
  ["nos_heg__sufei"] = "苏飞",
  ["#nos_heg__sufei"] = "诤友投明",
  ["designer:nos_heg__sufei"] = "逍遥鱼叔",
  ["illustrator:nos_heg__sufei"] = "兴游",

  ["~nos_heg__sufei"] = "恐不能再与兴霸兄，并肩作战了……",
}

generals.nos_heg__xuyou = General:new(extension, "nos_heg__xuyou", "qun", 3)
generals.nos_heg__xuyou.subkingdom = "wei"
generals.nos_heg__xuyou:addSkills{ "nos_heg__shicai", "nos_heg__chenglue" }
Fk:loadTranslationTable{
  ["nos_heg__xuyou"] = "许攸",
  ["#nos_heg__xuyou"] = "毕方矫翼",
  ["illustrator:nos_heg__xuyou"] = "兴游",
  ["designer:nos_heg__xuyou"] = "逍遥鱼叔",

  ["~nos_heg__xuyou"] = "阿瞒，你竟忘恩负义！！",
}

generals.nos_heg__pengyang = General:new(extension, "nos_heg__pengyang", "shu", 3)
generals.nos_heg__pengyang.subkingdom = "qun"
generals.nos_heg__pengyang:addSkills{ "nos_heg__tongling", "nos_heg__jinxian" }
Fk:loadTranslationTable{
  ["nos_heg__pengyang"] = "彭羕",
  ["#nos_heg__pengyang"] = "误身的狂士",
  ["illustrator:nos_heg__pengyang"] = "君桓文化",
  ["designer:nos_heg__pengyang"] = "韩旭",

  ["~nos_heg__pengyang"] = "人言我心大志寡，难可保安，果然如此，唉……",
}

General:new(extension, "nos_heg__sunchen", "wild", 4):addSkills{ "nos_heg__shilus", "nos_heg__xiongnve" }
Fk:loadTranslationTable{
  ["nos_heg__sunchen"] = "孙綝",
  ["#nos_heg__sunchen"] = "食髓的朝堂客",
  ["illustrator:nos_heg__sunchen"] = "特特肉",
  ["designer:nos_heg__sunchen"] = "逍遥鱼叔",

  ["~nos_heg__sunchen"] = "愿陛下念臣昔日之功，陛下？陛下！！",
}

return extension
