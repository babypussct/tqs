local extension = Package:new("1v1_generals")
extension.extensionName = "gamemode"
extension.game_modes_whitelist = {
  "m_1v1_mode",
}

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/1v1_generals/skills")

Fk:loadTranslationTable{
  ["1v1_generals"] = "1v1专属武将",
  ["v11"] = "1v1",
}

--经典标准版
General:new(extension, "v11__xuchu", "wei", 4):addSkills { "luoyi", "v11__xiechan" }
Fk:loadTranslationTable{
  ["v11__xuchu"] = "许褚",
  ["#v11__xuchu"] = "虎痴",
}

General:new(extension, "v11__liubei", "shu", 4):addSkills { "v11__renwang" }
Fk:loadTranslationTable{
  ["v11__liubei"] = "刘备",
  ["#v11__liubei"] = "乱世的枭雄",
}

General:new(extension, "v11__guanyu", "shu", 4):addSkills { "wusheng", "v11__huwei" }
Fk:loadTranslationTable{
  ["v11__guanyu"] = "关羽",
  ["#v11__guanyu"] = "美髯公",
}

General:new(extension, "v11__huangyueying", "shu", 3, 3, General.Female):addSkills { "jizhi", "v11__cangji" }
Fk:loadTranslationTable{
  ["v11__huangyueying"] = "黄月英",
  ["#v11__huangyueying"] = "归隐的杰女",
}

General:new(extension, "v11__ganning", "wu", 4):addSkills { "v11__qixi" }
Fk:loadTranslationTable{
  ["v11__ganning"] = "甘宁",
  ["#v11__ganning"] = "锦帆游侠",
}

General:new(extension, "v11__lvmeng", "wu", 4):addSkills { "v11__shenju", "v11__botu" }
Fk:loadTranslationTable{
  ["v11__lvmeng"] = "吕蒙",
  ["#v11__lvmeng"] = "白衣渡江",
}

General:new(extension, "v11__daqiao", "wu", 3, 3, General.Female):addSkills { "guose", "v11__wanrong" }
Fk:loadTranslationTable{
  ["v11__daqiao"] = "大乔",
  ["#v11__daqiao"] = "矜持之花",
}

General:new(extension, "v11__sunshangxiang", "wu", 3, 3, General.Female):addSkills { "xiaoji", "v11__yinli" }
Fk:loadTranslationTable{
  ["v11__sunshangxiang"] = "孙尚香",
  ["#v11__sunshangxiang"] = "弓腰姬",
}

General:new(extension, "v11__diaochan", "qun", 3, 3, General.Female):addSkills { "biyue", "v11__pianyi" }
Fk:loadTranslationTable{
  ["v11__diaochan"] = "貂蝉",
  ["#v11__diaochan"] = "绝世的舞姬",
}

General:new(extension, "v11__huatuo", "qun", 3):addSkills { "jijiu", "v11__puji" }
Fk:loadTranslationTable{
  ["v11__huatuo"] = "华佗",
  ["#v11__huatuo"] = "神医",
}

General:new(extension, "v11__niujin", "wei", 4):addSkills { "v11__cuorui", "v11__liewei" }
Fk:loadTranslationTable{
  ["v11__niujin"] = "牛金",
  ["#v11__niujin"] = "独进的兵胆",
  ["illustrator:v11__niujin"] = "青骑士",

  ["~v11__niujin"] = "这包围圈太厚，老牛，尽力了……",
}

Fk:loadTranslationTable{
  ["v11__hejin"] = "何进",
  ["#v11__hejin"] = "色厉内荏",
  ["v11__mouzhu"] = "谋诛",
  [":v11__mouzhu"] = "出牌阶段限一次，你可以令对手交给你一张手牌，然后若其手牌数小于你，其选择视为对你使用【杀】或【决斗】。",
  ["v11__yanhuo"] = "延祸",
  [":v11__yanhuo"] = "当你死亡时，你可以依次弃置对手X张牌（X为你的牌数）。",
}

Fk:loadTranslationTable{
  ["v11__hansui"] = "韩遂",
  ["v11__niluan"] = "逆乱",
  [":v11__niluan"] = "对手的结束阶段，若其体力值大于你，或其本回合对你使用过【杀】，你可以将一张黑色牌当【杀】对其使用。",
}

--测试beta版
General:new(extension, "v11__xiangchong", "shu", 4):addSkills { "v11__changjun", "v11__aibing" }
Fk:loadTranslationTable{
  ["v11__xiangchong"] = "向宠",
}

General:new(extension, "v11__sunyi", "wu", 4):addSkills { "v11__guolie", "v11__hunbi" }
Fk:loadTranslationTable{
  ["v11__sunyi"] = "孙翊",
}

Fk:loadTranslationTable{
  ["v11__duosidawang"] = "朵思大王",
  ["v11__mihuo"] = "迷惑",
  [":v11__mihuo"] = "对手使用的锦囊牌结算完毕进入弃牌堆时，你可以将之置于你的武将牌上。对手不能使用与“迷惑”同名的牌。",
  ["v11__fanshu"] = "反术",
  [":v11__fanshu"] = "出牌阶段限一次，你可以将一张“迷惑”牌当任意一张“迷惑”牌使用。",
}

General:new(extension, "v11__zhuyi", "qun", 4):addSkills { "v11__chengji" }
Fk:loadTranslationTable{
  ["v11__zhuyi"] = "注诣",
}

return extension
