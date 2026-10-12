local extension = Package:new("mobile_lxxh")
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/mobile_lxxh/skills")

Fk:loadTranslationTable{
  ["mobile_lxxh"] = "手杀-龙血玄黄",
  ["m_sp"] = "手杀SP",
  ["mobile2"] = "手杀",
}

local caomao = General:new(extension, "mobile__caomao", "wei", 3)
caomao:addSkills { "mobile__qianlong", "weitong" }
Fk:loadTranslationTable{
  ["mobile__caomao"] = "曹髦",
  ["#mobile__caomao"] = "向死存魏",
  ["illustrator:mobile__caomao"] = "铁杵",

  ["~mobile__caomao"] = "纵不成身死，朕亦为太祖子孙，大魏君王……",
  ["!mobile__caomao"] = "少康诛寒浞以中兴，朕夷司马未尝不可！",
}
local caomao2 = General:new(extension, "mobile2__caomao", "wei", 3)
caomao2:addSkills { "mobile__qianlong", "weitong" }
caomao2.hidden = true
Fk:loadTranslationTable{
  ["mobile2__caomao"] = "曹髦",
  ["#mobile2__caomao"] = "向死存魏",
  ["illustrator:mobile2__caomao"] = "铁杵",

  ["~mobile2__caomao"] = "纵不成身死，朕亦为太祖子孙，大魏君王……",
}
Fk:addPersonalMark{
  name = "qianlong",
  qml_path = "/packages/mobile/qml/personalMark/qianlong.qml",
  mark_name = "@mobile__qianlong_daoxin",
}
caomao:addAttachedPersonalMark("qianlong")
caomao2:addAttachedPersonalMark("qianlong")

General:new(extension, "m_sp__guanqiujian", "wei", 4):addSkills { "cuizhen", "kuili" }
Fk:loadTranslationTable{
  ["m_sp__guanqiujian"] = "毌丘俭",
  ["#m_sp__guanqiujian"] = "才识拔干",
  ["illustrator:m_sp__guanqiujian"] = "凝聚永恒",

  ["~m_sp__guanqiujian"] = "汝不讨篡权逆臣，何杀吾讨贼义军……",
}

General:new(extension, "lizhaojiaobo", "wei", 4):addSkills { "zuoyou", "shishoul" }
Fk:loadTranslationTable{
  ["lizhaojiaobo"] = "李昭焦伯",
  ["#lizhaojiaobo"] = "竭诚尽节",
  ["illustrator:lizhaojiaobo"] = "凝聚永恒",

  ["~lizhaojiaobo"] = "陛下！！尔等乱臣，安敢弑君！呃啊……",
}

General:new(extension, "chengjiw", "wei", 4):addSkills { "kuangli", "xiongsi" }
Fk:loadTranslationTable{
  ["chengjiw"] = "成济",
  ["#chengjiw"] = "劣犬良弓",
  ["illustrator:chengjiw"] = "凝聚永恒",

  ["~chengjiw"] = "汝等要卸磨杀驴吗？呃啊……",
}

local simafu = General:new(extension, "mobile__simafu", "wei", 3)
simafu:addSkills { "panxiang", "mobile__chenjie" }
simafu.subkingdom = "jin"
Fk:loadTranslationTable{
  ["mobile__simafu"] = "司马孚",
  ["#mobile__simafu"] = "徒难夷惠",
  ["illustrator:mobile__simafu"] = "鬼画府",

  ["~mobile__simafu"] = "生此篡逆之事，罪臣难辞其咎……",
}

General:new(extension, "mobile__wenqin", "wei", 4):addSkills { "beiming", "choumang" }
Fk:loadTranslationTable{
  ["mobile__wenqin"] = "文钦",
  ["#mobile__wenqin"] = "淮山骄腕",
  ["illustrator:mobile__wenqin"] = "铁杵",

  ["~mobile__wenqin"] = "伺君兵败之日，必报此仇于九泉！",
}

local simazhou = General:new(extension, "mobile__simazhou", "wei", 4)
simazhou:addSkills { "bifeng", "suwang" }
simazhou.subkingdom = "jin"
Fk:loadTranslationTable{
  ["mobile__simazhou"] = "司马伷",
  ["#mobile__simazhou"] = "恭温克己",
  ["illustrator:mobile__simazhou"] = "错落宇宙",

  ["~mobile__simazhou"] = "臣所求唯莽伏太妃陵次，分国封四子而已。",
}

local jiachong = General:new(extension, "mobile__jiachong", "qun", 3)
jiachong:addSkills { "mobile__beini", "mobile__dingfa" }
jiachong.subkingdom = "jin"
Fk:loadTranslationTable{
  ["mobile__jiachong"] = "贾充",
  ["#mobile__jiachong"] = "凶凶踽行",
  ["designer:mobile__jiachong"] = "Loun老萌",
  ["illustrator:mobile__jiachong"] = "铁杵文化",
  ["cv:mobile__jiachong"] = "虞晓旭",

  ["~mobile__jiachong"] = "此生从势忠命，此刻，只乞不获恶谥……",
}

local simazhao = General:new(extension, "mobile__simazhao", "wei", 3)
table.insert(Fk.lords, "mobile__simazhao") -- 没有主公技的常备主
simazhao:addSkills { "mobile__xiezheng", "mobile__qiantun", "mobile__zhaoxiong" }
Fk:loadTranslationTable{
  ["mobile__simazhao"] = "司马昭",
  ["#mobile__simazhao"] = "独祅吞天",
  ["illustrator:mobile__simazhao"] = "腥鱼仔",

  ["~mobile__simazhao"] = "锋芒毕露，野心昭彰，竟有此果……",
  ["!mobile__simazhao"] = "执掌朝野，尽吞大魏河山！",
}
local simazhao2 = General:new(extension, "mobile2__simazhao", "qun", 3)
simazhao2.hidden = true
simazhao2:addSkills { "mobile__weisi", "mobile__xiezheng", "mobile__dangyi" }
Fk:loadTranslationTable{
  ["mobile2__simazhao"] = "司马昭",
  ["#mobile2__simazhao"] = "独祅吞天",
  ["illustrator:mobile2__simazhao"] = "腥鱼仔",

  ["$mobile__xiezheng_mobile2__simazhao1"] = "吾今大权独揽，何可再予他人？",
  ["$mobile__xiezheng_mobile2__simazhao2"] = "吾领三军于外，岂容陛下收政于京！",
  ["~mobile2__simazhao"] = "王权崩坏，此罪弥天……",
  ["!mobile2__simazhao"] = "一统之世，当由我司马氏开创！",
}

return extension
