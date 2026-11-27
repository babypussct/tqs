local extension = Package:new("mobile_heg")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/mobile_heg/skills")

Fk:loadTranslationTable{
  ["mobile_heg"] = "国战-手杀专属",
  ["m_heg"] = "手杀国战",
}

local xiahoudun = General:new(extension, "m_heg__xiahoudun", "wei", 5)
xiahoudun:addSkill("ganglie")
xiahoudun:addCompanions("hs__xiahouyuan")
Fk:loadTranslationTable{
  ["m_heg__xiahoudun"] = "夏侯惇",
  ["#m_heg__xiahoudun"] = "独眼的罗刹",
  ["illustrator:m_heg__xiahoudun"] = "KayaK",

  ["~m_heg__xiahoudun"] = "两边都看不见了……",
}

local xiahouyuan = General:new(extension, "m_heg__xiahouyuan", "wei", 4)
xiahouyuan:addSkill("m_heg__shensu")
xiahouyuan:addCompanions{"hs__xiahoudun", "m_heg__xiahoudun"}
Fk:loadTranslationTable{
  ["m_heg__xiahouyuan"] = "夏侯渊",
  ["#m_heg__xiahouyuan"] = "疾行的猎豹",

  ["~m_heg__xiahouyuan"] = "竟然比我还……快……",
}

General:new(extension, "m_heg__dianwei", "wei", 4):addSkills{ "m_heg__qiangxi" }
Fk:loadTranslationTable{
  ["m_heg__dianwei"] = "典韦",
  ["#m_heg__dianwei"] = "古之恶来",
  ["illustrator:m_heg__dianwei"] = "凝聚永恒",

  ["~m_heg__dianwei"] = "主公，快走！",
}

local ganfuren = General:new(extension, "m_heg__ganfuren", "shu", 3, 3, General.Female)
ganfuren:addSkills{ "m_heg__shushen", "nos_heg__shenzhi" }
ganfuren:addCompanions{ "hs__liubei" }
Fk:loadTranslationTable{
  ["m_heg__ganfuren"] = "甘夫人",
  ["#m_heg__ganfuren"] = "昭烈皇后",
  ["illustrator:m_heg__ganfuren"] = "MUMU",

  ["~m_heg__ganfuren"] = "请替我照顾好阿斗……",
}

General:new(extension, "m_heg__ganning", "wu", 4):addSkills{ "qixi", "m_heg__fenwei" }
Fk:loadTranslationTable{
  ["m_heg__ganning"] = "甘宁",
  ["#m_heg__ganning"] = "锦帆游侠",
  --["illustrator:m_heg__ganning"] = "",

  ["~m_heg__ganning"] = "",
}

local luxun = General:new(extension, "m_heg__luxun", "wu", 3)
luxun:addSkills{ "m_heg__qianxun", "m_heg__duoshi" }
luxun:addCompanions{ "ld__lukang" }
Fk:loadTranslationTable{
  ["m_heg__luxun"] = "陆逊",
  ["#m_heg__luxun"] = "擎天之柱",
  ["illustrator:m_heg__luxun"] = "Zero",
  ["~m_heg__luxun"] = "还以为我已经不再年轻……",
}

General:new(extension, "m_heg__dingfeng", "wu", 4):addSkills{ "duanbing", "m_heg__fenxun" }
Fk:loadTranslationTable{
  ["m_heg__dingfeng"] = "丁奉",
  ["#m_heg__dingfeng"] = "清侧重臣",
  --["illustrator:m_heg__dingfeng"] = "",

  ["~m_heg__dingfeng"] = "",
}

General:new(extension, "m_heg__panfeng", "qun", 4):addSkills{ "m_heg__kuangfu" }
Fk:loadTranslationTable{
  ["m_heg__panfeng"] = "潘凤",
  ["#m_heg__panfeng"] = "联军上将",
  ["illustrator:m_heg__panfeng"] = "明暗交界",

  ["~m_heg__panfeng"] = "潘凤又被华雄斩了。",
}

local caohong = General:new(extension, "m_heg__caohong", "wei", 4)
caohong:addSkills{ "nos_heg__huyuan", "m_heg__heyi" }
caohong:addCompanions("hs__caoren")
Fk:loadTranslationTable{
  ["m_heg__caohong"] = "曹洪",
  ["#m_heg__caohong"] = "魏之福将",
  ["illustrator:m_heg__caohong"] = "LiuHeng",

  ["~m_heg__caohong"] = "曹公，可安好……",
}

local jiangwei = General:new(extension, "m_heg__jiangwei", "shu", 4)
jiangwei:addCompanions("hs__zhugeliang")
jiangwei.deputyMaxHpAdjustedValue = -1
jiangwei:addSkills{ "tiaoxin", "m_heg__tianfu", "yizhi" }
Fk:loadTranslationTable{
  ["m_heg__jiangwei"] = "姜维",
  ["#m_heg__jiangwei"] = "龙的衣钵",
  ["illustrator:m_heg__jiangwei"] = "木美人",

  ["$tiaoxin_m_heg__jiangwei1"] = "小小娃娃，乳臭未干。",
  ["$tiaoxin_m_heg__jiangwei2"] = "快滚回去，叫你主将出来！",
  ["$guanxing_m_heg__jiangwei1"] = "天文地理，丞相所教。维，铭记于心。",
  ["$guanxing_m_heg__jiangwei2"] = "哪怕只有一线生机，我也不会放弃。",
  ["~m_heg__jiangwei"] = "臣等正欲死战，陛下何故先降？",
}

General:new(extension, "m_heg__jiangwanfeiyi", "shu", 3):addSkills{ "ty__shengxi", "shoucheng" }
Fk:loadTranslationTable{
  ["m_heg__jiangwanfeiyi"] = "蒋琬费祎",
  ["#m_heg__jiangwanfeiyi"] = "社稷股肱",
  ["illustrator:m_heg__jiangwanfeiyi"] = "",

  ["~m_heg__jiangwanfeiyi"] = "墨守成规，终为其害啊……",
}

local jiangqin = General:new(extension, "m_heg__jiangqin", "wu", 4)
jiangqin:addSkills{ "shangyi", "m_heg__niaoxiang" }
jiangqin:addCompanions("hs__zhoutai")
Fk:loadTranslationTable{
  ["m_heg__jiangqin"] = "蒋钦",
  ["#m_heg__jiangqin"] = "祁奚之器",
  ["illustrator:m_heg__jiangqin"] = "铁杵文化",

  ["~m_heg__jiangqin"] = "竟破我阵法…",
}

General:new(extension, "m_heg__zhangren", "qun", 4):addSkills{ "m_heg__chuanxin", "m_heg__fengshi" }
Fk:loadTranslationTable{
  ["m_heg__zhangren"] = "张任",
  ["#m_heg__zhangren"] = "索命神射",
  ["illustrator:m_heg__zhangren"] = "君桓文化",

  ["~m_heg__zhangren"] = "本将军败于诸葛，无憾……",
}

local xushu = General:new(extension, "m_heg__xushu", "shu", 4)
xushu.deputyMaxHpAdjustedValue = -1
xushu:addCompanions{ "hs__zhaoyun", "hs__wolong" }
xushu:addSkills{ "m_heg__zhuhai", "m_heg__jiancai" }
Fk:loadTranslationTable{
  ["m_heg__xushu"] = "徐庶",
  ["#m_heg__xushu"] = "智勇侠义",
  ["illustrator:m_heg__xushu"] = "",

  ["~m_heg__xushu"] = "未尽孝道，抱憾此生。",
}

local pengyang = General:new(extension, "m_heg__pengyang", "shu", 3)
pengyang.subkingdom = "qun"
pengyang:addSkills{ "m_heg__daming", "m_heg__xiaoni" }
Fk:loadTranslationTable{
  ["m_heg__pengyang"] = "彭羕",
  ["#m_heg__pengyang"] = "误身的狂士",
  ["illustrator:m_heg__pengyang"] = "铁杵文化",

  ["~m_heg__pengyang"] = "招祸自咎，无不自己……",
}

General:new(extension, "m_heg__duyu", "qun", 4):addSkills{ "m_heg__wuku", "m_heg__miewu" }
Fk:loadTranslationTable{
  ["m_heg__duyu"] = "杜预",
  ["#m_heg__duyu"] = "文成武德",
  ["illustrator:m_heg__duyu"] = "鬼画府",

  ["~m_heg__duyu"] = "洛水圆石，遂道向南，吾将以俭自完耳……",
}

General:new(extension, "m_heg__dongcheng", "qun", 4):addSkills{ "m_heg__chengzhao" }
Fk:loadTranslationTable{
  ["m_heg__dongcheng"] = "董承",
  ["#m_heg__dongcheng"] = "沥胆卫汉",
  --["illustrator:m_heg__dongcheng"] = "",

  ["~m_heg__dongcheng"] = "九泉之下，我等着你曹贼到来！",
}

General:new(extension, "m_heg__xiahoushang", "wei", 4):addSkills{ "m_heg__tanfeng" }
Fk:loadTranslationTable{
  ["m_heg__xiahoushang"] = "夏侯尚",
  ["#m_heg__xiahoushang"] = "魏胤前驱",
  ["illustrator:m_heg__xiahoushang"] = "云涯",

  ["~m_heg__xiahoushang"] = "陛下垂怜至此，臣纵死无憾……",
}

local liaohua = General:new(extension, "m_heg__liaohua", "shu", 4)
liaohua:addCompanions("hs__guanyu")
liaohua:addSkills{ "m_heg__dangxian" }
Fk:loadTranslationTable{
  ["m_heg__liaohua"] = "廖化",
  ["#m_heg__liaohua"] = "历尽沧桑",
  ["designer:m_heg__liaohua"] = "梦魇狂朝",
  ["illustrator:m_heg__liaohua"] = "聚一工作室",

  ["~m_heg__liaohua"] = "兴复大业，就靠你们了……",
}

General:new(extension, "m_heg__zhoufang", "wu", 3):addSkills { "duanfa", "sp__youdi" }
Fk:loadTranslationTable{
  ["m_heg__zhoufang"] = "周鲂",
  ["#m_heg__zhoufang"] = "下发载义",
  ["illustrator:m_heg__zhoufang"] = "黑白画谱",

  ["~m_heg__zhoufang"] = "功亏一篑，功亏一篑啊。",
}

General:new(extension, "m_heg__liwei", "shu", 4):addSkills { "mobile__jiaohua" }
Fk:loadTranslationTable{
  ["m_heg__liwei"] = "李遗",
  ["#m_heg__liwei"] = "伏被俞元",
  ["illustrator:m_heg__liwei"] = "君桓文化",

  ["~m_heg__liwei"] = "安南重任，万不可轻之……",
}

General:new(extension, "m_heg__huaxiong", "qun", 4):addSkills { "m_heg__yaowu", "m_heg__shiyong" }
Fk:loadTranslationTable{
  ["m_heg__huaxiong"] = "华雄",
  ["#m_heg__huaxiong"] = "魔将",
  ["illustrator:m_heg__huaxiong"] = "地狱许",

  ["~m_heg__huaxiong"] = "皮厚，不挡刀啊……",
}

General:new(extension, "m_heg__gongsunzan", "qun", 4):addSkills { "m_heg__yicong", "m_heg__henge" }
Fk:loadTranslationTable{
  ["m_heg__gongsunzan"] = "公孙瓒",
  ["#m_heg__gongsunzan"] = "白马将军",
  --["illustrator:m_heg__gongsunzan"] = "",

  ["~m_heg__gongsunzan"] = "我军将败，我已无颜苟活于世……",
}

local lordcaocao = General:new(extension, "m_heg__lordcaocao", "wei", 4)
lordcaocao.heg_lord = "hs__caocao"
lordcaocao.hidden = true
lordcaocao:addSkills{ "m_heg__xiongchi", "m_heg__zhengrongc", "m_heg__junwei" }
lordcaocao:addCompanions{ "wei_generals" }
lordcaocao:addCompanionRule(function(self, other)
  return other:hasKingdom("wei")
end)
Fk:loadTranslationTable{
  ["m_heg__lordcaocao"] = "君曹操",
  --["#m_heg__lordcaocao"] = "",
  ["illustrator:m_heg__lordcaocao"] = "云涯",

  ["$m_heg__junwei_m_heg__lordcaocao1"] = "孤代天子举兵，所伐俱是乱臣！",
  ["$m_heg__junwei_m_heg__lordcaocao2"] = "骖六龙以骋志，巡四海之永宁。",
  ["!m_heg__lordcaocao"] = "无孤之征戎，汉室早不复矣！",
  ["~m_heg__lordcaocao"] = "四百年来枯骨，大江东去英雄……",
}

local lordliubei = General:new(extension, "m_heg__lordliubei", "shu", 4)
lordliubei.heg_lord = "hs__liubei"
lordliubei.hidden = true
lordliubei:addSkills{ "m_heg__lizhong", "m_heg__zhangwu", "m_heg__junwei" }
lordliubei:addCompanions{ "shu_generals" }
lordliubei:addCompanionRule(function(self, other)
  return other:hasKingdom("shu")
end)
Fk:loadTranslationTable{
  ["m_heg__lordliubei"] = "君刘备",
  --["#m_heg__lordliubei"] = "",
  --["illustrator:m_heg__lordliubei"] = "",

  ["$m_heg__junwei_m_heg__lordliubei1"] = "登台受禅，恭承天祚；兹是建国，其名为汉！",
  ["$m_heg__junwei_m_heg__lordliubei2"] = "朕以二剑傍身，一剑日仁，一剑日义。",
  ["!m_heg__lordliubei"] = "彰汉德昭昭，感情义烈烈！",
  ["~m_heg__lordliubei"] = "汉室危亡，皆朕之过也……",
}

local lordsunquan = General:new(extension, "m_heg__lordsunquan", "wu", 4)
lordsunquan.heg_lord = "hs__sunquan"
lordsunquan.hidden = true
lordsunquan:addSkills{ "m_heg__dushou", "m_heg__jvjiang", "m_heg__junwei" }
lordsunquan:addCompanions{ "wu_generals" }
lordsunquan:addCompanionRule(function(self, other)
  return other:hasKingdom("wu")
end)
Fk:loadTranslationTable{
  ["m_heg__lordsunquan"] = "君孙权",
  --["#m_heg__lordsunquan"] = "",
  --["illustrator:m_heg__lordsunquan"] = "",

  ["$m_heg__junwei_m_heg__lordsunquan1"] = "坐断东南地，威名四海扬！",
  ["$m_heg__junwei_m_heg__lordsunquan2"] = "天降祥瑞，以昭四海安澜！",
  ["!m_heg__lordsunquan"] = "三江在握，孤岂独为守成之主？",
  ["~m_heg__lordsunquan"] = "坐观大江东去，空待英雄老……",
}

local lordyuanshao = General:new(extension, "m_heg__lordyuanshao", "qun", 4)
lordyuanshao.heg_lord = "hs__yuanshao"
lordyuanshao.hidden = true
lordyuanshao:addSkills{ "m_heg__huimeng", "m_heg__shoufeng", "m_heg__junwei" }
lordyuanshao:addCompanions{ "qun_generals" }
lordyuanshao:addCompanionRule(function(self, other)
  return other:hasKingdom("qun")
end)
Fk:loadTranslationTable{
  ["m_heg__lordyuanshao"] = "君袁绍",
  --["#m_heg__lordyuanshao"] = "",
  --["illustrator:m_heg__lordyuanshao"] = "",

  ["$m_heg__junwei_m_heg__lordyuanshao1"] = "吾名已满天下，今即试锋之时！",
  ["$m_heg__junwei_m_heg__lordyuanshao2"] = "天下风云之士，何不聚此讨贼？！",
  ["!m_heg__lordyuanshao"] = "汝剑利，吾剑亦未尝不利也！",
  ["~m_heg__lordyuanshao"] = "官渡虽败，我亦不会……输……",
}

local lordcaopi = General:new(extension, "m_heg__lordcaopi", "wei", 4)
lordcaopi.heg_lord = "hs__caopi"
lordcaopi.hidden = true
lordcaopi:addSkills{ "m_heg__poweic", "m_heg__pinzheng", "m_heg__junwei" }
lordcaopi:addCompanions{ "wei_generals" }
lordcaopi:addCompanionRule(function(self, other)
  return other:hasKingdom("wei")
end)
Fk:loadTranslationTable{
  ["m_heg__lordcaopi"] = "君曹丕",
  --["#m_heg__lordcaopi"] = "",
  --["illustrator:m_heg__lordcaopi"] = "",

  ["$m_heg__junwei_m_heg__lordcaopi1"] = "大魏新朝既起，天下当颂朕威！",
  ["$m_heg__junwei_m_heg__lordcaopi2"] = "朕为天下之尊，四海自当缄口。",
  ["!m_heg__lordcaopi"] = "天命加之在魏，朕为大魏始皇！",
  ["~m_heg__lordcaopi"] = "生已尽时，死当尽哀。",
}

local lordliushan = General:new(extension, "m_heg__lordliushan", "shu", 4)
lordliushan.heg_lord = "hs__liushan"
lordliushan.hidden = true
lordliushan:addSkills{ "m_heg__huihong", "m_heg__xingshi", "m_heg__junwei" }
lordliushan:addCompanions{ "shu_generals" }
lordliushan:addCompanionRule(function(self, other)
  return other:hasKingdom("shu")
end)
Fk:loadTranslationTable{
  ["m_heg__lordliushan"] = "君刘禅",
  --["#m_heg__lordliushan"] = "",
  --["illustrator:m_heg__lordliushan"] = "",

  ["$m_heg__junwei_m_heg__lordliushan1"] = "即刻出兵，兴复汉室！",
  ["$m_heg__junwei_m_heg__lordliushan2"] = "亲贤臣，远小人，此先汉所以兴隆也。",
  ["!m_heg__lordliushan"] = "汉道持恒不改，朕亦为中兴之主。",
  ["~m_heg__lordliushan"] = "大争之世，不容仁主啊！",
}

local lordsunce = General:new(extension, "m_heg__lordsunce", "wu", 4)
lordsunce.heg_lord = "ld__sunce"
lordsunce.hidden = true
lordsunce:addSkills{ "m_heg__saokou", "m_heg__bawei", "m_heg__junwei" }
lordsunce:addCompanions{ "wu_generals" }
lordsunce:addCompanionRule(function(self, other)
  return other:hasKingdom("wu")
end)
Fk:loadTranslationTable{
  ["m_heg__lordsunce"] = "君孙策",
  --["#m_heg__lordsunce"] = "",
  --["illustrator:m_heg__lordsunce"] = "",

  ["$m_heg__junwei_m_heg__lordsunce1"] = "江东儿郎，且随我闯出一片天地！",
  ["$m_heg__junwei_m_heg__lordsunce2"] = "威震三江，我武为极！",
  ["!m_heg__lordsunce"] = "一统何须经略，以武亦能定国！",
  ["~m_heg__lordsunce"] = "天下英雄从无对手，奈何今日死于小人……",
}

local lorddongzhuo = General:new(extension, "m_heg__lorddongzhuo", "qun", 4)
lorddongzhuo.heg_lord = "ld__dongzhuo"
lorddongzhuo.hidden = true
lorddongzhuo:addSkills{ "m_heg__baowei", "m_heg__siling", "m_heg__junwei" }
lorddongzhuo:addCompanions{ "qun_generals" }
lorddongzhuo:addCompanionRule(function(self, other)
  return other:hasKingdom("qun")
end)
Fk:loadTranslationTable{
  ["m_heg__lorddongzhuo"] = "君董卓",
  --["#m_heg__lorddongzhuo"] = "",
  --["illustrator:m_heg__lorddongzhuo"] = "",

  ["$m_heg__junwei_m_heg__lorddongzhuo1"] = "进京讨贼？老夫必大有可为，哈哈哈哈！",
  ["$m_heg__junwei_m_heg__lorddongzhuo2"] = "非霸王不能配此刀，非老夫不能镇天下！",
  ["!m_heg__lorddongzhuo"] = "天下尽在老夫之手，远胜尔等诸侯腐儒！",
  ["~m_heg__lorddongzhuo"] = "尔等畏我，尔等恨我，尔等同我！",
}

return extension
