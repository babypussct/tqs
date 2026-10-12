local extension = Package:new("overseas_mougong")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_mougong/skills")

Fk:loadTranslationTable{
  ["overseas_mougong"] = "国际服-谋攻篇",
  ["os_mou"] = "国际谋",
}

--知
General:new(extension, "os_mou__zhangjiao", "qun", 3):addSkills { "mou__leiji", "os_mou__guidao", "os_mou__huangtian" }
Fk:loadTranslationTable{
  ["os_mou__zhangjiao"] = "谋张角",
  ["#os_mou__zhangjiao"] = "驱雷掣电",
  ["illustrator:os_mou__zhangjiao"] = "凡果", -- 借法黄天

  ["~os_mou__zhangjiao"] = "天书浩渺，不可穷极……",
}

--识
General:new(extension, "os_mou__chengong", "qun", 3):addSkills { "os_mou__mingce", "mou__zhichi" }
Fk:loadTranslationTable{
  ["os_mou__chengong"] = "谋陈宫",
  ["#os_mou__chengong"] = "刚直壮烈",
  ["illustrator:os_mou__chengong"] = "光域", -- 壮怀终计

  ["$mou__zhichi_os_mou__chengong1"] = "此地不便久留，不若另寻他处。",
  ["$mou__zhichi_os_mou__chengong2"] = "暂退三舍，再做计议。",
  ["~os_mou__chengong"] = "只恨……当年未能一剑杀了你！",
}

General:new(extension, "os_mou__caopi", "wei", 3):addSkills { "os_mou__xingshang", "os_mou__fangzhu", "os_mou__songwei" }
Fk:loadTranslationTable{
  ["os_mou__caopi"] = "谋曹丕",
  ["#os_mou__caopi"] = "魏文帝",
  ["illustrator:os_mou__caopi"] = "花狐貂",

  ["~os_mou__caopi"] = "人生百年，惟立德扬名可不朽……",
  ["!os_mou__caopi"] = "临观大魏山河，千秋万载汤汤！",
}

General:new(extension, "os_mou__zhanghe", "wei", 4):addSkills { "os_mou__qiaobian", "os_mou__liaoshi" }
Fk:loadTranslationTable{
  ["os_mou__zhanghe"] = "谋张郃",
  ["#os_mou__zhanghe"] = "变数尽展",
	["illustrator:os_mou__zhanghe"] = "地狱许", -- 从征四方

  ["~os_mou__zhanghe"] = "舍身为国，虽死无憾！",
}

--同
General:new(extension, "os_mou__zhuran", "wu", 4):addSkills { "os__zhenweiz", "os__heyuan" }
Fk:loadTranslationTable{
  ["os_mou__zhuran"] = "谋朱然",
  ["#os_mou__zhuran"] = "不动之督",
  ["illustrator:os_mou__zhuran"] = "铁杵文化", -- 临沮截击

  ["!os_mou__zhuran"] = "",
  ["~os_mou__zhuran"] = "臣寿数已尽，望主公珍重。",
}

--虞
General:new(extension, "os_mou__luzhi", "qun", 3):addSkills { "os_mou__mingren", "os_mou__zhenliang" }
Fk:loadTranslationTable{
  ["os_mou__luzhi"] = "谋卢植",
  ["#os_mou__luzhi"] = "国之桢干",
  ["cv:os_mou__luzhi"] = "袁国庆",
  --["illustrator:os_mou__luzhi"] = "",

  ["~os_mou__luzhi"] = "",
}

--能
General:new(extension, "os_mou__lvbu", "qun", 5):addSkills { "os_mou__wushuang", "os_mou__liyu" }
Fk:loadTranslationTable{
  ["os_mou__lvbu"] = "谋吕布",
  ["#os_mou__lvbu"] = "宇内无双",
  ["illustrator:os_mou__lvbu"] = "",

  ["~os_mou__lvbu"] = "",
}

General:new(extension, "os_mou__zhugejin", "wu", 3):addSkills { "mou__huanshi", "os_mou__hongyuan", "os_mou__mingzhe" }
Fk:loadTranslationTable{
  ["os_mou__zhugejin"] = "谋诸葛瑾",
  ["#os_mou__zhugejin"] = "才猷蕴借",
  ["illustrator:os_mou__zhugejin"] = "",

  ["~os_mou__zhugejin"] = "",
}

return extension
