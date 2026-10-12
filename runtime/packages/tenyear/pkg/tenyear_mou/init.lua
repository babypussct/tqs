local extension = Package:new("tenyear_mou")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_mou/skills")

Fk:loadTranslationTable{
  ["tenyear_mou"] = "十周年-谋",
  ["tymou"] = "新服谋",
  ["tymou2"] = "新服谋",
}

--谋定天下：
General:new(extension, "tymou__zhouyu", "wu", 4):addSkills { "ronghuo", "yingmou" }
local zhouyu2 = General:new(extension, "tymou2__zhouyu", "wu", 4)
zhouyu2:addSkills { "ronghuo", "yingmou" }
zhouyu2.hidden = true
Fk:loadTranslationTable{
  ["tymou__zhouyu"] = "谋周瑜",
  ["#tymou__zhouyu"] = "炽谋英隽",
  ["illustrator:tymou__zhouyu"] = "鬼画府",

  ["~tymou__zhouyu"] = "人生之艰难，犹如不息之长河……",

  ["tymou2__zhouyu"] = "谋周瑜",
  ["#tymou2__zhouyu"] = "炽谋英隽",
  ["illustrator:tymou2__zhouyu"] = "鬼画府",

  ["$ronghuo_tymou2__zhouyu1"] = "江东多锦绣，离火起曹贼毕，九州同忾。",
  ["$ronghuo_tymou2__zhouyu2"] = "星火乘风，风助火势，其必成燎原之姿。",
  ["$yingmou_tymou2__zhouyu1"] = "既遇知己之明主，当福祸共之，荣辱共之。",
  ["$yingmou_tymou2__zhouyu2"] = "将者，贵在知敌虚实，而后避实而击虚。",
  ["~tymou2__zhouyu"] = "大业未成，奈何身赴黄泉……",
}

General:new(extension, "tymou__lusu", "wu", 3):addSkills { "mingshil", "mengmou" }
local lusu2 = General:new(extension, "tymou2__lusu", "wu", 3)
lusu2:addSkills { "mingshil", "mengmou" }
lusu2.hidden = true
Fk:loadTranslationTable{
  ["tymou__lusu"] = "谋鲁肃",
  ["#tymou__lusu"] = "鸿谋翼远",
  ["illustrator:tymou__lusu"] = "鬼画府",

  ["~tymou__lusu"] = "虎可为之用，亦可为之伤……",

  ["tymou2__lusu"] = "谋鲁肃",
  ["#tymou2__lusu"] = "鸿谋翼远",
  ["illustrator:tymou2__lusu"] = "鬼画府",

  ["$mingshil_tymou2__lusu1"] = "今天下春秋已定，君不见南北沟壑乎？",
  ["$mingshil_tymou2__lusu2"] = "善谋者借势而为，其化万物为己用。",
  ["$mengmou_tymou2__lusu1"] = "合左抑右，定两家之盟。",
  ["$mengmou_tymou2__lusu2"] = "求同存异，邀英雄问鼎。",
  ["~tymou2__lusu"] = "青龙已巢，以何驱之……",
}

General:new(extension, "tymou__simayi", "wei", 3):addSkills { "pingliao", "quanmou" }
local simayi2 = General:new(extension, "tymou2__simayi", "wei", 3)
simayi2:addSkills { "pingliao", "quanmou" }
simayi2.hidden = true
Fk:loadTranslationTable{
  ["tymou__simayi"] = "谋司马懿",
  ["#tymou__simayi"] = "韬谋韫势",
  ["designer:tymou__simayi"] = "星移",
  ["illustrator:tymou__simayi"] = "米糊PU",

  ["~tymou__simayi"] = "以权谋而立者，必失大义于千秋……",

  ["tymou2__simayi"] = "谋司马懿",
  ["#tymou2__simayi"] = "韬谋韫势",
  ["illustrator:tymou2__simayi"] = "鬼画府",
  ["designer:tymou2__simayi"] = "星移",

  ["$pingliao_tymou2__simayi1"] = "率土之滨皆为王臣，辽土亦居普天之下。",
  ["$pingliao_tymou2__simayi2"] = "青云远上，寒锋试刃，北雁当寄红翎。",
  ["$quanmou_tymou2__simayi1"] = "鸿门之宴虽歇，会稽之胆尚悬，孤岂姬、项之辈？",
  ["$quanmou_tymou2__simayi2"] = "昔藏青锋于沧海，今潮落，可现兵！",
  ["~tymou2__simayi"] = "人立中流，非已力可向，实大势所迫……",
}

General:new(extension, "tymou__jiaxu", "qun", 3):addSkills { "sushen", "fumouj" }
local jiaxu2 = General:new(extension, "tymou2__jiaxu", "qun", 3)
jiaxu2:addSkills { "sushen", "fumouj" }
jiaxu2.hidden = true
Fk:loadTranslationTable{
  ["tymou__jiaxu"] = "谋贾诩",
  ["#tymou__jiaxu"] = "晦谋独善",
  ["designer:tymou__jiaxu"] = "星移",
  ["illustrator:tymou__jiaxu"] = "鬼画府",

  ["~tymou__jiaxu"] = "辛者抱薪，妄燃烽火以戏诸侯……",

  ["tymou2__jiaxu"] = "谋贾诩",
  ["#tymou2__jiaxu"] = "晦谋独善",
  ["illustrator:tymou2__jiaxu"] = "鬼画府",
  ["designer:tymou2__jiaxu"] = "星移",

  ["$sushen_tymou2__jiaxu1"] = "我有三窟之筹谋，不蹈背水之维谷。",
  ["$sushen_tymou2__jiaxu2"] = "已积千里跬步，欲履万里河山。",
  ["$rushi_tymou2__jiaxu1"] = "曾寄青鸟凌云志，归来城头看王旗。",
  ["$rushi_tymou2__jiaxu2"] = "烽火照长安，淯水洗枯骨，今日对弈何人？",
  ["$fumouj_tymou2__jiaxu1"] = "不周之柱已折，这世间，当起一阵风、落一场雨！",
  ["$fumouj_tymou2__jiaxu2"] = "善谋者，不与善战者争功。",
  ["~tymou2__jiaxu"] = "未见青山草木，枯骨徒付浊流……",
}

General:new(extension, "tymou__guojia", "wei", 3):addSkills { "xianmou", "tymou__lunshi" }
local guojia2 = General:new(extension, "tymou2__guojia", "wei", 3)
guojia2:addSkills { "xianmou", "tymou__lunshi" }
guojia2.hidden = true
Fk:loadTranslationTable{
  ["tymou__guojia"] = "谋郭嘉",
  ["#tymou__guojia"] = "翼谋奇佐",
  ["designer:tymou__guojia"] = "懵萌猛梦",
  ["illustrator:tymou__guojia"] = "鬼画府",

  ["$ex__yiji_tymou__guojia1"] = "算无遗策，方能决胜于千里。",
  ["$ex__yiji_tymou__guojia2"] = "吾身虽殒，然智计长存。",
  ["~tymou__guojia"] = "生如夏花，死亦何憾？",

  ["tymou2__guojia"] = "谋郭嘉",
  ["#tymou2__guojia"] = "翼谋奇佐",
  ["illustrator:tymou2__guojia"] = "鬼画府",
  ["designer:tymou2__guojia"] = "懵萌猛梦",

  ["$xianmou_tymou2__guojia1"] = "嘉不受此劫，安能以凡人之躯窥得天机！",
  ["$xianmou_tymou2__guojia2"] = "九州为觞，风雨为酿，谁与我共饮此杯？",
  ["$tymou__lunshi_tymou2__guojia1"] = "公有此十胜，败绍非难事尔。",
  ["$tymou__lunshi_tymou2__guojia2"] = "嘉窃料之，绍有十败，公有十胜。",
  ["$ex__yiji_tymou2__guojia1"] = "今生不借此身度，更向何生度此身？",
  ["$ex__yiji_tymou2__guojia2"] = "胸怀丹心一颗，欲照山河万朵。",
  ["~tymou2__guojia"] = "江湖路远，诸君，某先行一步。",
}

General:new(extension, "tymou__xunyu", "wei", 3):addSkills { "bizuo", "shimou" }
local xunyu2 = General:new(extension, "tymou2__xunyu", "wei", 3)
xunyu2:addSkills { "bizuo", "shimou" }
xunyu2.hidden = true
Fk:loadTranslationTable{
  ["tymou__xunyu"] = "谋荀彧",
  ["#tymou__xunyu"] = "贞谋弼汉",
  ["illustrator:tymou__xunyu"] = "鬼画府",

  ["~tymou__xunyu"] = "诸君见我冢，亦如见青山。",

  ["tymou2__xunyu"] = "谋荀彧",
  ["#tymou2__xunyu"] = "贞谋弼汉",
  ["illustrator:tymou2__xunyu"] = "鬼画府",

  ["$bizuo_tymou2__xunyu1"] = "而今江山未靖，劝君择日称公。",
  ["$bizuo_tymou2__xunyu2"] = "请君三尺剑，诛罢宵小，再复江山！",
  ["$shimou_tymou2__xunyu1"] = "明公揽青兖，征睢洛，胜券已然在握。",
  ["$shimou_tymou2__xunyu2"] = "为大汉抱薪者，不可使其冻毙于风雨。",
  ["~tymou2__xunyu"] = "知我罪我，其惟春秋。",
}

General:new(extension, "tymou__jiangwei", "shu", 3, 4):addSkills { "juemou", "fuzhan" }
local jiangwei2 = General:new(extension, "tymou2__jiangwei", "shu", 3, 4)
jiangwei2:addSkills { "juemou", "fuzhan" }
jiangwei2.hidden = true
Fk:loadTranslationTable{
  ["tymou__jiangwei"] = "谋姜维",
  ["#tymou__jiangwei"] = "锲谋昭汉",
  ["illustrator:tymou__jiangwei"] = "鬼画府",

  ["~tymou__jiangwei"] = "天地君师在上，维尽力了。",

  ["tymou2__jiangwei"] = "谋姜维",
  ["#tymou2__jiangwei"] = "锲谋昭汉",
  ["illustrator:tymou2__jiangwei"] = "鬼画府",

  ["$juemou_tymou2__jiangwei1"] = "晋道克昌，皆君之功，艾何窃之？",
  ["$juemou_tymou2__jiangwei2"] = "项王力覆诸秦，倒教那刘季先入了咸阳。",
  ["$fuzhan_tymou2__jiangwei1"] = "维才疏智短，拼得一死也要保住先帝基业！",
  ["$fuzhan_tymou2__jiangwei2"] = "愿陛下忍数日之辱，臣欲使社稷危而复安，日月幽而复明。",

  ["~tymou2__jiangwei"] = "蜀国之灭，非将军之罪，实是后主无道而致啊！",
}

General:new(extension, "tymou__luxun", "wu", 3):addSkills { "junmou", "zhanyan" }
local luxun2 = General:new(extension, "tymou2__luxun", "wu", 3)
luxun2:addSkills { "junmou", "zhanyan" }
luxun2.hidden = true
Fk:loadTranslationTable{
  ["tymou__luxun"] = "谋陆逊",
  ["#tymou__luxun"] = "渊谋谦略",
  ["illustrator:tymou__luxun"] = "白",

  ["~tymou__luxun"] = "夷陵火光，终究照不亮江东长夜。",

  ["tymou2__luxun"] = "谋陆逊",
  ["#tymou2__luxun"] = "渊谋谦略",
  ["illustrator:tymou2__luxun"] = "白",

  ["$junmou_tymou2__luxun1"] = "此棋方至中盘，勿用潜龙惊渊。",
  ["$junmou_tymou2__luxun2"] = "昔年越王卧薪，非惧甲戈，乃待天时。",
  ["$zhanyan_tymou2__luxun1"] = "江东陆伯言，问刘皇叔安！",
  ["$zhanyan_tymou2__luxun2"] = "汝非真金，当惧火炼！",

  ["~tymou2__luxun"] = "滔滔大江，不及人心之险。",
}

General:new(extension, "tymou__pangtong", "shu", 3):addSkills { "yinmoup", "hongce" }
local pangtong2 = General:new(extension, "tymou2__pangtong", "shu", 3)
pangtong2:addSkills { "yinmoup", "hongce" }
pangtong2.hidden = true
Fk:loadTranslationTable{
  ["tymou__pangtong"] = "谋庞统",
  ["#tymou__pangtong"] = "机谋辟业",
  ["illustrator:tymou__pangtong"] = "",

  ["~tymou__pangtong"] = "的卢的卢，今日妨我。",

  ["tymou2__pangtong"] = "谋庞统",
  ["#tymou2__pangtong"] = "机谋辟业",
  ["illustrator:tymou2__pangtong"] = "",

  ["$yinmoup_tymou2__pangtong1"] = "鹿食苹，虎食鹿，鸱居梧桐，何以食腐鼠？",
  ["$yinmoup_tymou2__pangtong2"] = "昔尧舜相让以成贤名，季玉效之，亦不失为富家翁。",
  ["$hongce_tymou2__pangtong1"] = "昔秦赵会于渑池，璋公麾下，有蔺姓卿乎？",
  ["$hongce_tymou2__pangtong2"] = "张鲁居卧榻之侧，无皇叔备患，谁可安睡？",
  ["$hongce_tymou2__pangtong3"] = "大人者，言不必信，行不必果。",
  ["$hongce_tymou2__pangtong4"] = "君子之于天下，非于一人一城。",
  ["$hongce_tymou2__pangtong5"] = "普天应元，嘉宾亦能夺主。",

  ["~tymou2__pangtong"] = "大好江山，岂庸人居之！",
}

General:new(extension, "tymou__zhugeliang", "shu", 4):addSkills { "jingmou", "guyi" }
local zhugeliang2 = General:new(extension, "tymou2__zhugeliang", "shu", 4)
zhugeliang2:addSkills { "jingmou", "guyi" }
zhugeliang2.hidden = true
Fk:loadTranslationTable{
  ["tymou__zhugeliang"] = "谋诸葛亮",
  ["#tymou__zhugeliang"] = "威谋定疆",
  -- ["illustrator:tymou__zhugeliang"] = "",

  ["~tymou__zhugeliang"] = "吾虽功于社稷，必损寿矣。",

  ["tymou2__zhugeliang"] = "谋诸葛亮",
  ["#tymou2__zhugeliang"] = "威谋定疆",
  -- ["illustrator:tymou2__zhugeliang"] = "",

  ["$jingmou_tymou2__zhugeliang1"] = "尔若再叛，王师所至，人与林俱焚。",
  ["$jingmou_tymou2__zhugeliang2"] = "江山在德不在险，民心在帛不在戈。",
  ["$guyi_tymou2__zhugeliang1"] = "二十八宿悬孤灯，独照我衣霜浓。",
  ["$guyi_tymou2__zhugeliang2"] = "欲举杯，无人共，满堂新将，谁与话隆中？",
  ["$dingnan_tymou2__zhugeliang1"] = "南中未定，何谈北复中原？",
  ["$dingnan_tymou2__zhugeliang2"] = "杀人易，服人难，平南易，定南艰。",

  ["~tymou2__zhugeliang"] = "天地不平，我心何甘？",
}

--冢虎狼顾：
General:new(extension, "tymou__jiangji", "wei", 3):addSkills { "shiju", "yingshij" }
Fk:loadTranslationTable{
  ["tymou__jiangji"] = "谋蒋济",
  ["#tymou__jiangji"] = "策论万机",
  ["illustrator:tymou__jiangji"] = "错落宇宙",
  ["designer:tymou__jiangji"] = "黑寡妇",

  ["~tymou__jiangji"] = "大醉解忧，然忧无解，唯忘耳……",
}

General:new(extension, "tymou__wangling", "wei", 4):addSkills { "jichouw", "ty__mouli" }
Fk:loadTranslationTable{
  ["tymou__wangling"] = "谋王凌",
  ["#tymou__wangling"] = "风节格尚",
  ["illustrator:tymou__wangling"] = "鬼画府",
  ["designer:tymou__wangling"] = "韩旭",

  ["~tymou__wangling"] = "曹魏之盛，再难复梦……",
}

General:new(extension, "tymou__simashi", "wei", 3):addSkills { "sanshi", "zhenrao", "chenlue" }
Fk:loadTranslationTable{
  ["tymou__simashi"] = "谋司马师",
  ["#tymou__simashi"] = "唯几成务",
  ["illustrator:tymou__simashi"] = "鬼画府",
  ["designer:tymou__simashi"] = "韩旭",

  ["~tymou__simashi"] = "东兴之败，此我过也，诸将何罪……",
}

General:new(extension, "tymou__caoshuang", "wei", 4):addSkills { "jianzhuan", "fanshi" }
Fk:loadTranslationTable{
  ["tymou__caoshuang"] = "谋曹爽",
  ["#tymou__caoshuang"] = "托孤傲臣",
  ["illustrator:tymou__caoshuang"] = "鬼画府",
  ["designer:tymou__caoshuang"] = "韩旭",

  ["~tymou__caoshuang"] = "我度太傅之意，不欲伤我兄弟耳……",
}

--子敬邀刀：
General:new(extension, "tymou__zhugejin", "wu", 3):addSkills { "taozhou", "houde" }
Fk:loadTranslationTable{
  ["tymou__zhugejin"] = "谋诸葛瑾",
  ["#tymou__zhugejin"] = "清雅德纯",
  ["illustrator:tymou__zhugejin"] = "君桓文化",
  ["designer:tymou__zhugejin"] = "银蛋",

  ["~tymou__zhugejin"] = "吾数梦，琅琊旧园……",
}

General:new(extension, "tymou__guanping", "shu", 4):addSkills { "wuwei" }
Fk:loadTranslationTable{
  ["tymou__guanping"] = "谋关平",
  ["#tymou__guanping"] = "百战烈烈",
  ["designer:tymou__guanping"] = "银蛋",
  ["cv:tymou__guanping"] = "清水浊流",
  ["illustrator:tymou__guanping"] = "黯荧岛",

  ["~tymou__guanping"] = "生未屈刀兵，死罢战黄泉……",
}

General:new(extension, "tymou__lvmeng", "wu", 4):addSkills { "hengye", "yingbo" }
Fk:loadTranslationTable{
  ["tymou__lvmeng"] = "谋吕蒙",
  ["#tymou__lvmeng"] = "诡识渐近",
  ["illustrator:tymou__lvmeng"] = "君桓文化",

  ["~tymou__lvmeng"] = "腹而不备，岂罪于我？",
}

General:new(extension, "tymou__guanyu", "shu", 4):addSkills { "guanwu", "weishi", "juao" }
Fk:loadTranslationTable{
  ["tymou__guanyu"] = "谋关羽",
  ["#tymou__guanyu"] = "单刀赴会",

  ["~tymou__guanyu"] = "这也不是江水，二十年流不尽的英雄血！",
}

--毒士鸩计：
General:new(extension, "tymou__caoang", "wei", 4):addSkills { "fengmin", "zhiwang" }
Fk:loadTranslationTable{
  ["tymou__caoang"] = "谋曹昂",
  ["#tymou__caoang"] = "两全忠孝",
  ["illustrator:tymou__caoang"] = "钟於",

  ["~tymou__caoang"] = "青草明年绿，王孙不再归。",
}

General:new(extension, "tymou__zhangxiu", "qun", 4):addSkills { "fuxi", "haoyi" }
Fk:loadTranslationTable{
  ["tymou__zhangxiu"] = "谋张绣",
  ["#tymou__zhangxiu"] = "凌枪破宛",
  ["illustrator:tymou__zhangxiu"] = "君桓文化",
  ["designer:tymou__zhangxiu"] = "银蛋",

  ["~tymou__zhangxiu"] = "曹贼……欺我太甚！",
}

General:new(extension, "tymou__dianwei", "wei", 4, 5):addSkills { "kuangzhan", "kangyong" }
Fk:loadTranslationTable{
  ["tymou__dianwei"] = "谋典韦",
  ["#tymou__dianwei"] = "狂战怒莽",
  ["illustrator:tymou__dianwei"] = "黯荧岛",
  ["designer:tymou__dianwei"] = "银蛋",

  ["~tymou__dianwei"] = "主公无恙，韦虽死犹生……",
}

General:new(extension, "tymou__hucheer", "qun", 4):addSkills { "kongwu" }
Fk:loadTranslationTable{
  ["tymou__hucheer"] = "谋胡车儿",
  ["#tymou__hucheer"] = "有力逮戟",
  ["illustrator:tymou__hucheer"] = "钟於",

  ["~tymou__hucheer"] = "典，典将军，您还没睡呀？",
}

--奇佐论胜：
General:new(extension, "tymou__jvshou", "qun", 3):addSkills { "zuojun", "muwang" }
Fk:loadTranslationTable{
  ["tymou__jvshou"] = "谋沮授",
  ["#tymou__jvshou"] = "忠不逢时",
  ["illustrator:tymou__jvshou"] = "鬼画府",
  ["designer:tymou__jvshou"] = "步穗",

  ["~tymou__jvshou"] = "身虽死，忠魂不灭。",
}

General:new(extension, "tymou__chenlin", "qun", 3):addSkills { "yaozuo", "zhuanwen" }
Fk:loadTranslationTable{
  ["tymou__chenlin"] = "谋陈琳",
  ["#tymou__chenlin"] = "文翻云海",
  ["illustrator:tymou__chenlin"] = "鬼画府",
  ["designer:tymou__chenlin"] = "银蛋",

  ["~tymou__chenlin"] = "矢在弦上，不得不发，请曹公恕罪。",
}

General:new(extension, "tymou__chunyuqiong", "qun", 5):addSkills { "lingshu", "wankang" }
Fk:loadTranslationTable{
  ["tymou__chunyuqiong"] = "谋淳于琼",
  ["#tymou__chunyuqiong"] = "殊死难当",

  ["~tymou__chunyuqiong"] = "胜负自天，何用为问乎！",
}

General:new(extension, "tymou__xuyou", "qun", 3):addSkills { "moyou", "shiao" }
Fk:loadTranslationTable{
  ["tymou__xuyou"] = "谋许攸",
  ["#tymou__xuyou"] = "智士濡足",

  ["~tymou__xuyou"] = "仲康！适才相戏耳！",
}

--王佐倡义：
General:new(extension, "tymou__dongcheng", "qun", 4):addSkills { "baojia", "douwei" }
Fk:loadTranslationTable{
  ["tymou__dongcheng"] = "谋董承",
  ["#tymou__dongcheng"] = "汉室孤忠",
  ["illustrator:tymou__dongcheng"] = "鬼画府",

  ["~tymou__dongcheng"] = "东都破败，非龙栖之所。",
}

General:new(extension, "tymou__caohong", "wei", 4):addSkills { "ty__yingjia", "xianju" }
Fk:loadTranslationTable{
  ["tymou__caohong"] = "谋曹洪",
  ["#tymou__caohong"] = "奉令西迎",
  ["illustrator:tymou__caohong"] = "鹿田",

  ["~tymou__caohong"] = "董承，这仇便结下了！",
}

General:new(extension, "tymou__liuxie", "qun", 3):addSkills { "zhanban", "chensheng", "tiancheng" }
Fk:loadTranslationTable{
  ["tymou__liuxie"] = "谋刘协",
  ["#tymou__liuxie"] = "玉辂东归",
  ["illustrator:tymou__liuxie"] = "黯荧岛",
  ["designer:tymou__liuxie"] = "韩旭",

  ["~tymou__liuxie"] = "前有董贼、李贼，今有曹贼！",
}

General:new(extension, "tymou__yangfeng", "qun", 4):addSkills { "zhubo", "xieshi", "qijue" }
Fk:loadTranslationTable{
  ["tymou__yangfeng"] = "谋杨奉",
  ["#tymou__yangfeng"] = "猰貐",
  --["illustrator:tymou__yangfeng"] = "",

  ["~tymou__yangfeng"] = "",
}

--武侯定南：
General:new(extension, "tymou__wangping", "shu", 5):addSkills { "youyiw", "ty__fangong" }
Fk:loadTranslationTable{
  ["tymou__wangping"] = "谋王平",
  ["#tymou__wangping"] = "佯败溯战",

  ["~tymou__wangping"] = "南疆多瘴气，未战身先休。",
}

General:new(extension, "tymou__masu", "shu", 4):addSkills { "chengce", "ty__xinzhan" }
Fk:loadTranslationTable{
  ["tymou__masu"] = "谋马谡",
  ["#tymou__masu"] = "服心屈兵",

  ["~tymou__masu"] = "",
}

--凤雏溯攻：
General:new(extension, "tymou__fazheng", "shu", 3):addSkills { "zhenjian", "xixing" }
Fk:loadTranslationTable{
  ["tymou__fazheng"] = "谋法正",
  ["#tymou__fazheng"] = "洞人识心",

  ["~tymou__fazheng"] = "璋公有恩，我却无义。",
}

General:new(extension, "tymou__wuyi", "shu", 4):addSkills { "shibianw", "bibu" }
Fk:loadTranslationTable{
  ["tymou__wuyi"] = "谋吴懿",
  ["#tymou__wuyi"] = "恤下媲子",

  ["~tymou__wuyi"] = "功与过，留后人说。",
}

General:new(extension, "tymou__zhangren", "qun", 5):addSkills { "shedao", "xunshiz", "zhengong" }
Fk:loadTranslationTable{
  ["tymou__zhangren"] = "谋张任",
  ["#tymou__zhangren"] = "尖峰致溃",
  -- ["illustrator:tymou__zhangren"] = "",

  ["~tymou__zhangren"] = "忠臣不侍二主，可速杀我！",
}

General:new(extension, "tymou__liuzhang", "qun", 3):addSkills { "ty__jutu", "renshan", "yizhil" }
Fk:loadTranslationTable{
  ["tymou__liuzhang"] = "谋刘璋",
  ["#tymou__liuzhang"] = "半圭黯暗",
  -- ["illustrator:tymou__liuzhang"] = "",

  ["~tymou__liuzhang"] = "沃土养懦骨，一夕照胆寒。",
}

--幼麟绝战：
General:new(extension, "tymou__dengai", "wei", 4):addSkills { "ty__zhouxi", "shijin" }
Fk:loadTranslationTable{
  ["tymou__dengai"] = "谋邓艾",
  ["#tymou__dengai"] = "奇锋厄川",
  ["illustrator:tymou__dengai"] = "黯荧岛",

  ["~tymou__dengai"] = "此处，名三造亭。",
}

General:new(extension, "tymou__huliew", "wei", 4):addSkills { "chuanyu", "yitou" }
Fk:loadTranslationTable{
  ["tymou__huliew"] = "谋胡烈",
  ["#tymou__huliew"] = "暗舆平叛",
  ["illustrator:tymou__huliew"] = "鬼画府",

  ["~tymou__huliew"] = "不曾想，竟死在蛮夷刀下！",
}

General:new(extension, "tymou__zhonghui", "wei", 4):addSkills { "jinglian", "ty__xieshu", "zongzi" }
Fk:loadTranslationTable{
  ["tymou__zhonghui"] = "谋钟会",
  ["#tymou__zhonghui"] = "策诡凌云",
  --["illustrator:tymou__zhonghui"] = "",

  ["~tymou__zhonghui"] = "",
}

--周郎将计：
General:new(extension, "tymou__chengyu", "wei", 3):addSkills { "shizha", "gaojian" }
Fk:loadTranslationTable{
  ["tymou__chengyu"] = "谋程昱",
  ["#tymou__chengyu"] = "沐风知秋",
  ["illustrator:tymou__chengyu"] = "匠人绘",

  ["~tymou__chengyu"] = "乌鹊南飞，何枝可依呀……",
}

General:new(extension, "tymou__huanggai", "wu", 4):addSkills { "lieji", "quzhou" }
Fk:loadTranslationTable{
  ["tymou__huanggai"] = "谋黄盖",
  ["#tymou__huanggai"] = "毁身纾难",
  ["illustrator:tymou__huanggai"] = "白",

  ["~tymou__huanggai"] = "被那曹贼看穿了。",
}

General:new(extension, "tymou__jianggan", "wei", 3):addSkills { "mingfang", "jibian" }
Fk:loadTranslationTable{
  ["tymou__jianggan"] = "谋蒋干",
  ["#tymou__jianggan"] = "反笺沉江",
  ["illustrator:tymou__jianggan"] = "君桓文化",

  ["~tymou__jianggan"] = "丞相！是周瑜诈了我呀！",
}

General:new(extension, "tymou__chengpu", "wu", 5):addSkills { "jianweic", "juzhanc" }
Fk:loadTranslationTable{
  ["tymou__chengpu"] = "谋程普",
  ["#tymou__chengpu"] = "平江定乱",
  --["illustrator:tymou__chengpu"] = "",

  ["~tymou__chengpu"] = "",
}

--伯言绽火：
General:new(extension, "tymou__luotong", "wu", 3):addSkills { "juce", "kangming" }
Fk:loadTranslationTable{
  ["tymou__luotong"] = "谋骆统",
  ["#tymou__luotong"] = "知寒始北",
  ["illustrator:tymou__luotong"] = "君桓文化",

  ["~tymou__luotong"] = "此身当为柱石，奈何徒膏野革。",
}

General:new(extension, "tymou__huangquan", "wei", 3):addSkills { "qiaodui", "ty__tuicheng" }
Fk:loadTranslationTable{
  ["tymou__huangquan"] = "谋黄权",
  ["#tymou__huangquan"] = "智答魏诏",
  ["illustrator:tymou__huangquan"] = "君桓文化",

  ["~tymou__huangquan"] = "大江阻断，归乡路。",
}

General:new(extension, "tymou__zhuran", "wu", 4):addSkills { "zhenyu", "jielu" }
Fk:loadTranslationTable{
  ["tymou__zhuran"] = "谋朱然",
  ["#tymou__zhuran"] = "孤城镇岳",
  ["illustrator:tymou__zhuran"] = "鬼画府",

  ["~tymou__zhuran"] = "不好！叫刘备那厮逃了！",
}

General:new(extension, "tymou__xusheng", "wu", 4):addSkills { "qinqiang", "yizhen" }
Fk:loadTranslationTable{
  ["tymou__xusheng"] = "谋徐盛",
  ["#tymou__xusheng"] = "穰苴之风",

  ["~tymou__xusheng"] = "我来问你，牙旗何在？",
}

return extension
