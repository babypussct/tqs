local extension = Package:new("formation")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

local H = require "packages.hegemony.util"

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/formation/skills")

Fk:loadTranslationTable{
  ["formation"] = "君临天下·阵",
  ["ld"] = "国战",
}

local dengai = General:new(extension, "ld__dengai", "wei", 4)
dengai.mainMaxHpAdjustedValue = -1
dengai:addSkills{ "ld__tuntian", "ld__jixi", "ziliang" }
Fk:loadTranslationTable{
  ["ld__dengai"] = "邓艾",
  ["#ld__dengai"] = "矫然的壮士",
  ["designer:ld__dengai"] = "KayaK（淬毒）",
  ["illustrator:ld__dengai"] = "Amo",
  ["~ld__dengai"] = "君不知臣，臣不知君。罢了……罢了！",
}

local caohong = General:new(extension, "ld__caohong", "wei", 4)
caohong:addSkills{"ld__huyuan", "heyi"}
caohong:addCompanions("hs__caoren")
Fk:loadTranslationTable{
  ["ld__caohong"] = "曹洪",
  ["caohong"] = "曹洪",
  ["#ld__caohong"] = "魏之福将",
  ["illustrator:ld__caohong"] = "YellowKiss",
  ["cv:ld__caohong"] = "绯川陵彦",
  ["~ld__caohong"] = "曹公，可安好…",
}

local jiangwei = General:new(extension, "ld__jiangwei", "shu", 4)
jiangwei:addCompanions("hs__zhugeliang")
jiangwei.deputyMaxHpAdjustedValue = -1
jiangwei:addSkills{ "tiaoxin", "tianfu", "yizhi" }
Fk:loadTranslationTable{
  ["ld__jiangwei"] = "姜维",
  ["#ld__jiangwei"] = "龙的衣钵",
  ["designer:ld__jiangwei"] = "KayaK（淬毒）",
  ["illustrator:ld__jiangwei"] = "木美人",

  ["$tiaoxin_ld__jiangwei1"] = "小小娃娃，乳臭未干。",
  ["$tiaoxin_ld__jiangwei2"] = "快滚回去，叫你主将出来！",

  ["~ld__jiangwei"] = "臣等正欲死战，陛下何故先降？",
}

local jiangfei = General:new(extension, "ld__jiangwanfeiyi", "shu", 3)
jiangfei:addSkills{ "shengxi", "shoucheng" }
jiangfei:addCompanions("hs__zhugeliang")
Fk:loadTranslationTable{
  ["ld__jiangwanfeiyi"] = "蒋琬费祎",
  ["jiangwanfeiyi"] = "蒋琬费祎",
  ["#ld__jiangwanfeiyi"] = "社稷股肱",
  ["designer:ld__jiangwanfeiyi"] = "淬毒",
  ["illustrator:ld__jiangwanfeiyi"] = "cometrue",
  ["~ld__jiangwanfeiyi"] = "墨守成规，终为其害啊……",
}

local xusheng = General:new(extension, "ld__xusheng", "wu", 4)
xusheng:addSkill("yicheng")
xusheng:addCompanions("hs__dingfeng")
Fk:loadTranslationTable{
  ["ld__xusheng"] = "徐盛",
  ["xusheng"] = "徐盛",
  ["#ld__xusheng"] = "江东的铁壁",
  ["designer:ld__xusheng"] = "淬毒",
  ["illustrator:ld__xusheng"] = "天信",
  ["~ld__xusheng"] = "可怜一身胆略，尽随一抔黄土……",
}

local jiangqin = General:new(extension, "ld__jiangqin", "wu", 4)
jiangqin:addSkills{ "shangyi", "niaoxiang" }
jiangqin:addCompanions("hs__zhoutai")
Fk:loadTranslationTable{
  ["ld__jiangqin"] = "蒋钦",
  ["jiangqin"] = "蒋钦",
  ["#ld__jiangqin"] = "祁奚之器",
  ["designer:ld__jiangqin"] = "淬毒",
  ["illustrator:ld__jiangqin"] = "天空之城",
  ["cv:ld__jiangqin"] = "小六",
  ["~ld__jiangqin"] = "竟破我阵法…",
}

General:new(extension, "ld__yuji", "qun", 3):addSkill("qianhuan")
Fk:loadTranslationTable{
  ["ld__yuji"] = "于吉",
  ["#ld__yuji"] = "魂绕左右",
  ["designer:ld__yuji"] = "淬毒",
  ["illustrator:ld__yuji"] = "G.G.G.",
  ["~ld__yuji"] = "幻化之物，终是算不得真呐。",
}

General:new(extension, "ld__hetaihou", "qun", 3, 3, General.Female):addSkills{ "zhendu", "qiluan" }
Fk:loadTranslationTable{
  ["ld__hetaihou"] = "何太后",
  ["hetaihou"] = "何太后",
  ["#ld__hetaihou"] = "弄权之蛇蝎",
  ["cv:ld__hetaihou"] = "水原",
  ["illustrator:ld__hetaihou"] = "KayaK&木美人",
  ["designer:ld__hetaihou"] = "淬毒",
  ["~ld__hetaihou"] = "你们男人造的孽，非要说什么红颜祸水……",
}

local lordliubei = General:new(extension, "ld__lordliubei", "shu", 4)
lordliubei.hidden = true
H.lordGenerals["hs__liubei"] = "ld__lordliubei"
lordliubei:addSkills{ "zhangwu", "shouyue", "jizhao" }
lordliubei:addCompanions{ "shu_generals" }
lordliubei:addCompanionRule(function(self, other)
  return other:hasKingdom("shu")
end)
Fk:loadTranslationTable{
  ["ld__lordliubei"] = "君刘备",
  ["#ld__lordliubei"] = "龙横蜀汉",
  ["designer:ld__lordliubei"] = "韩旭",
  ["illustrator:ld__lordliubei"] = "LiuHeng",

  ["$ex__rende_ld__lordliubei1"] = "勿以恶小而为之，勿以善小而不为。",
  ["$ex__rende_ld__lordliubei2"] = "君才十倍于丕，必能安国成事。",
  ["~ld__lordliubei"] = "若嗣子可辅，辅之。如其不才，君可自取……",

  ["shu_generals"] = "蜀势力武将",
}

return extension
