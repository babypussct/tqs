local H = require "packages.hegemony.util"
local extension = Package:new("momentum")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/momentum/skills")

Fk:loadTranslationTable{
  ["momentum"] = "君临天下·势",
}

local lidian = General:new(extension, "ld__lidian", "wei", 3)
lidian:addSkills{"hs__xunxun", "hs__wangxi"}
lidian:addCompanions("hs__yuejin")
Fk:loadTranslationTable{
  ["ld__lidian"] = "李典",
  ["lidian"] = "李典",
  ["#ld__lidian"] = "深明大义",
  ["designer:ld__lidian"] = "KayaK",
  ["illustrator:ld__lidian"] = "张帅",
  ["~ld__lidian"] = "报国杀敌，虽死犹荣……",
}

local zangba = General:new(extension, "ld__zangba", "wei", 4)
zangba:addSkill("hengjiang")
zangba:addCompanions("hs__zhangliao")
Fk:loadTranslationTable{
  ["ld__zangba"] = "臧霸",
  ["zangba"] = "臧霸",
  ["#ld__zangba"] = "节度青徐",
  ["illustrator:ld__zangba"] = "HOOO",
  ["cv:ld__zangba"] = "墨禅",
  ["~ld__zangba"] = "断刃沉江，负主重托……",
}

local madai = General:new(extension, "ld__madai", "shu", 4)
madai:addSkills{"heg_madai__mashu", "re__qianxi"}
madai:addCompanions("hs__machao")
Fk:loadTranslationTable{
  ["ld__madai"] = "马岱",
  ["madai"] = "马岱",
  ["#ld__madai"] = "临危受命",
  ["designer:ld__madai"] = "凌天翼（韩旭）",
  ["illustrator:ld__madai"] = "Thinking",
  ["~ld__madai"] = "我怎么会死在这里……",
}

General:new(extension, "ld__mifuren", "shu", 3, 3, General.Female):addSkills{ "guixiu", "cunsi" }
Fk:loadTranslationTable{
  ["ld__mifuren"] = "糜夫人",
  ["mifuren"] = "糜夫人",
  ["#ld__mifuren"] = "乱世沉香",
  ["designer:ld__mifuren"] = "淬毒",
  ["illustrator:ld__mifuren"] = "木美人",
  ["~ld__mifuren"] = "阿斗被救，妾身再无牵挂…",
}

local sunce = General:new(extension, "ld__sunce", "wu", 4)
sunce.deputyMaxHpAdjustedValue = -1
sunce:addCompanions { "hs__zhouyu", "hs__taishici", "hs__daqiao" }
sunce:addSkills{ "jiang", "yingyang", "hunshang" }
Fk:loadTranslationTable{
  ["ld__sunce"] = "孙策",
  ["#ld__sunce"] = "江东的小霸王",
  ["designer:ld__sunce"] = "KayaK（韩旭）",
  ["illustrator:ld__sunce"] = "木美人",
  ["~ld__sunce"] = "内事不决问张昭，外事不决问周瑜……",
}

General:new(extension, "ld__chenwudongxi", "wu", 4):addSkills{"duanxie", "fenming"}
Fk:loadTranslationTable{
  ["ld__chenwudongxi"] = "陈武董袭",
  ["chenwudongxi"] = "陈武董袭",
  ["#ld__chenwudongxi"] = "壮怀激烈",
  ["designer:ld__chenwudongxi"] = "淬毒",
  ["illustrator:ld__chenwudongxi"] = "地狱许",
  ["~ld__chenwudongxi"] = "杀身卫主，死而无憾！",
}

General:new(extension, "ld__dongzhuo", "qun", 4):addSkills{ "hengzheng", "baoling" }
Fk:loadTranslationTable{
  ["ld__dongzhuo"] = "董卓",
  ["#ld__dongzhuo"] = "魔王",
  ["designer:ld__dongzhuo"] = "KayaK（韩旭）",
  ["illustrator:ld__dongzhuo"] = "巴萨小马",
  ["~ld__dongzhuo"] = "为何人人……皆与我为敌？",
}

General:new(extension, "ld__zhangren", "qun", 4):addSkills{"ld__xue", "fengshi"}
Fk:loadTranslationTable{
  ["ld__zhangren"] = "张任",
  ["zhangren"] = "张任",
  ["#ld__zhangren"] = "索命神射",
  ["designer:ld__zhangren"] = "淬毒",
  ["illustrator:ld__zhangren"] = "DH",
  ["~ld__zhangren"] = "本将军败于诸葛，无憾……",
}

local lordzhangjiao = General:new(extension, "ld__lordzhangjiao", "qun", 4)
lordzhangjiao.hidden = true
H.lordGenerals["hs__zhangjiao"] = "ld__lordzhangjiao"
lordzhangjiao:addSkills{ "wuxin", "hongfa", "wendao" }
lordzhangjiao:addCompanions{ "qun_generals" }
lordzhangjiao:addCompanionRule(function(self, other)
  return other:hasKingdom("qun")
end)
Fk:loadTranslationTable{
  ["ld__lordzhangjiao"] = "君张角",
  ["#ld__lordzhangjiao"] = "时代的先驱",
  ["designer:ld__lordzhangjiao"] = "韩旭",
  ["illustrator:ld__lordzhangjiao"] = "青骑士",

  ["~ld__lordzhangjiao"] = "天，真要灭我……",

  ["qun_generals"] = "群势力武将",
}

return extension
