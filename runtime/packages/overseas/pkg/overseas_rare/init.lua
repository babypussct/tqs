local extension = Package:new("overseas_rare")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_rare/skills")

Fk:loadTranslationTable{
  ["overseas_rare"] = "国际服-稀有专属",
  ["os_xing"] = "国际星",
}

General:new(extension, "os__himiko", "qun", 3, 3, General.Female):addSkills { "os__zongkui", "os__guju", "os__baijia", "os__bingzhao" }
Fk:loadTranslationTable{
  ["os__himiko"] = "卑弥呼",
  ["#os__himiko"] = "邪马台女王",
  ["illustrator:os__himiko"] = "杨杨和夏季",

  ["~os__himiko"] = "鬼道破灭，我有何寄托？",
}

General:new(extension, "os__gexuan", "qun", 3):addSkills { "os__danfa", "os__lingbao", "os__sidao" }
Fk:loadTranslationTable{
  ["os__gexuan"] = "葛玄",
  ["#os__gexuan"] = "冲应真人",
  ["illustrator:os__gexuan"] = "凝聚永恒",

  ["~os__gexuan"] = "金丹难成，大道难修……",
  ["!os__gexuan"] = "科有天禁不可抑，华精庵蔼化仙人。",
}

General:new(extension, "os__zhuling", "wei", 4):addSkill("os__zhanyi")
Fk:loadTranslationTable{
  ["os__zhuling"] = "朱灵",
  ["#os__zhuling"] = "良将之亚",
  ["cv:os__zhuling"] = "秦且歌",
  ["illustrator:os__zhuling"] = "NOVART",

  ["~os__zhuling"] = "此生得遇曹公，再无他求。",
}

General:new(extension, "os__zhugeguo", "shu", 3, 3, General.Female):addSkills { "os__qirang", "os__yuhua" }
Fk:loadTranslationTable{
  ["os__zhugeguo"] = "诸葛果",
  ["#os__zhugeguo"] = "凤阁乘烟",
  ["illustrator:os__zhugeguo"] = "alien",

  ["~os__zhugeguo"] = "方生方死，方死方生。",
}

General:new(extension, "os__lingju", "qun", 3, 3, General.Female):addSkills { "os__jieyuan", "os__fenxin", "os__fuchen" }
Fk:loadTranslationTable{
  ["os__lingju"] = "灵雎",
  ["#os__lingju"] = "情随梦逝",
  ["illustrator:os__lingju"] = "木美人", -- 阵面对决

  ["~os__lingju"] = "",
}

General:new(extension, "os_xing__zhanghe", "qun", 4):addSkill("os_xing__zhilue")
Fk:loadTranslationTable{
  ["os_xing__zhanghe"] = "星张郃",
  ["#os_xing__zhanghe"] = "宁国中郎将",
  ["illustrator:os_xing__zhanghe"] = "凡果",

  ["~os_xing__zhanghe"] = "吾筹划而思，奈何还是慢了一步。",
  ["!os_xing__zhanghe"] = "天易之理可胜，知略更甚以往。",
}

General:new(extension, "nashime", "qun", 3):addSkills { "os__chijie", "os__waishi", "os__renshe" }
Fk:loadTranslationTable{
  ["nashime"] = "难升米",
  ["#nashime"] = "率善中郎将",
  ["illustrator:nashime"] = "杨杨和夏季",
  ["designer:nashime"] = "Loun老萌",

  ["~nashime"] = "请把这身残躯，带回我的家乡……",
}

local weiyan = General:new(extension, "os_xing__weiyan", "qun", 4)
weiyan.shield = 1
weiyan:addSkills { "os__guli", "os_xing__aosi" }
Fk:loadTranslationTable{
  ["os_xing__weiyan"] = "星魏延",
  ["#os_xing__weiyan"] = "骜勇孤战",
  ["illustrator:os_xing__weiyan"] = "凡果", -- 摧敌气豪

  ["~os_xing__weiyan"] = "庸夫之怒，终不过血流五步尔……",
}

General:new(extension, "os_xing__fazheng", "qun", 3):addSkills { "os__cangjia", "duohui", "os__yueyuan" }
Fk:loadTranslationTable{
  ["os_xing__fazheng"] = "星法正",
  ["#os_xing__fazheng"] = "弹铗待试",
  ["illustrator:os_xing__fazheng"] = "",

  ["~os_xing__fazheng"] = "",
}

General:new(extension, "os_xing__dongzhuo", "qun", 3, 5):addSkills { "os__xiongjin", "os__zhenbian", "baoxi" }
Fk:loadTranslationTable{
  ["os_xing__dongzhuo"] = "星董卓",
  ["#os_xing__dongzhuo"] = "破羌安边",

  ["~os_xing__dongzhuo"] = "本欲坐观时变，奈何天不遂我啊。",
}

General:new(extension, "os_xing__zhoubuyi", "wei", 3):addSkills { "huiyao", "os__quesong" }
Fk:loadTranslationTable{
  ["os_xing__zhoubuyi"] = "星周不疑",
  ["#os_xing__zhoubuyi"] = "稚雀清声",
  ["illustrator:os_xing__zhoubuyi"] = "zoo", -- 白雀献瑞

  ["$huiyao_os_xing__zhoubuyi1"] = "虽晓万类之理，未可逆而改之。",
  ["$huiyao_os_xing__zhoubuyi2"] = "研品类而俯察，究天文而仰观。",
  ["~os_xing__zhoubuyi"] = "吾与仓舒私交甚笃，丞相为何杀我……",
}

return extension
