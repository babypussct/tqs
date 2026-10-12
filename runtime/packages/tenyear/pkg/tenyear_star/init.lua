local extension = Package:new("tenyear_star")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_star/skills")

Fk:loadTranslationTable{
  ["tenyear_star"] = "十周年-星河璀璨",
  ["tystar"] = "新服星",
}

--天枢：
General:new(extension, "tystar__dongzhuo", "qun", 5):addSkills { "weilin", "zhangrong", "haoshou" }
Fk:loadTranslationTable{
  ["tystar__dongzhuo"] = "星董卓",
  ["#tystar__dongzhuo"] = "千里草的魔阀",
  ["designer:tystar__dongzhuo"] = "对勾对勾w",
  ["illustrator:tystar__dongzhuo"] = "黯荧岛工作室",

  ["~tystar__dongzhuo"] = "美人迷人眼，溢权昏人智……",
}

General:new(extension, "tystar__yuanshu", "qun", 4):addSkills { "canxi", "pizhi", "zhonggu" }
Fk:loadTranslationTable{
  ["tystar__yuanshu"] = "星袁术",
  ["#tystar__yuanshu"] = "狂貔猖貅",
  ["designer:tystar__yuanshu"] = "头发好借好还",
  ["illustrator:tystar__yuanshu"] = "黯荧岛工作室",

  ["~tystar__yuanshu"] = "英雄不死则已，死则举大名尔……",
}

General:new(extension, "tystar__yuanshao", "qun", 4):addSkills { "xiaoyan", "zongshiy", "jiaowang", "aoshi" }
Fk:loadTranslationTable{
  ["tystar__yuanshao"] = "星袁绍",
  ["#tystar__yuanshao"] = "熏灼群魔",
  ["designer:tystar__yuanshao"] = "步穗",
  ["illustrator:tystar__yuanshao"] = "鬼画府",

  ["~tystar__yuanshao"] = "骄兵必败，奈何不记前辙……",
}

General:new(extension, "tystar__zhangrang", "qun", 3):addSkills { "duhai", "lingse" }
Fk:loadTranslationTable{
  ["tystar__zhangrang"] = "星张让",
  ["#tystar__zhangrang"] = "斗筲穿窬",
  ["illustrator:tystar__zhangrang"] = "君桓文化",

  ["~tystar__zhangrang"] = "先皇啊，小陛下他拿咱不当人！",
}

--天璇：
General:new(extension, "tystar__zhangzhao", "wu", 3):addSkills { "zhongyanz", "jinglun" }
Fk:loadTranslationTable{
  ["tystar__zhangzhao"] = "星张昭",
  ["#tystar__zhangzhao"] = "忠謇方直",
  ["illustrator:tystar__zhangzhao"] = "君桓文化",

  ["~tystar__zhangzhao"] = "曹公虎豹也，不如以礼早降。",
}

General:new(extension, "tystar__fazheng", "shu", 3):addSkills { "zhijif", "anji" }
Fk:loadTranslationTable{
  ["tystar__fazheng"] = "星法正",
  ["#tystar__fazheng"] = "定军佐功",
  ["illustrator:tystar__fazheng"] = "匠人绘",
  ["designer:tystar__fazheng"] = "懵萌猛梦",

  ["~tystar__fazheng"] = "我当为君之子房，奈何命寿将尽……",
}

General:new(extension, "tystar__xunyu", "wei", 3):addSkills { "anshu", "kuangzuo" }
Fk:loadTranslationTable{
  ["tystar__xunyu"] = "星荀彧",
  ["#tystar__xunyu"] = "怀忠念治",
  ["designer:tystar__xunyu"] = "对勾对勾w",
  ["illustrator:tystar__xunyu"] = "黯荧岛",

  ["~tystar__xunyu"] = "臣固忠于国，非一家之臣。",
}

General:new(extension, "tystar__zhangsong", "shu", 3):addSkills { "xisong", "fanglang" }
Fk:loadTranslationTable{
  ["tystar__zhangsong"] = "星张松",
  ["#tystar__zhangsong"] = "乌鹊折槁",
  -- ["illustrator:tystar__zhangsong"] = "",

  ["~tystar__zhangsong"] = "刘季玉！你也配某一声主公！",
}

General:new(extension, "tystar__zhugejin", "wu", 3):addSkills { "ty__zunjian", "hongya" }
Fk:loadTranslationTable{
  ["tystar__zhugejin"] = "星诸葛瑾",
  ["#tystar__zhugejin"] = "怀玉之臣",

  --["~tystar__zhugejin"] = "",
}

--玉衡：
General:new(extension, "tystar__caoren", "wei", 4):addSkills { "sujun", "lifengc" }
Fk:loadTranslationTable{
  ["tystar__caoren"] = "星曹仁",
  ["#tystar__caoren"] = "伏波四方",
  ["designer:tystar__caoren"] = "追风少年",
  ["illustrator:tystar__caoren"] = "君桓文化",

  ["~tystar__caoren"] = "濡须之败，此生之耻……",
}

General:new(extension, "tystar__zhangchunhua", "wei", 3, 3, General.Female):addSkills { "liangyan", "minghui" }
Fk:loadTranslationTable{
  ["tystar__zhangchunhua"] = "星张春华",
  ["#tystar__zhangchunhua"] = "皑雪皎月",
  ["designer:tystar__zhangchunhua"] = "黑寡妇",
  ["illustrator:tystar__zhangchunhua"] = "七兜豆",

  ["~tystar__zhangchunhua"] = "我何为也？竟称可憎之老物……",
}

General:new(extension, "tystar__dongyun", "shu", 4):addSkills { "bishid", "zhengting" }
Fk:loadTranslationTable{
  ["tystar__dongyun"] = "星董允",
  ["#tystar__dongyun"] = "謇谔镇慝",
  --["illustrator:tystar__dongyun"] = "",

  ["~tystar__dongyun"] = "子不类父，子不类父啊！",
}

General:new(extension, "tystar__jiangwan", "shu", 3):addSkills { "ty__zhenting", "chiguo" }
Fk:loadTranslationTable{
  ["tystar__jiangwan"] = "星蒋琬",
  ["#tystar__jiangwan"] = "讬忠赞业",
  ["illustrator:tystar__jiangwan"] = "君桓文化",

  ["~tystar__jiangwan"] = "琬无功于国，愧负丞相重托。",
}

General:new(extension, "tystar__zhanghe", "qun", 4):addSkills { "junxi", "jixianz" }
Fk:loadTranslationTable{
  ["tystar__zhanghe"] = "星张郃",
  ["#tystar__zhanghe"] = "河北之庭柱",
  -- ["illustrator:tystar__zhanghe"] = "",

  ["~tystar__zhanghe"] = "佞臣之言，猛于蛇虎。",
}

--开阳：
General:new(extension, "tystar__sunjian", "qun", 4, 5):addSkills { "ruijun", "gangyi" }
Fk:loadTranslationTable{
  ["tystar__sunjian"] = "星孙坚",
  ["#tystar__sunjian"] = "破虏将军",
  ["illustrator:tystar__sunjian"] = "鬼画府",
  ["designer:tystar__sunjian"] = "韩旭",

  ["~tystar__sunjian"] = "身怀宝器，必受群狼觊觎……",
}

General:new(extension, "tystar__taishici", "qun", 4):addSkills { "chongwei", "chongzu" }
Fk:loadTranslationTable{
  ["tystar__taishici"] = "星太史慈",
  ["#tystar__taishici"] = "信义为先",
  ["illustrator:tystar__taishici"] = "君桓文化",

  ["~tystar__taishici"] = "士为知己者死，何憾之有？",
}

General:new(extension, "tystar__xiahouba", "shu", 4):addSkills { "weigu", "juefa" }
Fk:loadTranslationTable{
  ["tystar__xiahouba"] = "星夏侯霸",
  ["#tystar__xiahouba"] = "箍围抗尽",
  --["illustrator:tystar__xiahouba"] = "",

  ["~tystar__xiahouba"] = "我如无根之萍，不知埋骨何处。",
}

--瑶光：
General:new(extension, "tystar__wenchou", "qun", 4):addSkills { "lianzhan", "weimingw" }
Fk:loadTranslationTable{
  ["tystar__wenchou"] = "星文丑",
  ["#tystar__wenchou"] = "夔威天下",
  ["illustrator:tystar__wenchou"] = "错落宇宙",

  ["~tystar__wenchou"] = "今日之败，实在是天意弄人啊……",
}

General:new(extension, "tystar__sunshangxiang", "wu", 3, 3, General.Female):addSkills { "saying", "ty__jiaohao" }
Fk:loadTranslationTable{
  ["tystar__sunshangxiang"] = "星孙尚香",
  ["#tystar__sunshangxiang"] = "鸳袖衔剑珮",
  ["designer:tystar__sunshangxiang"] = "食饿不赦",
  ["illustrator:tystar__sunshangxiang"] = "匠人绘",

  ["~tystar__sunshangxiang"] = "秋风冷，江水寒……",
}

General:new(extension, "tystar__dingfeng", "wu", 4):addSkills { "dangchen", "jianyud" }
Fk:loadTranslationTable{
  ["tystar__dingfeng"] = "星丁奉",
  ["#tystar__dingfeng"] = "廓清阶陛",
  ["illustrator:tystar__dingfeng"] = "钟於",

  ["~tystar__dingfeng"] = "野豕入营，此凶徵也。",
}

General:new(extension, "tystar__yanliang", "qun", 4):addSkills { "jizhany", "cuxia" }
Fk:loadTranslationTable{
  ["tystar__yanliang"] = "星颜良",
  ["#tystar__yanliang"] = "狰颤四方",
  ["illustrator:tystar__yanliang"] = "错落宇宙",

  ["~tystar__yanliang"] = "来将可是关……啊！",
}

return extension
