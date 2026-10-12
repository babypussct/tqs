local extension = Package:new("power")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/power/skills")

Fk:loadTranslationTable{
  ["power"] = "君临天下·权",
}

local H = require "packages.hegemony.util"

local cuiyanmaojie = General:new(extension, "ld__cuiyanmaojie", "wei", 3)
cuiyanmaojie:addSkills{"ld__zhengbi", "ld__fengying"}
cuiyanmaojie:addCompanions("hs__caopi")
Fk:loadTranslationTable{
  ["ld__cuiyanmaojie"] = "崔琰毛玠",
  ["cuiyanmaojie"] = "崔琰毛玠",
  ["#ld__cuiyanmaojie"] = "日出月盛",
  ["designer:ld__cuiyanmaojie"] = "Virgopaladin（韩旭）",
  ["illustrator:ld__cuiyanmaojie"] = "兴游",
  ["~ld__cuiyanmaojie"] = "为世所痛惜，冤哉……",
}

local yujin = General:new(extension, "ld__yujin", "wei", 4)
yujin:addSkills{"ld__jieyue"}
yujin:addCompanions("hs__xiahoudun")
Fk:loadTranslationTable{
  ["ld__yujin"] = "于禁",
  ["yujin"] = "于禁",
  ["#ld__yujin"] = "讨暴坚垒",
  ["designer:ld__yujin"] = "Virgopaladin（韩旭）",
  ["illustrator:ld__yujin"] = "biou09",
  ["~ld__yujin"] = "此役一败，晚节不保啊……",
}

local wangping = General:new(extension, "ld__wangping", "shu", 4)
wangping:addCompanions("ld__jiangwanfeiyi")
wangping:addSkill("jianglue")
Fk:loadTranslationTable{
  ["ld__wangping"] = "王平",
  ["#ld__wangping"] = "键闭剑门",
  ["illustrator:ld__wangping"] = "zoo",
  ["~ld__wangping"] = "无当飞军，也有困于深林之时……",
}

local fazheng = General:new(extension, "ld__fazheng", "shu", 3)
fazheng:addCompanions("hs__liubei")
fazheng:addSkills{ "ld__xuanhuo","ld__enyuan"}
Fk:loadTranslationTable{
  ["ld__fazheng"] = "法正",
  ["fazheng"] = "法正",
  ["#ld__fazheng"] = "蜀汉的辅翼",
  ["illustrator:ld__fazheng"] = "黑白画谱",

  ["~ld__fazheng"] = "汉室复兴，我，是看不到了……",
}

local lukang = General:new(extension, "ld__lukang", "wu", 3)
lukang:addSkills{ "ld__keshou", "ld__zhuwei" }
lukang:addCompanions("hs__luxun")
Fk:loadTranslationTable{
  ["ld__lukang"] = "陆抗",
  ["#ld__lukang"] = "孤柱扶厦",
  ["illustrator:ld__lukang"] = "王立雄",
  ["~ld__lukang"] = "吾既亡矣，又能存几时…",
}

local wuguotai = General:new(extension, "ld__wuguotai", "wu", 3, 3, General.Female)
wuguotai:addSkills{"ld__buyi", "ganlu"}
wuguotai:addCompanions("hs__sunjian")
Fk:loadTranslationTable{
  ["ld__wuguotai"] = "吴国太",
  ["wuguotai"] = "吴国太",
  ["#ld__wuguotai"] = "武烈皇后",
  ["illustrator:ld__wuguotai"] = "李秀森",
  ["$ganlu_ld__wuguotai1"] = "玄德，实乃佳婿呀！",
  ["$ganlu_ld__wuguotai2"] = "好一个郎才女貌，真是天作之合啊。",
  ["~ld__wuguotai"] = "诸位卿家，还请尽力辅佐仲谋啊……",
}

local yuanshu = General:new(extension, "ld__yuanshu", "qun", 4)
yuanshu:addCompanions("hs__jiling")
yuanshu:addSkills{ "ld__weidi", "ld__yongsi" }
Fk:loadTranslationTable{
  ["ld__yuanshu"] = "袁术",
  ["yuanshu"] = "袁术",
  ["#ld__yuanshu"] = "仲家帝",
  ["illustrator:ld__yuanshu"] = "YanBai",
  ["~ld__yuanshu"] = "可恶！就差……一步了……",
}

local zhangxiu = General:new(extension, "ld__zhangxiu", "qun", 4)
zhangxiu:addSkills{"ld__fudi", "ld__congjian"}
zhangxiu:addCompanions("hs__jiaxu")
Fk:loadTranslationTable{
  ["ld__zhangxiu"] = "张绣",
  ["#ld__zhangxiu"] = "北地枪王",
  ["designer:ld__zhangxiu"] = "千幻",
  ["illustrator:ld__zhangxiu"] = "青岛磐蒲",
  ["~ld__zhangxiu"] = "若失文和，吾将何归？",
}

local lordcaocao = General:new(extension, "ld__lordcaocao", "wei", 4)
lordcaocao.hidden = true
H.lordGenerals["hs__caocao"] = "ld__lordcaocao"
lordcaocao:addSkills{ "jianan", "huibian", "zongyu" }
lordcaocao:addCompanions{ "wei_generals" }
lordcaocao:addCompanionRule(function(self, other)
  return other:hasKingdom("wei")
end)
Fk:loadTranslationTable{
  ["ld__lordcaocao"] = "君曹操",
  ["#ld__lordcaocao"] = "凤舞九霄",
  ["illustrator:ld__lordcaocao"] = "波子",

  ["~ld__lordcaocao"] = "神龟虽寿，犹有竟时。腾蛇乘雾，终为土灰。",

  ["wei_generals"] = "魏势力武将",
}

return extension
