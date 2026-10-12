local extension = Package:new("transformation")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/transformation/skills")

Fk:loadTranslationTable{
  ["transformation"] = "君临天下·变",
  ["transformDeputy"] = "变更副将",
}
local xunyou = General:new(extension, "ld__xunyou", "wei", 3)
xunyou:addSkills{"ld__qice", "ld__zhiyu"}
xunyou:addCompanions("hs__xunyu")
Fk:loadTranslationTable{
  ["ld__xunyou"] = "荀攸",
  ["xunyou"] = "荀攸",
  ["#ld__xunyou"] = "曹魏的谋主",
  ["designer:ld__xunyou"] = "淬毒",
  ["illustrator:ld__xunyou"] = "心中一凛",
  ["~ld__xunyou"] = "主公，臣下……先行告退……",
}

local bianfuren = General:new(extension, "ld__bianfuren", "wei", 3)
bianfuren:addCompanions("hs__caocao")
bianfuren:addSkills{"ld__wanwei", "ld__yuejian"}
Fk:loadTranslationTable{
  ["ld__bianfuren"] = "卞夫人",
  ["bianfuren"] = "卞夫人",
  ["#ld__bianfuren"] = "奕世之雍容",
  ["illustrator:ld__bianfuren"] = "雪君S",
  ["~ld__bianfuren"] = "子桓，兄弟之情，不可轻忘…",
}

General:new(extension, "ld__shamoke", "shu", 4):addSkill("ld__jilis")
Fk:loadTranslationTable{
  ["ld__shamoke"] = "沙摩柯",
  ["shamoke"] = "沙摩柯",
  ["#ld__shamoke"] = "五溪蛮王",
  ["illustrator:ld__shamoke"] = "LiuHeng",
  ["designer:ld__shamoke"] = "韩旭",
  ["~ld__shamoke"] = "五溪蛮夷，不可能输！",
}

General:new(extension, "ld__masu", "shu", 3):addSkills{"ld__sanyao", "ld__zhiman"}
Fk:loadTranslationTable{
  ["ld__masu"] = "马谡",
  ["masu"] = "马谡",
  ["#ld__masu"] = "帷幄经谋",
  ["designer:ld__masu"] = "点点",
  ["illustrator:ld__masu"] = "蚂蚁君",
  ["~ld__masu"] = "败军之罪，万死难赎……" ,
}

local lingtong = General:new(extension, "ld__lingtong", "wu", 4)
lingtong:addSkills{ "xuanlve", "yongjin" }
lingtong:addCompanions("hs__ganning")
Fk:loadTranslationTable{
  ["ld__lingtong"] = "凌统",
  ["lingtong"] = "凌统",
  ["#ld__lingtong"] = "豪情烈胆",
  ["designer:ld__lingtong"] = "韩旭",
  ["illustrator:ld__lingtong"] = "F.源",
  ["~ld__lingtong"] = "大丈夫，不惧死亡……",
}

General:new(extension, "ld__lvfan", "wu", 3):addSkills{"diaodu", "diancai"}
Fk:loadTranslationTable{
  ["ld__lvfan"] = "吕范",
  ["lvfan"] = "吕范",
  ["#ld__lvfan"] = "忠笃亮直",
  ["designer:ld__lvfan"] = "韩旭",
  ["illustrator:ld__lvfan"] = "铭zmy",
  ["~ld__lvfan"] = "闻主公欲授大司马之职，容臣不能……谢恩了……",
}

local zuoci = General:new(extension, "ld__zuoci", "qun", 3)
zuoci:addCompanions("ld__yuji")
zuoci:addSkills{"ld__yigui", "ld__jihun"}
zuoci.hidden = true -- FIXME
Fk:loadTranslationTable{
  ["ld__zuoci"] = "左慈",
  ["#ld__zuoci"] = "鬼影神道",
  ["illustrator:ld__zuoci"] = "吕阳",
  ["~ld__zuoci"] = "仙人之逝，魂归九天…",
}

local lijueguosi = General:new(extension, "ld__lijueguosi", "qun", 4)
lijueguosi:addCompanions("hs__jiaxu")
lijueguosi:addSkill("xiongsuan")
Fk:loadTranslationTable{
  ["ld__lijueguosi"] = "李傕郭汜",
  ["lijueguosi"] = "李傕郭汜",
  ["#ld__lijueguosi"] = "犯祚倾祸",
  ["designer:ld__lijueguosi"] = "千幻",
  ["illustrator:ld__lijueguosi"] = "旭",
  ["~ld__lijueguosi"] = "异心相争，兵败战损……",
}

local H = require "packages.hegemony.util"
local lordsunquan = General:new(extension, "ld__lordsunquan", "wu", 4)
lordsunquan.hidden = true
H.lordGenerals["hs__sunquan"] = "ld__lordsunquan"
lordsunquan:addSkills{"jiahe", "lianzi", "jubao"}
lordsunquan:addCompanions{ "wu_generals" }
lordsunquan:addCompanionRule(function(self, other)
  return other:hasKingdom("wu")
end)
Fk:loadTranslationTable{
  ["ld__lordsunquan"] = "君孙权",
  ["#ld__lordsunquan"] = "虎踞江东",
  ["designer:ld__lordsunquan"] = "韩旭",
  ["illustrator:ld__lordsunquan"] = "瞌瞌一休",

  ["~ld__lordsunquan"] = "朕的江山，要倒下了么……",

  ["wu_generals"] = "吴势力武将",
}

return extension
