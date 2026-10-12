local extension = Package:new("ol_shzl")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_shzl/skills")

Fk:loadTranslationTable{
  ["ol_shzl"] = "OL-神话",
}

General:new(extension, "ol__caoren", "wei", 4):addSkills { "ol__jushou", "ol__jiewei" }
Fk:loadTranslationTable{
  ["ol__caoren"] = "曹仁",
  ["#ol__caoren"] = "大将军",
  ["illustrator:ol__caoren"] = "Ccat",

  ["~ol__caoren"] = "长江以南，再无王土矣……",
}

General:new(extension, "ol__zhoutai", "wu", 4):addSkills { "ol__buqu", "fenji" }
Fk:loadTranslationTable{
  ["ol__zhoutai"] = "周泰",
  ["#ol__zhoutai"] = "历战之躯",
  ["illustrator:ol__zhoutai"] = "Thinking",

  ["~ol__zhoutai"] = "敌众我寡，无力回天……",
}

General:new(extension, "ol__dianwei", "wei", 4):addSkills { "ol__qiangxi" }
Fk:loadTranslationTable{
  ["ol__dianwei"] = "典韦",
  ["#ol__dianwei"] = "古之恶来",
  ["illustrator:ol__dianwei"] = "宋其金",

  ["~ol__dianwei"] = "喝酒误事，丢我双戟……",
}

General:new(extension, "ol__menghuo", "shu", 4):addSkills { "huoshou", "ol__zaiqi" }
Fk:loadTranslationTable{
  ["ol__menghuo"] = "孟获",
  ["#ol__menghuo"] = "南蛮王",
  ["illustrator:ol__menghuo"] = "depp",

  ["$huoshou_ol__menghuo1"] = "定叫你们有来无回！",
  ["$huoshou_ol__menghuo2"] = "汉人岂是我等的对手！",
  ["~ol__menghuo"] = "有心无力了……",
}

General:new(extension, "ol__sunliang", "wu", 3):addSkills { "ol__kuizhu", "ol__chezheng", "ol__lijun" }
Fk:loadTranslationTable{
  ["ol__sunliang"] = "孙亮",
  ["#ol__sunliang"] = "寒江枯木",
  ["cv:ol__sunliang"] = "徐刚",
  ["illustrator:ol__sunliang"] = "alien",

  ["~ol__sunliang"] = "君不君，臣不臣，此国之悲……",
}

General:new(extension, "ol__luzhi", "qun", 3):addSkills { "ol__mingren", "ol__zhenliang" }
Fk:loadTranslationTable{
  ["ol__luzhi"] = "卢植",
  ["#ol__luzhi"] = "国之桢干",
  ["illustrator:ol__luzhi"] = "凡果",

  ["~ol__luzhi"] = "左丰与臣在，此仗怎可胜？",
}

General:new(extension, "ol__guanqiujian", "wei", 4):addSkills { "ol__zhengrong", "ol__hongju" }
Fk:loadTranslationTable{
  ["ol__guanqiujian"] = "毌丘俭",
  ["#ol__guanqiujian"] = "镌功铭征荣",
  ["illustrator:ol__guanqiujian"] = "alien",

  ["~ol__guanqiujian"] = "好谋而不达，此事必有隐患。",
}

General:new(extension, "ol__zhoufei", "wu", 3, 3, General.Female):addSkills { "ol__liangyin", "ol__kongsheng" }
Fk:loadTranslationTable{
  ["ol__zhoufei"] = "周妃",
  ["#ol__zhoufei"] = "软玉温香",
  ["designer:ol__zhoufei"] = "玄蝶既白",
  ["illustrator:ol__zhoufei"] = "圆子",

  ["~ol__zhoufei"] = "梧桐半枯衰，鸳鸯白头散……",
}

General:new(extension, "ol__godguanyu", "god", 5):addSkills { "ol__wushen", "wuhun" }
Fk:loadTranslationTable{
  ["ol__godguanyu"] = "神关羽",
  ["#ol__godguanyu"] = "鬼神再临",
  ["illustrator:ol__godguanyu"] = "秋呆呆",

  ["$wuhun_ol__godguanyu1"] = "还我头来！",
  ["$wuhun_ol__godguanyu2"] = "不杀此人，何以雪恨？",
  ["~ol__godguanyu"] = "夙愿已了，魂归地府。",
}

General:new(extension, "ol__godcaocao", "god", 3):addSkills { "ol__guixin", "feiying" }
Fk:loadTranslationTable{
  ["ol__godcaocao"] = "神曹操",
  ["#ol__godcaocao"] = "超世之英杰",
  ["illustrator:ol__godcaocao"] = "一串糖葫芦",

  ["~ol__godcaocao"] = "怎可负……天下人……",
}

General:new(extension, "ol__godzhangliao", "god", 4):addSkills { "ol__duorui", "ol__zhiti" }
Fk:loadTranslationTable{
  ["ol__godzhangliao"] = "神张辽",
  ["#ol__godzhangliao"] = "雁门之刑天",

  ["~ol__godzhangliao"] = "辽来，辽来！辽去！辽去……",
}

General:new(extension, "godsunquan", "god", 4):addSkills { "yuheng", "dili" }
Fk:loadTranslationTable{
  ["godsunquan"] = "神孙权",
  ["#godsunquan"] = "坐断东南",
  ["designer:godsunquan"] = "玄蝶既白",
  ["illustrator:godsunquan"] = "鬼画府",

  ["~godsunquan"] = "困居江东，枉称至尊……",
}

General:new(extension, "ol__godzhangjiao", "god", 3):addSkills { "ol__yizhao", "ol__sijun", "tianjie" }
Fk:loadTranslationTable{
  ["ol__godzhangjiao"] = "神张角",
  ["#ol__godzhangjiao"] = "清淼没川",
  ["designer:ol__godzhangjiao"] = "韩旭",
  --["illustrator:ol__godzhangjiao"] = "",

  ["$tianjie_ol__godzhangjiao1"] = "彼肉食者，奈何枉顾庶民之怒！",
  ["$tianjie_ol__godzhangjiao2"] = "我等载舟之水，欲覆不仁之舟于黄泉。",
  ["~ol__godzhangjiao"] = "这覆舟的水，皆是百姓的泪……",
}

General:new(extension, "ol__godhuangzhong", "god", 4):addSkills { "shenyu", "huaren" }
Fk:loadTranslationTable{
  ["ol__godhuangzhong"] = "神黄忠",
  ["#ol__godhuangzhong"] = "血刃斩穹",
  ["illustrator:ol__godhuangzhong"] = "",

  ["~ol__godhuangzhong"] = "荧惑归天，吾亦往矣……",
}

return extension
