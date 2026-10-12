local extension = Package:new("overseas_wuxia")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_wuxia/skills")

Fk:loadTranslationTable{
  ["overseas_wuxia"] = "国际服-武侠篇",

  ["#JointPindianDesc"] = "#\"<b>共同拼点</b>\"：所有角色一起比大小（而非“同时拼点”：发起者和其余角色两两各比大小）。",
}

General:new(extension, "wangyue", "qun", 4):addSkills { "os__yulong", "os__jianming" }
Fk:loadTranslationTable{
  ["wangyue"] = "王越",
  ["#wangyue"] = "驭龙在天",
  ["illustrator:wangyue"] = "鱼仔",

  ["~wangyue"] = "汉室中兴，不系于吾一人……",
}

General:new(extension, "liyan", "qun", 4):addSkills { "os__zhenhu", "os__lvren" }
Fk:loadTranslationTable{
  ["liyan"] = "李彦",
  ["#liyan"] = "暴虎冯河",

  ["~liyan"] = "戾气入髓，不可再起杀心……",
}

General:new(extension, "os__tongyuan", "qun", 4):addSkills { "os__chaofeng", "os__chuanshu" }
Fk:loadTranslationTable{
  ["os__tongyuan"] = "童渊",
  ["#os__tongyuan"] = "凤鸣麟出",
  ["illustrator:os__tongyuan"] = "M云涯",

  ["~os__tongyuan"] = "隐居山水，空老病榻。",
}

General:new(extension, "os__xia__xushu", "qun", 4):addSkills { "os__jiange", "os__xiawang" }
Fk:loadTranslationTable{
  ["os__xia__xushu"] = "侠徐庶",
  ["#os__xia__xushu"] = "仗剑为侠",
  ["illustrator:os__xia__xushu"] = "zoo",

  ["~os__xia__xushu"] = "天下为公……",
}

General:new(extension, "xiahouzie", "qun", 3, 4, General.Female):addSkills { "os__xuechang", "os__duoren" }
Fk:loadTranslationTable{
  ["xiahouzie"] = "夏侯紫萼",
  ["#xiahouzie"] = "孤草飘零",
  ["illustrator:xiahouzie"] = "M云涯",

  ["~xiahouzie"] = "祖父，紫萼不能为您昭雪了……",
}

General:new(extension, "os__xia__lusu", "qun", 4):addSkills { "os__kaizeng", "os__yangming" }
Fk:loadTranslationTable{
  ["os__xia__lusu"] = "侠鲁肃",
  ["#os__xia__lusu"] = "性善好施",
  ["illustrator:os__xia__lusu"] = "zoo",

  ["~os__xia__lusu"] = "人心不足，巴蛇吞象……",
}

General:new(extension, "os__xia__dianwei", "qun", 4):addSkills { "os__liexi", "os__shezhong" }
Fk:loadTranslationTable{
  ["os__xia__dianwei"] = "侠典韦",
  ["#os__xia__dianwei"] = "任侠报怨",
  ["illustrator:os__xia__dianwei"] = "鱼仔",

  ["~os__xia__dianwei"] = "少智无谋，空负此身勇武……",
}

General:new(extension, "zhaoe", "qun", 3, 3, General.Female):addSkills { "os__yanshi", "os__renchou" }
Fk:loadTranslationTable{
  ["zhaoe"] = "赵娥",
  ["#zhaoe"] = "烈女誓仇",
  ["illustrator:zhaoe"] = "充电JUJU",

  ["~zhaoe"] = "乞就刑戮，肃明王法……",
}

General:new(extension, "os__xia__xiahoudun", "qun", 4):addSkill("os__danlie")
Fk:loadTranslationTable{
  ["os__xia__xiahoudun"] = "侠夏侯惇",
  ["#os__xia__xiahoudun"] = "刚烈勇猛",
  ["illustrator:os__xia__xiahoudun"] = "鬼画府",

  ["~os__xia__xiahoudun"] = "英雄烈胆，何惧泉台一战……",
}

General:new(extension, "zhangwei", "qun", 3, 3, General.Female):addSkills { "os__huzhong", "os__fenwang" }
Fk:loadTranslationTable{
  ["zhangwei"] = "张葳",
  ["#zhangwei"] = "舍生取义",
  ["illustrator:zhangwei"] = "腥鱼仔",

  ["~zhangwei"] = "百姓……安否……",
}

General(extension, "os__xia__liubei", "shu", 4):addSkills { "os__shenyi", "os__xinghan" }
Fk:loadTranslationTable{
  ["os__xia__liubei"] = "侠刘备",
  ["#os__xia__liubei"] = "为国为民",
  ["illustrator:os__xia__liubei"] = "特特肉",

  ["~os__xia__liubei"] = "楼桑羽葆，终是一梦……",
}

General:new(extension, "xiahouzieh", "qun", 4, 4, General.Female):addSkill("os__chengxi")
Fk:loadTranslationTable{
  ["xiahouzieh"] = "夏侯子萼",
  ["#xiahouzieh"] = "承继婆娑",
  ["illustrator:xiahouzieh"] = "错落宇宙",

  ["~xiahouzieh"] = "蔷薇凋零，永沉血海……",
}

General:new(extension, "os__xia__guanyu", "qun", 4):addSkills { "os__chue", "os__zhongyi" }
Fk:loadTranslationTable{
  ["os__xia__guanyu"] = "侠关羽",
  ["#os__xia__guanyu"] = "义薄云天",
  ["illustrator:os__xia__guanyu"] = "zoo",

  ["~os__xia__guanyu"] = "丈夫终有一死，唯恨壮志难酬。",
}

-- local yuzhenzi = General(extension, "yuzhenzi", "qun", 3)


Fk:loadTranslationTable{
  ["yuzhenzi"] = "玉真子",
  ["#yuzhenzi"] = "神功天授",
  ["illustrator:yuzhenzi"] = "铁杵",

  ["os__huajing"] = "化境",
  [":os__huajing"] = "①游戏开始时，你获得6个（未生效的）“武”标记。②有“武”的角色攻击范围+X（X为其有的“武”数）。②出牌阶段限一次，你可展示至多四张手牌，随机获得其中花色数个“武”的效果直到回合结束。③若一名角色有“武”且有对应的效果，其装备区里武器牌的技能失效。<br/ ><font color='grey'>" ..
    "<b>6个“武”</b>分别为：<br /><b>剑</b>：你使用【杀】指定目标后，随机弃置其两张手牌<br/ >" ..
    "<b>刀</b>：你使用【杀】对目标角色造成伤害时，若其没有手牌，此伤害+1<br/ >" ..
    "<b>斧</b>：你使用【杀】被【闪】抵消时，对目标角色造成1点伤害<br/ >" ..
    "<b>枪</b>：你使用的黑色【杀】结算结束后，从牌堆或弃牌堆中获得一张【闪】<br/ >" ..
    "<b>戟</b>：你使用【杀】造成伤害时，摸一张牌<br/ >" ..
    "<b>弓</b>：你使用【杀】对一名角色造成伤害后，随机弃置其装备区里的一张牌",
  ["os__tianshou"] = "天授",
  [":os__tianshou"] = "锁定技，回合结束时，若你此回合使用【杀】造成过伤害，你须选择1个生效的“武”交给一名其他角色并令其获得对应效果，然后摸两张牌。其下回合结束后移除此“武”。",

  ["$os__huajing1"] = "瞬息之间，已蕴森罗万象之法！",
  ["$os__huajing2"] = "万般兵器，皆由吾心所化！",
  ["$os__tianshou1"] = "既怀远志，此武可助汝成之！",
  ["$os__tianshou2"] = "汝得此术，当勤为善行，勿动恶念！",
  ["~yuzhenzi"] = "吾身归去，如化大道。",
}

General:new(extension, "shie", "wei", 4):addSkills { "os__dengjian", "os__xinshou" }
Fk:loadTranslationTable{
  ["shie"] = "史阿",
  ["#shie"] = "剑术登峰",
  ["illustrator:shie"] = "凝聚永恒",

  ["~shie"] = "江湖路远，吾等终会有再见之时。",
}

General:new(extension, "shitao", "qun", 4):addSkills { "os__jieqiu", "os__enchou" }
Fk:loadTranslationTable{
  ["shitao"] = "石韬",
  ["#shitao"] = "快意恩仇",
  ["illustrator:shitao"] = "鱼仔",

  ["~shitao"] = "想不到竟中了官府的埋伏……",
}

return extension
