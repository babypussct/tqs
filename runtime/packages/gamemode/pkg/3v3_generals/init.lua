-- SPDX-License-Identifier: GPL-3.0-or-later
local extension = Package:new("3v3_generals")
extension.extensionName = "gamemode"
extension.game_modes_whitelist = {
  "m_3v3_mode",
}

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/3v3_generals/skills")

Fk:loadTranslationTable{
  ["3v3_generals"] = "3v3专属武将",
  ["v33"] = "3v3",
  ["v33_nos"] = "3v3旧",
}

General:new(extension, "v33__zhugejin", "wu", 3):addSkills { "v33__huanshi", "v33__hongyuan", "mingzhe" }
Fk:loadTranslationTable{
  ["v33__zhugejin"] = "诸葛瑾",
  ["#v33__zhugejin"] = "联盟的维系者",
  ["illustrator:v33__zhugejin"] = "LiuHeng",
}

General:new(extension, "v33__wenpin", "wei", 4):addSkills { "v33__zhenwei" }
Fk:loadTranslationTable{
  ["v33__wenpin"] = "文聘",
  ["#v33__wenpin"] = "坚城宿将",
  ["illustrator:v33__wenpin"] = "木美人",
}

General:new(extension, "v33__xiahoudun", "wei", 4):addSkills { "v33__ganglie" }
Fk:loadTranslationTable{
  ["v33__xiahoudun"] = "夏侯惇",
  ["#v33__xiahoudun"] = "独眼的罗刹",
  ["illustrator:v33__xiahoudun"] = "KayaK",

  ["~v33__xiahoudun"] = "两边都看不见了……",
}

General:new(extension, "v33__guanyu", "shu", 4):addSkills { "wusheng", "zhongyi" }
Fk:loadTranslationTable{
  ["v33__guanyu"] = "关羽",
  ["#v33__guanyu"] = "美髯公",
  ["illustrator:v33__guanyu"] = "KayaK",

  ["~v33__guanyu"] = "什么？此地名叫麦城？",
}

General:new(extension, "v33__zhaoyun", "shu", 4):addSkills { "longdan", "jiuzhu" }
Fk:loadTranslationTable{
  ["v33__zhaoyun"] = "赵云",
  ["#v33__zhaoyun"] = "少年将军",
  ["illustrator:v33__zhaoyun"] = "KayaK",

  ["~v33__zhaoyun"] = "这，就是失败的滋味吗？",
}

General:new(extension, "v33_nos__lvbu", "qun", 4):addSkills { "wushuang", "zhanshen" }
Fk:loadTranslationTable{
  ["v33_nos__lvbu"] = "吕布",
  ["#v33_nos__lvbu"] = "武的化身",
  ["illustrator:v33_nos__lvbu"] = "KayaK",

  ["~v33_nos__lvbu"] = "不可能……！",
}

General:new(extension, "v33__huangquan", "shu", 3):addSkills { "choujin", "zhongjianh" }
Fk:loadTranslationTable{
  ["v33__huangquan"] = "黄权",
  ["#v33__huangquan"] = "道绝殊途",
  ["illustrator:v33__huangquan"] = "兴游",

  ["~v33__huangquan"] = "魏王厚待于我，降魏又有何错？",
}

General:new(extension, "v33__xusheng", "wu", 4):addSkills { "v33__yicheng" }
Fk:loadTranslationTable{
  ["v33__xusheng"] = "徐盛",
  ["#v33__xusheng"] = "江东的铁壁",
  ["designer:v33__xusheng"] = "淬毒",
  ["illustrator:v33__xusheng"] = "天信",

  ["~v33__xusheng"] = "可怜一身胆略，尽随一抔黄土……",
}

return extension
