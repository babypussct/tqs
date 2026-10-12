local extension = Package:new("ol_mo")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_mo/skills")

Fk:loadTranslationTable{
  ["ol_mo"] = "OL-魔",
  ["ol_evil"] = "魔",

  ["#RuMoDesc"] = "入魔是每局游戏限一次的操作，入魔后，每轮结束时，若本轮你未造成过伤害，你失去1点体力。",
}

General:new(extension, "ol_evil__simayi", "wei", 3):addSkills { "guifu", "moubian" }
Fk:loadTranslationTable{
  ["ol_evil__simayi"] = "魔司马懿",
  ["#ol_evil__simayi"] = "无天的魔狼",
  ["illustrator:ol_evil__simayi"] = "鬼画府",

  ["~ol_evil__simayi"] = "哈哈哈哈哈哈，天数…我还是输给了天数？",
}

General:new(extension, "ol_evil__sunquan", "wu", 4):addSkills { "quanyu", "tianen", "qiangang" }
Fk:loadTranslationTable{
  ["ol_evil__sunquan"] = "魔孙权",
  ["#ol_evil__sunquan"] = "隳堕的英谋",
  --["illustrator:ol_evil__sunquan"] = "",

  ["~ol_evil__sunquan"] = "朕非朕，天下皆朕！",
}

General:new(extension, "ol_evil__caocao", "wei", 4):addSkills { "bachao", "fuzai" }
Fk:loadTranslationTable{
  ["ol_evil__caocao"] = "魔曹操",
  ["#ol_evil__caocao"] = "逆溯的帝魔",
  ["illustrator:ol_evil__caocao"] = "游卡",

  ["~ol_evil__caocao"] = "身登帝座……也救不了……大魏江山！",
}

General:new(extension, "ol_evil__lvbu", "qun", 4):addSkills { "duoqi", "kuangmo", "gangquan" }
Fk:loadTranslationTable{
  ["ol_evil__lvbu"] = "魔吕布",
  ["#ol_evil__lvbu"] = "荡宇的捷拳",
  ["illustrator:ol_evil__lvbu"] = "琴酒",

  ["~ol_evil__lvbu"] = "人间无敌，该去地狱挑战了。",
}

General:new(extension, "ol_evil__diaochan", "qun", 3, 3, General.Female):addSkills { "huanhuo", "qingshic" }
Fk:loadTranslationTable{
  ["ol_evil__diaochan"] = "魔貂蝉",
  ["#ol_evil__diaochan"] = "倾世的魅影",
  ["illustrator:ol_evil__diaochan"] = "游卡",

  ["~ol_evil__diaochan"] = "待我归来，定让这天下再为我癫狂！",
}

General:new(extension, "ol_evil__zhangfei", "shu", 5):addSkills { "zhuohun", "chenshiz" }
Fk:loadTranslationTable{
  ["ol_evil__zhangfei"] = "魔张飞",
  ["#ol_evil__zhangfei"] = "祭命的战神",
  ["illustrator:ol_evil__zhangfei"] = "七七",

  ["~ol_evil__zhangfei"] = "夙仇得报，魂飞魄散又何妨！",
}

Fk:loadTranslationTable{
  ["ol_evil__zhangjiao"] = "魔张角",
  ["#ol_evil__zhangjiao"] = "正世的道首",

  -- ["~ol_evil__zhangjiao"] = "",
}

return extension
