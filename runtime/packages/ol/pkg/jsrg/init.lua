local extension = Package:new("ol_jsrg")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/jsrg/skills")

Fk:loadTranslationTable{
  ["ol_jsrg"] = "OL-江山如故",
  ["ol_js"] = "OL江山",
}

General:new(extension, "ol_js__zhaoyun", "shu", 4):addSkills { "ol__longlin", "ol__zhendan" }
Fk:loadTranslationTable{
  ["ol_js__zhaoyun"] = "闪赵云",
  ["#ol_js__zhaoyun"] = "北伐之柱",
  --["illustrator:ol_js__zhaoyun"] = "",

  ["~ol_js__zhaoyun"] = "北伐点将，丞相为何置我于不顾？",
}

General:new(extension, "ol_js__liuhong", "qun", 4):addSkills { "ol__chaozheng", "ol__shenchong", "ol__julian" }
Fk:loadTranslationTable{
  ["ol_js__liuhong"] = "闪刘宏",
  ["#ol_js__liuhong"] = "轧庭焚礼",
  --["illustrator:ol_js__liuhong"] = "",

  ["~ol_js__liuhong"] = "中兴无望，唯将大志托于此剑……",
}

local zhangliao = General:new(extension, "ol_js__zhangliao", "qun", 4)
zhangliao.subkingdom = "wei"
zhangliao:addSkills { "ol__zhengbing", "ol__tuwei" }
Fk:loadTranslationTable{
  ["ol_js__zhangliao"] = "闪张辽",
  ["#ol_js__zhangliao"] = "利刃风骑",
  --["illustrator:ol_js__zhangliao"] = "",

  ["~ol_js__zhangliao"] = "病厄缠身，君恩难报……",
}

General:new(extension, "ol_js__zhujun", "qun", 4):addSkills { "ol__fendi", "ol__jvxiang" }
Fk:loadTranslationTable{
  ["ol_js__zhujun"] = "闪朱儁",
  ["#ol_js__zhujun"] = "得假日月",
  --["illustrator:ol_js__zhujun"] = "",

  ["~ol_js__zhujun"] = "郭多竖子，恨不能悬头见你殁亡之日……",
}

General:new(extension, "ol_js__sunjian", "qun", 4):addSkills { "ol__pingtao", "ol__juelie" }
Fk:loadTranslationTable{
  ["ol_js__sunjian"] = "闪孙坚",
  ["#ol_js__sunjian"] = "拨定烈志",
  ["illustrator:ol_js__sunjian"] = "小牛",

  ["~ol_js__sunjian"] = "罪逆董卓，该杀，该杀！",
}

local zhanghe = General:new(extension, "ol_js__zhanghe", "qun", 4)
zhanghe.subkingdom = "wei"
zhanghe:addSkills { "ol__qiongtu", "ol__xianzhao" }
Fk:loadTranslationTable{
  ["ol_js__zhanghe"] = "闪张郃",
  ["#ol_js__zhanghe"] = "伐虢百里",
  --["illustrator:ol_js__zhanghe"] = "",

  ["~ol_js__zhanghe"] = "公天威难抵，郃必效死力。",
}

return extension
