local extension = Package:new("tenyear_wei")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_wei/skills")

Fk:loadTranslationTable{
  ["tenyear_wei"] = "十周年-威",
  ["ty_wei"] = "威",
}

--威震天下
General:new(extension, "ty_wei__zhangliao", "qun", 4):addSkills { "yuxi", "porong" }
Fk:loadTranslationTable{
  ["ty_wei__zhangliao"] = "威张辽",
  ["#ty_wei__zhangliao"] = "威锐镇西风",
  ["illustrator:ty_wei__zhangliao"] = "鬼画府",
  ["designer:ty_wei__zhangliao"] = "银蛋",

  ["~ty_wei__zhangliao"] = "血染战袍，虽死犹荣，此心无憾！",
}

General:new(extension, "ty_wei__lvbu", "qun", 5):addSkills { "xiaowul", "baguan" }
Fk:loadTranslationTable{
  ["ty_wei__lvbu"] = "威吕布",
  ["#ty_wei__lvbu"] = "虓虎叱北地",
  ["illustrator:ty_wei__lvbu"] = "第七个桔子",

  ["~ty_wei__lvbu"] = "虓虎失落尽，日暮无归途。",
}

General:new(extension, "ty_wei__dongzhuo", "qun", 6):addSkills { "guangyong", "juchui" }
Fk:loadTranslationTable{
  ["ty_wei__dongzhuo"] = "威董卓",
  ["#ty_wei__dongzhuo"] = "魔震西凉",
  ["illustrator:ty_wei__dongzhuo"] = "鬼画府",
  ["cv:ty_wei__dongzhuo"] = "冷泉夜月",

  ["~ty_wei__dongzhuo"] = "半生戎马，不及门阀一语。",
}

General:new(extension, "ty_wei__machao", "qun", 4):addSkills { "ty__zhongtao", "jizhanm" }
Fk:loadTranslationTable{
  ["ty_wei__machao"] = "威马超",
  ["#ty_wei__machao"] = "雄烈盖世",
  ["illustrator:ty_wei__machao"] = "维柯托骑士",

  ["~ty_wei__machao"] = "战马不休，唯死方卧……",
}

General:new(extension, "ty_wei__gongsunzan", "qun", 4):addSkills { "juxi", "ty__zhuitao" }
Fk:loadTranslationTable{
  ["ty_wei__gongsunzan"] = "威公孙瓒",
  ["#ty_wei__gongsunzan"] = "武勇戾猛",
  -- ["illustrator:ty_wei__gongsunzan"] = "",

  ["~ty_wei__gongsunzan"] = "此身焚尽处，千山震绝嵘！",
}

General:new(extension, "ty_wei__mateng", "qun", 4):addSkills { "heqim", "huirui", "xiaoben" }
Fk:loadTranslationTable{
  ["ty_wei__mateng"] = "威马腾",
  ["#ty_wei__mateng"] = "千骑卷黄沙",
  -- ["illustrator:ty_wei__mateng"] = "",

  ["~ty_wei__mateng"] = "铁骑失其主，天地失其色。",
}

General:new(extension, "ty_wei__caozhang", "wei", 5):addSkills { "kuipan", "ningpao" }
Fk:loadTranslationTable{
  ["ty_wei__caozhang"] = "威曹彰",
  ["#ty_wei__caozhang"] = "功武驰誉",
  -- ["illustrator:ty_wei__caozhang"] = "",

  -- ["~ty_wei__caozhang"] = "",
}

--君威盖世
General:new(extension, "ty_wei__sunquan", "wu", 4):addSkills { "woheng", "yuhui" }
Fk:loadTranslationTable{
  ["ty_wei__sunquan"] = "威孙权",
  ["#ty_wei__sunquan"] = "坐断东南",
  ["illustrator:ty_wei__sunquan"] = "鬼画府",

  ["~ty_wei__sunquan"] = "自古许多忧，英雄老来愁……",
}

General:new(extension, "ty_wei__caopi", "wei", 4):addSkills { "sugang", "dianlun", "jiweic" }
Fk:loadTranslationTable{
  ["ty_wei__caopi"] = "威曹丕",
  ["#ty_wei__caopi"] = "威泽四海都",
  ["illustrator:ty_wei__caopi"] = "君桓文化",

  ["~ty_wei__caopi"] = "建平所言八十，谓昼夜也，吾其绝矣。",
}

General:new(extension, "ty_wei__caocao", "wei", 4):addSkills { "duoyue", "junhe", "xiongwei" }
Fk:loadTranslationTable{
  ["ty_wei__caocao"] = "威曹操",
  ["#ty_wei__caocao"] = "山海归心",
  ["illustrator:ty_wei__caocao"] = "君桓文化",

  ["~ty_wei__caocao"] = "孤这一生，何其壮哉，哈哈哈哈！",
}

General:new(extension, "ty_wei__sunce", "wu", 5):addSkills { "zhifeng", "weijings" }
Fk:loadTranslationTable{
  ["ty_wei__sunce"] = "威孙策",
  ["#ty_wei__sunce"] = "勇冠三江势",
  ["illustrator:ty_wei__sunce"] = "",

  ["~ty_wei__sunce"] = "恨，不见九鼎，尽刻吴纹。",
}

General:new(extension, "ty_wei__liubei", "shu", 4):addSkills { "liexiang", "rengou" }
Fk:loadTranslationTable{
  ["ty_wei__liubei"] = "威刘备",
  ["#ty_wei__liubei"] = "志昭义烈",
  -- ["illustrator:ty_wei__liubei"] = "",

  ["~ty_wei__liubei"] = "朕不为弟报仇，纵有万里江山，何足为贵！",
}

--片羽威凤
General:new(extension, "ty_wei__sunshangxiang", "wu", 3, 3, General.Female):addSkills { "shuren", "saran" }
Fk:loadTranslationTable{
  ["ty_wei__sunshangxiang"] = "威孙尚香",
  ["#ty_wei__sunshangxiang"] = "巽荷绽情",
  ["illustrator:ty_wei__sunshangxiang"] = "黯荧岛",

  ["~ty_wei__sunshangxiang"] = "荷残风住时，无物可赠君。",
}

General:new(extension, "ty_wei__xingcai", "shu", 3, 3, General.Female):addSkills { "huangnu", "xiankuang" }
Fk:loadTranslationTable{
  ["ty_wei__xingcai"] = "威张星彩",
  ["#ty_wei__xingcai"] = "帼姿凤舞",
  --["illustrator:ty_wei__xingcai"] = "",

  ["~ty_wei__xingcai"] = "陛下良善，请诸公容之辅之。",
}

General:new(extension, "ty_wei__guanyinping", "shu", 4, 4, General.Female):addSkills { "shaowei", "dichou" }
Fk:loadTranslationTable{
  ["ty_wei__guanyinping"] = "威关银屏",
  ["#ty_wei__guanyinping"] = "凋棠醒春薄",
  --["illustrator:ty_wei__guanyinping"] = "",

  --["~ty_wei__guanyinping"] = "",
}

return extension
