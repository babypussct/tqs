local extension = Package:new("jyzs")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/jin_jyzs/skills")

Fk:loadTranslationTable{
  ["jyzs"] = "国战-金印紫授",
}

local H = require "packages.hegemony.util"

General:new(extension, "heg__zhanghuyuechen", "jin", 4):addSkills { "heg__xijue", "heg__lvxian", "heg__yingwei" }
Fk:loadTranslationTable{
  ["heg__zhanghuyuechen"] = "张虎乐綝",
  ["#heg__zhanghuyuechen"] = "不辱门庭",
  ["illustrator:heg__zhanghuyuechen"] = "凝聚永恒",

  ["~heg__zhanghuyuechen"] = "儿有辱……父亲威名……",
}

General:new(extension, "heg__wenyang", "jin", 5):addSkills { "heg__duanqiu" }
Fk:loadTranslationTable{
  ["heg__wenyang"] = "文鸯",
  ["#heg__wenyang"] = "勇冠三军",
  ["illustrator:heg__wenyang"] = "小罗没想好",

  ["~heg__wenyang"] = "欲加之罪，何患吾辞？",
}

General:new(extension, "heg__yanghu", "jin", 4):addSkills { "heg__huaiyuan", "heg__fushou" }
Fk:loadTranslationTable{
  ["heg__yanghu"] = "羊祜",
  ["#heg__yanghu"] = "静水沧笙",
  ["illustrator:heg__yanghu"] = "白",

  ["~heg__yanghu"] = "当断不断，反受其乱……",
}

General:new(extension, "heg__yangjun", "jin", 4):addSkills { "heg__neiji" }
Fk:loadTranslationTable{
  ["heg__yangjun"] = "杨骏",
  ["yangjun"] = "杨骏",
  ["#heg__yangjun"] = "阶缘佞宠",
  ["illustrator:heg__yangjun"] = "荆芥",
}

local bailingyun = General:new(extension, "heg__bailingyun", "jin", 3, 3, General.Female)
bailingyun:addSkills{ "heg__xiace", "heg__limeng" }
bailingyun:addCompanions("heg__simayi")
Fk:loadTranslationTable{
  ["heg__bailingyun"] = "柏夫人",
  ["#heg__bailingyun"] = "玲珑心窍",
  ["illustrator:heg__bailingyun"] = "小罗没想好",

  ["~heg__bailingyun"] = "世人皆惧司马，独我痴情仲达……",
}

General:new(extension, "heg__wangxiang", "jin", 3):addSkills { "heg__bingxin" }
Fk:loadTranslationTable{
  ["heg__wangxiang"] = "王祥",
  ["#heg__wangxiang"] = "沂川跃鲤",
  ["illustrator:heg__wangxiang"] = "KY",

  ["~heg__wangxiang"] = "夫生之有死，自然之理也。",
}

local sunxiu = General:new(extension, "heg__sunxiuj", "jin", 3)
sunxiu:addSkills{ "heg__xiejian", "heg__yinsha" }
sunxiu:addCompanions("heg__simalun")
Fk:loadTranslationTable{
  ["heg__sunxiuj"] = "孙秀",
  ["sunxiuj"] = "孙秀",
  ["#heg__sunxiuj"] = "黄钟毁弃",
  ["illustrator:heg__sunxiuj"] = "荆芥",
}

local duyu = General:new(extension, "heg__duyu", "jin", 4)
duyu.mainMaxHpAdjustedValue = -1
duyu:addCompanions("heg__yanghu")
duyu:addSkills{ "heg__sanchen", "heg__pozhu" }
Fk:loadTranslationTable{
  ["heg__duyu"] = "杜预",
  ["#heg__duyu"] = "文成武德",
  ["illustrator:heg__duyu"] = "君桓文化",

  ["~heg__duyu"] = "金瓯尚缺，死难瞑目……",
}

local lordsimayi = General:new(extension, "heg__lordsimayi", "jin", 4)
lordsimayi.hidden = true
H.lordGenerals["heg__simayi"] = "heg__lordsimayi"
lordsimayi:addSkills{ "heg__jiaping", "heg__guikuang", "heg__shujuan" }
Fk:loadTranslationTable{
  ["heg__lordsimayi"] = "君司马懿",
  ["#heg__lordsimayi"] = "狼顾九州",
  ["illustrator:heg__lordsimayi"] = "凡果",

  ["~heg__lordsimayi"] = "洛水滔滔，难诉吾一生坎坷……",
}

return extension
