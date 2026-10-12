local extension = Package:new("tenyear_other")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_other/skills")

Fk:loadTranslationTable{
  ["tenyear_other"] = "十周年-其他",
  ["tycl"] = "典",
  ["child"] = "儿童节",
}

General:new(extension, "longwang", "god", 3):addSkills { "ty__longgong", "ty__sitian" }
Fk:loadTranslationTable{
  ["longwang"] = "东海龙王",
  ["#longwang"] = "呼风唤雨",--称号出自巅峰斗地主
  ["illustrator:longwang"] = "匠人绘",

  ["~longwang"] = "三年之期已到，哥们要回家啦…",
}

General:new(extension, "taoshen", "god", 3):addSkills { "ty__nutao" }
Fk:loadTranslationTable{
  ["taoshen"] = "涛神",
  ["#taoshen"] = "驱水为涛",--称号出自巅峰斗地主
  ["illustrator:taoshen"] = "青学",

  ["~taoshen"] = "马革裹尸，身沉江心。",
}

General:new(extension, "libai", "god", 3):addSkills { "jiuxian", "shixian" }
Fk:loadTranslationTable{
  ["libai"] = "李白",
  ["#libai"] = "诗人卧词",--称号出自巅峰斗地主
  ["illustrator:libai"] = "匠人绘",

  ["~libai"] = "谁识卧龙客，长吟愁鬓斑。",
}

General:new(extension, "khan", "god", 3):addSkills { "tongliao", "wudao" }
Fk:loadTranslationTable{
  ["khan"] = "小约翰可汗",
  ["cv:khan"] = "小约翰可汗",

  ["~khan"] = "留得青山在，老天爷饿不死瞎家雀。",
}

General:new(extension, "zhutiexiong", "god", 3):addSkills { "bianzhuang" }
Fk:loadTranslationTable{
  ["zhutiexiong"] = "朱铁雄",
  ["cv:zhutiexiong"] = "朱铁雄",

  ["~zhutiexiong"] = "那些看似很可笑的梦，是我们用尽全力守护的光……",
}

General:new(extension, "tycl__caocao", "wei", 4):addSkills { "tycl__jianxiong" }
Fk:loadTranslationTable{
  ["tycl__caocao"] = "经典曹操",
  ["#tycl__caocao"] = "乱世的奸雄",--称号出自巅峰斗地主
  ["illustrator:tycl__caocao"] = "Kayak",

  ["~tycl__caocao"] = "霸业未成未成啊！",
}

General:new(extension, "tycl__liubei", "shu", 4):addSkills { "tycl__rende" }
Fk:loadTranslationTable{
  ["tycl__liubei"] = "经典刘备",
  ["#tycl__liubei"] = "乱世的枭雄",
  ["illustrator:tycl__liubei"] = "Kayak",

  ["~tycl__liubei"] = "这就是桃园吗？",
}

General:new(extension, "tycl__sunquan", "wu", 4):addSkills { "tycl__zhiheng" }
Fk:loadTranslationTable{
  ["tycl__sunquan"] = "经典孙权",
  ["#tycl__sunquan"] = "年轻的贤君",
  ["illustrator:tycl__sunquan"] = "Kayak",

  ["~tycl__sunquan"] = "父亲大哥仲谋愧矣。",
}

General:new(extension, "sunwukong", "god", 3):addSkills { "jinjing", "ruyi", "cibeis" }
Fk:loadTranslationTable{
  ["sunwukong"] = "孙悟空",
  ["#sunwukong"] = "斗战胜佛",--称号出自巅峰斗地主
  ["illustrator:sunwukong"] = "匠人绘",

  ["~sunwukong"] = "曾经有一整片蟠桃园在我面前，失去后才追悔莫及……",
}

local nezha = General:new(extension, "nezha", "god", 3)
nezha:addSkills { "santou", "faqi" }
nezha.fixMaxHp = 3
Fk:loadTranslationTable{
  ["nezha"] = "哪吒",
  ["#nezha"] = "三坛海会大神",--称号出自巅峰斗地主
  ["illustrator:nezha"] = "匠人绘",

  ["~nezha"] = "莲藕花开，始知三清……",
}

General:new(extension, "tycl__sunce", "wu", 4):addSkills { "shuangbi" }
Fk:loadTranslationTable{
  ["tycl__sunce"] = "双璧孙策",
  ["#tycl__sunce"] = "江东双璧",--称号出自2026收藏
  ["illustrator:tycl__sunce"] = "游卡",
}

General:new(extension, "tycl__wuyi", "shu", 4):addSkills { "tycl__benxi" }
Fk:loadTranslationTable{
  ["tycl__wuyi"] = "名将吴懿",
  ["#tycl__wuyi"] = "五一名将",--称号出自天水濯名
  ["illustrator:tycl__wuyi"] = "biou09",
}

local c_sunquan = General:new(extension, "child__sunquan", "wu", 3)
c_sunquan:addSkills { "huiwan", "huanli" }
c_sunquan:addRelatedSkills { "zhijian", "guzheng", "ex__yingzi", "ex__fanjian", "ex__zhiheng" }
Fk:loadTranslationTable{
  ["child__sunquan"] = "小孙权",
  ["#child__sunquan"] = "牌堆的掌控者",--称号出自天水濯名
  ["illustrator:child__sunquan"] = "游漫美绘",

  ["~child__sunquan"] = "阿娘，大哥抢我糖人！",
}

General:new(extension, "quyuan", "qun", 3):addSkills { "qiusuo", "lisao" }
Fk:loadTranslationTable{
  ["quyuan"] = "屈原",
  ["#quyuan"] = "楚辞之祖",--称号出自天水濯名
  ["cv:quyuan"] = "虞晓旭",
  ["illustrator:quyuan"] = "君桓文化",

  ["~quyuan"] = "伏清白以死直兮，固前圣之所厚。",
}

General:new(extension, "wuming", "qun", 3):addSkills { "chushan" }
Fk:loadTranslationTable{
  ["wuming"] = "无名",
  ["illustrator:wuming"] = "凝聚永恒",
}

General:new(extension, "liuxiecaojie", "qun", 2):addSkills { "juanlv", "qixin" }
Fk:loadTranslationTable{
  ["liuxiecaojie"] = "刘协曹节",
  ["#liuxiecaojie"] = "双宿双飞",--称号出自巅峰斗地主
  ["illustrator:liuxiecaojie"] = "凝聚永恒",
}

General:new(extension, "xunyuxunyou", "wei", 3):addSkills { "zhinang", "gouzhu" }
Fk:loadTranslationTable{
  ["xunyuxunyou"] = "荀彧荀攸",
  ["#xunyuxunyou"] = "谋定天下",--称号出自天水濯名
  ["illustrator:xunyuxunyou"] = "黯荧岛",
}

General:new(extension, "weiqing", "qun", 3):addSkills { "beijin" }
Fk:loadTranslationTable{
  ["weiqing"] = "卫青",
  ["#weiqing"] = "追亡逐北",--称号出自巅峰斗地主
  ["illustrator:weiqing"] = "鬼画府",
}

General:new(extension, "tycl__cenhun", "wu", 3):addSkills { "baoshi", "xinggong" }
Fk:loadTranslationTable{
  ["tycl__cenhun"] = "食岑昏",
  ["#tycl__cenhun"] = "生啖其肉",--称号出自巅峰斗地主
  ["illustrator:tycl__cenhun"] = "凝聚永恒",
}

General:new(extension, "tianjiq", "qun", 3):addSkills { "weijit", "saima" }
Fk:loadTranslationTable{
  ["tianjiq"] = "田忌",
  ["#tianjiq"] = "高瞻远瞩",--称号出自巅峰斗地主
  ["illustrator:tianjiq"] = "鬼画府",
}

General:new(extension, "yuanshaoyuanshu", "qun", 4):addSkills { "lieti", "shigong", "luankui" }
Fk:loadTranslationTable{
  ["yuanshaoyuanshu"] = "烈袁绍袁术",
  ["#yuanshaoyuanshu"] = "四世三公",--称号出自巅峰斗地主
  ["illustrator:yuanshaoyuanshu"] = "鬼画府",
}

General:new(extension, "tycl__dengai", "wei", 4):addSkills { "neyan", "qianyao" }
Fk:loadTranslationTable{
  ["tycl__dengai"] = "忍邓艾",
  ["#tycl__dengai"] = "忍尤攘诟",--称号出自2026收藏
  ["illustrator:tycl__dengai"] = "鬼画府",
}

General:new(extension, "tycl__jiangwei", "shu", 4):addSkills { "ty__huoluan", "guxing" }
Fk:loadTranslationTable{
  ["tycl__jiangwei"] = "忍姜维",
  ["#tycl__jiangwei"] = "忍辱负重",--称号出自2026收藏
  ["illustrator:tycl__jiangwei"] = "鬼画府",
}

General:new(extension, "tycl__zhugeliang", "shu", 3):addSkills { "ty__yingyou" }
Fk:loadTranslationTable{
  ["tycl__zhugeliang"] = "有诸葛亮",
  ["#tycl__zhugeliang"] = "应有尽有",--称号出自巅峰斗地主
  ["illustrator:tycl__zhugeliang"] = "君桓文化",
}

General:new(extension, "tengjiananhai", "qun", 1, 4):addSkills { "tenggu", "dunyong" }
Fk:loadTranslationTable{
  ["tengjiananhai"] = "藤甲男孩",
  ["#tengjiananhai"] = "火之盾",
  ["illustrator:tengjiananhai"] = "宁涛",

  ["~tengjiananhai"] = "慢！我当何辞？",
}

General:new(extension, "ice_sword_girl", "qun", 3, 3, General.Female):addSkills { "bingling" }
Fk:loadTranslationTable{
  ["ice_sword_girl"] = "寒冰剑少女",
  ["#ice_sword_girl"] = "冰之剑",--称号出自巅峰斗地主
  ["illustrator:ice_sword_girl"] = "执兮",

  ["~ice_sword_girl"] = "山中无甲子，寒尽不知年。",
}

General:new(extension, "ty_sp__puyuan", "shu", 4):addSkills { "biancai", "cuiren", "shenfeng" }
Fk:loadTranslationTable{
  ["ty_sp__puyuan"] = "蒲元",
  ["#ty_sp__puyuan"] = "变废为宝",--称号出自巅峰斗地主
  ["illustrator:ty_sp__puyuan"] = "鬼画府",

  --["~ty_sp__puyuan"] = "",
}

return extension
