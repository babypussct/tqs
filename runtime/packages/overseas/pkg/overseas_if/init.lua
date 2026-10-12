local extension = Package:new("overseas_if")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_if/skills")

Fk:loadTranslationTable{
  ["overseas_if"] = "国际服-IF篇",
  ["os_if"] = "国际幻",
  ["os_if_huan"] = "入幻",
}

--- 定（北定中原）

General:new(extension, "os_if__zhugeliang", "shu", 3, 4):addSkills { "os__beiding", "os__jielv", "os__hunyou" }
Fk:loadTranslationTable{
  ["os_if__zhugeliang"] = "幻诸葛亮",
  ["#os_if__zhugeliang"] = "天意可叹",
  ["illustrator:os_if__zhugeliang"] = "黯荧岛",

  ["~os_if__zhugeliang"] = "先帝遗志未竟，吾怎可终于半途。",
  ["!os_if__zhugeliang"] = "卧龙腾于九天，炎汉之火长明。",
}

local zhugeliang = General:new(extension, "os_if_huan__zhugeliang", "shu", 3, 4)
zhugeliang.hidden = true
zhugeliang:addSkills { "os_huan__beiding", "os_huan__jielv", "os__huanji", "os__changgui" }
Fk:loadTranslationTable{
  ["os_if_huan__zhugeliang"] = "幻诸葛亮",
  ["#os_if_huan__zhugeliang"] = "天意可叹",
  ["illustrator:os_if_huan__zhugeliang"] = "黯荧岛",

  ["~os_if_huan__zhugeliang"] = "一人之愿，终难逆天命……",
  ["!os_if_huan__zhugeliang"] = "卧龙腾于九天，炎汉之火长明。",
}

General:new(extension, "os_if__zhaoyun", "shu", 4):addSkills { "os__jiezhan", "os__longjin" }
Fk:loadTranslationTable{
  ["os_if__zhaoyun"] = "幻赵云",
  ["#os_if__zhaoyun"] = "天武耆龙",
  ["illustrator:os_if__zhaoyun"] = "铁杵",

  ["$longdan_os_if__zhaoyun1"] = "进退有度，百战无伤！",
  ["$longdan_os_if__zhaoyun2"] = "龙魂缠身，虎威犹在！",
  ["$chongzhen_os_if__zhaoyun1"] = "众将士，且随老夫再战一场！",
  ["$chongzhen_os_if__zhaoyun2"] = "出入千军万马，经年横战八方！",
  ["~os_if__zhaoyun"] = "转战一生，终得见兴汉之日。",
}

General:new(extension, "os_if__zhanghe", "wei", 4):addSkills { "os__kuiduan" }
Fk:loadTranslationTable{
  ["os_if__zhanghe"] = "幻张郃",
  ["#os_if__zhanghe"] = "追敌入彀",
  ["illustrator:os_if__zhanghe"] = "铁杵",

  ["~os_if__zhanghe"] = "老卒迟暮，恨不能再报于国……",
}

General:new(extension, "os_if__jiangwei", "shu", 4):addSkills { "os__qinghan", "os__zhihuan" }
Fk:loadTranslationTable{
  ["os_if__jiangwei"] = "幻姜维",
  ["#os_if__jiangwei"] = "麒麟擎汉",
  ["illustrator:os_if__jiangwei"] = "刘小狼Syaoran",

  ["~os_if__jiangwei"] = "九州未定，维有负丞相遗托。",
}

General:new(extension, "os_if__zhugeguo", "shu", 3, 3, General.Female):addSkills { "os__xianyuan", "os__lingyin" }
Fk:loadTranslationTable{
  ["os_if__zhugeguo"] = "幻诸葛果",
  ["#os_if__zhugeguo"] = "悠游清汉",
  ["illustrator:os_if__zhugeguo"] = "福州暗金",

  ["~os_if__zhugeguo"] = "仙缘已了，魂入轮回。",
}

General:new(extension, "os_if__simayi", "wei", 3):addSkills { "os__zongquan", "os__guimou" }
Fk:loadTranslationTable{
  ["os_if__simayi"] = "幻司马懿",
  ["#os_if__simayi"] = "权谋并施",
  ["illustrator:os_if__simayi"] = "凝聚永恒",

  ["~os_if__simayi"] = "天命已定，汝竟能逆之……",
}

General:new(extension, "os_if__weiyan", "shu", 4):addSkills { "os__qiji", "os__piankuang" }
Fk:loadTranslationTable{
  ["os_if__weiyan"] = "幻魏延",
  ["#os_if__weiyan"] = "自矜功伐",
  ["illustrator:os_if__weiyan"] = "凝聚永恒",

  ["~os_if__weiyan"] = "若无粮草之急，何致有今日此败！",
}

General:new(extension, "os_if__liushan", "shu", 3):addSkills { "os__guihanh", "os__renxian", "os__yanzuok" }
Fk:loadTranslationTable{
  ["os_if__liushan"] = "幻刘禅",
  ["#os_if__liushan"] = "汉祚永延",
  --["illustrator:os_if__liushan"] = "",

  ["~os_if__liushan"] = "天下分崩离乱，再难建兴……",
}

General:new(extension, "os_if__luxun", "wu", 3):addSkills { "os__lifengh", "os__niwo" }
Fk:loadTranslationTable{
  ["os_if__luxun"] = "幻陆逊",
  ["#os_if__luxun"] = "审机而行",
  --["illustrator:os_if__luxun"] = "",

  ["~os_if__luxun"] = "但为大吴万世基业，臣死亦不改匡谏之心！",
}

--- 兴（魏昂龙兴）

General:new(extension, "os_if__caoang", "wei", 2, 3):addSkills { "os__chihui", "os__fuxi" }
Fk:loadTranslationTable{
  ["os_if__caoang"] = "幻曹昂",
  ["#os_if__caoang"] = "穿时寻冀",
  --["illustrator:os_if__caoang"] = "",

  ["$os__huangzhu_os_if__caoang1"] = "既见明日煌煌，何惧长夜漫漫。",
  ["$os__huangzhu_os_if__caoang2"] = "九天之光，终破长空！",
  ["$os__liyuan_os_if__caoang1"] = "虽九死之地，亦当搏一线生机。",
  ["$os__liyuan_os_if__caoang2"] = "吾志在天下万方，岂能困亡于此！",
  ["~os_if__caoang"] = "漫漫长夜，何时可见光明。",
  ["!os_if__caoang"] = "拂晓之光，终慰吾灵。",
}

local caoang = General:new(extension, "os_if_huan__caoang", "wei", 2, 3)
caoang.hidden = true
caoang:addSkills { "os__huangzhu", "os__liyuan", "os__jifa" }
Fk:loadTranslationTable{
  ["os_if_huan__caoang"] = "幻曹昂",
  ["#os_if_huan__caoang"] = "穿时寻冀",
  --["illustrator:os_if_huan__caoang"] = "",

  ["$os__chihui_os_if_huan__caoang1"] = "欲成王业，蜡炬成灰终无悔！",
  ["$os__chihui_os_if_huan__caoang2"] = "但为大魏社稷，又何顾此身！",
  ["~os_if_huan__caoang"] = "纵天予再造之恩，然恨吾亦未能成业。",
  ["!os_if_huan__caoang"] = "煌煌大魏，万世长明！",
}

General:new(extension, "os_if__dingfuren", "wei", 3, 3, General.Female):addSkills { "os__shiyih", "os__chunhui" }
Fk:loadTranslationTable{
  ["os_if__dingfuren"] = "幻丁夫人",
  ["#os_if__dingfuren"] = "懿德广扬",
  --["illustrator:os_if__dingfuren"] = "",

  ["~os_if__dingfuren"] = "今生之缘未断，还盼来生……",
}

General:new(extension, "os_if__huanggai", "wu", 4):addSkills { "os__fenxian", "os__juyan" }
Fk:loadTranslationTable{
  ["os_if__huanggai"] = "幻黄盖",
  ["#os_if__huanggai"] = "休戚归烬",
  --["illustrator:os_if__huanggai"] = "",

  ["~os_if__huanggai"] = "功败……垂成……",
}

General:new(extension, "os_if__caopi", "wei", 3):addSkills { "os__qianxiong", "os__zhengdi", "os__junsi" }
Fk:loadTranslationTable{
  ["os_if__caopi"] = "幻曹丕",
  ["#os_if__caopi"] = "溺于宸渊",
  --["illustrator:os_if__caopi"] = "",

  ["~os_if__caopi"] = "天授吾以大任，何故复而夺之……",
}

General:new(extension, "os_if__dianwei", "wei", 4):addSkills { "os__miewei", "os__miyong" }
Fk:loadTranslationTable{
  ["os_if__dianwei"] = "幻典韦",
  ["#os_if__dianwei"] = "拔山超海",
  --["illustrator:os_if__dianwei"] = "",

  ["~os_if__dianwei"] = "黄泉路上，某亦护主公左右……",
}

local liufeng = General:new(extension, "os_if__liufeng", "shu", 4)
liufeng.shield = 1
liufeng:addSkills { "os__chenxun" }
Fk:loadTranslationTable{
  ["os_if__liufeng"] = "幻刘封",
  ["#os_if__liufeng"] = "忠烈不驯",
  --["illustrator:os_if__liufeng"] = "",

  ["~os_if__liufeng"] = "断臂之犬，焉能挡我？……呃啊！",
}

General:new(extension, "os_if__caozhi", "wei", 3):addSkills { "os__hanhong", "os__huazhang" }
Fk:loadTranslationTable{
  ["os_if__caozhi"] = "幻曹植",
  ["#os_if__caozhi"] = "赋怀山河",
  --["illustrator:os_if__caozhi"] = "",

  ["~os_if__caozhi"] = "从此江海寄浮生……",
}

General:new(extension, "os_if__caochong", "wei", 3):addSkills { "os__fushu", "os__xiumu" }
Fk:loadTranslationTable{
  ["os_if__caochong"] = "幻曹冲",
  ["#os_if__caochong"] = "枯树新芽",
  --["illustrator:os_if__caochong"] = "",

  ["~os_if__caochong"] = "骨肉至亲，何必如此？",
}

--- 霸王问鼎

General:new(extension, "os_if__sunce", "wu", 4, 4):addSkills{ "os__liwu", "os__saoting", "os__jianyanc" }
Fk:loadTranslationTable{
  ["os_if__sunce"] = "幻孙策",
  ["#os_if__sunce"] = "独霸中原",

  ["!os_if__sunce"] = "坐拥三江，天下何不闻孙氏之威！",
  ["~os_if__sunce"] = "尔等宵小，便是斗至阴司，也还是我赢！",
}

local sunce = General:new(extension, "os_if_huan__sunce", "wu", 4, 4)
sunce.hidden = true
sunce:addSkills { "os__suzhen", "os__dangjiang", "os__jizhis" }
Fk:loadTranslationTable{
  ["os_if_huan__sunce"] = "幻孙策",
  ["#os_if_huan__sunce"] = "独霸中原",

  ["!os_if_huan__sunce"] = "九州皆畏吾名，天下尽服吾威！",
  ["~os_if_huan__sunce"] = "未能尽扫九州，只恨大梦先觉。",
}

General:new(extension, "os_if__daqiao", "wu", 3, 3, General.Female):addSkills{ "os__guosek", "os__liulis" }
Fk:loadTranslationTable{
  ["os_if__daqiao"] = "幻大乔",
  ["#os_if__daqiao"] = "温矜姝华",

  ["!os_if__daqiao"] = "我协于内，君在外无忧矣。",
  ["~os_if__daqiao"] = "不求肇建之功，只求此生不离。",
}

General:new(extension, "os_if__zhouyu", "wu", 4):addSkills{ "os__dumou", "os__hantian" }
Fk:loadTranslationTable{
  ["os_if__zhouyu"] = "幻周瑜",
  ["#os_if__zhouyu"] = "幻焰浮瑛",

  ["!os_if__zhouyu"] = "逢战必胜，此东吴之风！",
  ["~os_if__zhouyu"] = "伯符之业，瑜虽身死亦当佑之……",
}

General:new(extension, "os_if__xiaoqiao", "wu", 3, 3, General.Female):addSkills{ "os__shuyin", "os__fangyan" }
Fk:loadTranslationTable{
  ["os_if__xiaoqiao"] = "幻小乔",

  ["!os_if__xiaoqiao"] = "礼存乐兴，江东必存百年！",
  ["~os_if__xiaoqiao"] = "纵是同心为国，难阻夫妻别离……",
}

return extension
