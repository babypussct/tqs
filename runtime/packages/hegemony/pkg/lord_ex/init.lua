local extension = Package:new("lord_ex")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { 'new_heg_mode' }
extension:loadSkillSkelsByPath("./packages/hegemony/pkg/lord_ex/skills")

Fk:loadTranslationTable{
  ["lord_ex"] = "君临天下·EX/不臣篇",
}

General:new(extension, "ld__dongzhao", "wei", 3):addSkills{ "quanjin", "zaoyun" }
Fk:loadTranslationTable{
  ["ld__dongzhao"] = "董昭",
  ["dongzhao"] = "董昭",
  ["#ld__dongzhao"] = "移尊易鼎",
  ["illustrator:ld__dongzhao"] = "小牛",
  ["designer:ld__dongzhao"] = "逍遥鱼叔",
  ["cv:ld__dongzhao"] = "宋国庆",

  ["~ld__dongzhao"] = "一生无愧，又何惧身后之议……",
}

General:new(extension, "ld__zhuling", "wei", 4):addSkills{ "ld__juejue", "ld__fangyuan" }
Fk:loadTranslationTable{
  ["ld__zhuling"] = "朱灵",
  ["zhuling"] = "朱灵",
  ["#ld__zhuling"] = "五子之亚",
  ["illustrator:ld__zhuling"] = "YanBai",

  ["~ld__zhuling"] = "母亲，弟弟，我来了……",
}

local xushu = General:new(extension, "ld__xushu", "shu", 4)
xushu.deputyMaxHpAdjustedValue = -1
xushu:addCompanions({ "hs__wolong", "hs__zhaoyun" })
xushu:addSkills{ "ld__qiance", "ld__jujian" }
Fk:loadTranslationTable{
  ["ld__xushu"] = "徐庶",
  ["xushu"] = "徐庶",
  ["#ld__xushu"] = "难为完臣",
  ["illustrator:ld__xushu"] = "YanBai",

  ["~ld__xushu"] = "大义无言，虽死无怨。",
}

General:new(extension, "ld__liuba", "shu", 3):addSkills{ "ld__tongdu", "ld__qingyin" }
Fk:loadTranslationTable{
  ["ld__liuba"] = "刘巴",
  ["liuba"] = "刘巴",
  ["#ld__liuba"] = "清河一鲲",
  ["illustrator:ld__liuba"] = "Mr_Sleeping",
  ["designer:ld__liuba"] = "逍遥鱼叔",

  ["~ld__liuba"] = "家国将逢巨变，奈何此身先陨。",
}

General:new(extension, "ld__wujing", "wu", 4):addSkills{ "ld__diaogui", "ld__fengyang" }
Fk:loadTranslationTable{
  ["ld__wujing"] = "吴景",
  ["wujing"] = "吴景",
  ["#ld__wujing"] = "汗马鎏金",
  ["illustrator:ld__wujing"] = "小牛",
  ["designer:ld__wujing"] = "逍遥鱼叔",
  ["cv:ld__wujing"] = "虞晓旭",

  ["~ld__wujing"] = "憾未能见，我江东一统天下之时……",
}

local zhugeke = General:new(extension, "ld__zhugeke", "wu", 3)
zhugeke:addCompanions("hs__dingfeng")
zhugeke:addSkills{ "ld__aocai", "ld__duwu" }
Fk:loadTranslationTable{
  ["ld__zhugeke"] = "诸葛恪",
  ["zhugeke"] = "诸葛恪",
  ["#ld__zhugeke"] = "兴家赤族",
  ["designer:ld__zhugeke"] = "逍遥鱼叔",
  ["illustrator:ld__zhugeke"] = "猎枭",

  ["~ld__zhugeke"] = "重权震主，是我疏忽了……",
}

General:new(extension, "ld__yanbaihu", "qun", 4):addSkills{ "ld__zhidao", "ld__jilix" }
Fk:loadTranslationTable{
  ["ld__yanbaihu"] = "严白虎",
  ["yanbaihu"] = "严白虎",
  ["#ld__yanbaihu"] = "豺牙落涧",
  ["designer:ld__yanbaihu"] = "逍遥鱼叔",
  ["illustrator:ld__yanbaihu"] = "",

  ["~ld__yanbaihu"] = "江东，有我…一半…",
}

General:new(extension, "ld__huangzu", "qun", 4):addSkills{ "ld__xishe" }
Fk:loadTranslationTable{
  ["ld__huangzu"] = "黄祖",
  ["huangzu"] = "黄祖",
  ["#ld__huangzu"] = "遮山扼江",
  ["designer:ld__huangzu"] = "逍遥鱼叔",
  ["illustrator:ld__huangzu"] = "YanBai",

  ["~ld__huangzu"] = "今日不过是成王败寇，哼！动手吧！",
}

local mengda = General:new(extension, "ld__mengda", "shu", 4)
mengda.subkingdom = "wei"
mengda:addSkills{ "ld__qiuan", "ld__liangfan" }
Fk:loadTranslationTable{
  ["ld__mengda"] = "孟达",
  ["mengda"] = "孟达",
  ["#ld__mengda"] = "怠军反复",
  ["designer:ld__mengda"] = "韩旭",
  ["illustrator:ld__mengda"] = "张帅",

  ["~ld__mengda"] = "吾一生寡信，今报应果然来矣…",
}

local zhanglu = General:new(extension, "ld__zhanglu", "qun", 3)
zhanglu.subkingdom = "wei"
zhanglu:addSkills{ "ld__bushi", "ld__midao" }
Fk:loadTranslationTable{
  ["ld__zhanglu"] = "张鲁",
  ["zhanglu"] = "张鲁",
  ["#ld__zhanglu"] = "政宽教惠",
  ["illustrator:ld__zhanglu"] = "磐蒲",

  ["~ld__zhanglu"] = "唉，义不敌武，道难御兵……",
}

local qtc = General:new(extension, "ld__mifangfushiren", "shu", 4)
qtc.subkingdom = "wu"
qtc:addSkills{ "ld__fengshih" }
Fk:loadTranslationTable{
  ["ld__mifangfushiren"] = "糜芳傅士仁",
  ["mifangfushiren"] = "糜芳傅士仁",
  ["#ld__mifangfushiren"] = "逐驾迎尘",
  ["designer:ld__mifangfushiren"] = "Loun老萌",
  ["illustrator:ld__mifangfushiren"] = "木美人",

  ["~ld__mifangfushiren"] = "虞翻小儿，你安敢辱我！",
}

local shixie = General:new(extension, "ld__shixie", "qun", 3)
shixie.subkingdom = "wu"
shixie:addSkills{ "ld__biluan", "ld__lixia" }
Fk:loadTranslationTable{
  ["ld__shixie"] = "士燮",
  ["shixie"] = "士燮",
  ["#ld__shixie"] = "百粤灵欹",
  ["designer:ld__shixie"] = "韩旭",
  ["illustrator:ld__shixie"] = "磐蒲",

  ["~ld__shixie"] = "我这一生，足矣……",
}

local liuqi = General:new(extension, "ld__liuqi", "qun", 3)
liuqi.subkingdom = "shu"
liuqi:addSkills{ "ld__wenji", "ld__tunjiang" }
Fk:loadTranslationTable{
  ["ld__liuqi"] = "刘琦",
  ["liuqi"] = "刘琦",
  ["#ld__liuqi"] = "居外而安",
  ["designer:ld__liuqi"] = "荼蘼（韩旭）",
  ["illustrator:ld__liuqi"] = "绘聚艺堂",

  ["~ld__liuqi"] = "父亲，孩儿来，见你了。",
}

local tangzi = General:new(extension, "ld__tangzi", "wei", 4)
tangzi.subkingdom = "wu"
tangzi:addSkills{ "ld__xingzhao" }
Fk:loadTranslationTable{
  ["ld__tangzi"] = "唐咨",
  ["tangzi"] = "唐咨",
  ["#ld__tangzi"] = "得时识风",
  ["designer:ld__tangzi"] = "荼蘼（韩旭）",
  ["illustrator:ld__tangzi"] = "凝聚永恒",

  ["~ld__tangzi"] = "偷工减料，要不得啊…",
}

local xiahouba = General:new(extension, "ld__xiahouba", "shu", 4)
xiahouba.subkingdom = "wei"
xiahouba:addCompanions("ld__jiangwei")
xiahouba:addSkills{ "ld__baolie" }
Fk:loadTranslationTable{
  ["ld__xiahouba"] = "夏侯霸",
  ["xiahouba"] = "夏侯霸",
  ["#ld__xiahouba"] = "棘途壮志",
  ["designer:ld__xiahouba"] = "逍遥鱼叔",
  ["illustrator:ld__xiahouba"] = "小牛",

  ["~ld__xiahouba"] = "不好，有埋伏！呃！",
}

local panjun = General:new(extension, "ld__panjun", "wu", 3)
panjun.subkingdom = "shu"
panjun:addSkills{ "ld__congcha", "gongqing" }
Fk:loadTranslationTable{
  ["ld__panjun"] = "潘濬",
  ["panjun"] = "潘濬",
  ["#ld__panjun"] = "逆鳞之砥",
  ["illustrator:ld__panjun"] = "Domi",
  ["designer:ld__panjun"] = "逍遥鱼叔",

  ["~ld__panjun"] = "密谋既泄，难处奸贼啊……",
}

local wenqin = General:new(extension, "ld__wenqin", "wei", 4)
wenqin:addSkills{ "ld__jinfa" }
wenqin.subkingdom = "wu"
Fk:loadTranslationTable{
  ["ld__wenqin"] = "文钦",
  ["wenqin"] = "文钦",
  ["#ld__wenqin"] = "勇而无算",
  ["illustrator:ld__wenqin"] = "匠人绘-零二",
  ["designer:ld__wenqin"] = "逍遥鱼叔",

  ["~ld__wenqin"] = "公休，汝这是何意，呃……",
}

local sufei = General:new(extension, "ld__sufei", "qun", 4) 
sufei.subkingdom = "wu"
sufei:addCompanions("hs__ganning")
sufei:addSkills{ "ld__lianpian" }
Fk:loadTranslationTable{
  ["ld__sufei"] = "苏飞",
  ["sufei"] = "苏飞",
  ["#ld__sufei"] = "诤友投明",
  ["designer:ld__sufei"] = "逍遥鱼叔",
  ["illustrator:ld__sufei"] = "Domi",

  ["~ld__sufei"] = "恐不能再与兴霸兄，并肩作战了……",
}

local xuyou = General:new(extension, "ld__xuyou", "qun", 3)
xuyou.subkingdom = "wei"
xuyou:addSkills{ "ld__shicai", "ld__chenglue" }
Fk:loadTranslationTable{
  ["ld__xuyou"] = "许攸",
  ["xuyou"] = "许攸",
  ["#ld__xuyou"] = "毕方矫翼",
  ["designer:ld__xuyou"] = "逍遥鱼叔",
  ["illustrator:ld__xuyou"] = "猎枭",

  ["~ld__xuyou"] = "阿瞒，你竟忘恩负义！！",
}

local pengyang = General:new(extension, "ld__pengyang", "shu", 3)
pengyang.subkingdom = "qun"
pengyang:addSkills{ "ld__tongling", "ld__jinxian" }
Fk:loadTranslationTable{
  ["ld__pengyang"] = "彭羕",
  ["pengyang"] = "彭羕",
  ["#ld__pengyang"] = "误身的狂士",
  ["illustrator:ld__pengyang"] = "匠人绘-零一",
  ["designer:ld__pengyang"] = "韩旭",

  ["~ld__pengyang"] = "人言我心大志寡，难可保安，果然如此，唉……",
}

local zhonghui = General:new(extension, "ld__zhonghui", "wild", 4)
zhonghui:addCompanions("ld__jiangwei")
zhonghui:addSkills{ "ld__quanji", "ld__paiyi"}
Fk:loadTranslationTable{
  ["ld__zhonghui"] = "钟会",
  ["zhonghui"] = "钟会",
  ["#ld__zhonghui"] = "桀骜的野心家",
  ["designer:ld__zhonghui"] = "韩旭",
  ["illustrator:ld__zhonghui"] = "磐蒲",

  ["~ld__zhonghui"] = "吾机关算尽，却还是棋错一着……",
}

local simazhao = General:new(extension, "ld__simazhao", "wild", 3)
simazhao:addCompanions("hs__simayi")
simazhao:addSkills{ "ld__suzhi", "ld__zhaoxin" }
Fk:loadTranslationTable{
  ["ld__simazhao"] = "司马昭",
  ["simazhao"] = "司马昭",
  ["#ld__simazhao"] = "嘲风开天",
  ["designer:ld__simazhao"] = "韩旭",
  ["illustrator:ld__simazhao"] = "凝聚永恒",

  ["~ld__simazhao"] = "千里之功，只差一步了……",
}

General:new(extension, "ld__sunchen", "wild", 4):addSkills{ "shilus", "xiongnve" }
Fk:loadTranslationTable{
  ["ld__sunchen"] = "孙綝",
  ["sunchen"] = "孙綝",
  ["#ld__sunchen"] = "食髓的朝堂客",
  ["designer:ld__sunchen"] = "逍遥鱼叔",
  ["illustrator:ld__sunchen"] = "depp",

  ["~ld__sunchen"] = "愿陛下念臣昔日之功，陛下？陛下！！",
}

General:new(extension, "ld__gongsunyuan", "wild", 4):addSkills{ "ld__huaiyi", "ld__zisui" }
Fk:loadTranslationTable{
  ["ld__gongsunyuan"] = "公孙渊",
  ["gongsunyuan"] = "公孙渊",
  ["#ld__gongsunyuan"] = "狡黠的投机者",
  ["designer:ld__gongsunyuan"] = "逍遥鱼叔",
  ["illustrator:ld__gongsunyuan"] = "猎枭",

  ["~ld__gongsunyuan"] = "流星骤损，三军皆溃，看来大势去矣……",
}

return extension

