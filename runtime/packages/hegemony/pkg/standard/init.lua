local extension = Package:new("hegemony_standard")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/standard/skills")

Fk:loadTranslationTable{
  ["hegemony_standard"] = "国战标准版",
  ["hs"] = "国战",
}

local caocao = General:new(extension, "hs__caocao", "wei", 4)
caocao:addSkill("hs__jianxiong")
caocao:addCompanions{ "hs__dianwei", "hs__xuchu" }
Fk:loadTranslationTable{
  ["hs__caocao"] = "曹操",
  ["#hs__caocao"] = "魏武帝",
  ["illustrator:hs__caocao"] = "青骑士",
  ["~hs__caocao"] = "霸业未成，未成啊……",
}

General:new(extension, "hs__simayi", "wei", 3):addSkills{ "fankui", "ex__guicai" }
Fk:loadTranslationTable{
  ["hs__simayi"] = "司马懿",
  ["#hs__simayi"] = "狼顾之鬼",
  ["illustrator:hs__simayi"] = "KayaK",
  ["~hs__simayi"] = "我的气数……就到这里了吗？",
}

local xiahoudun = General:new(extension, "hs__xiahoudun", "wei", 4)
xiahoudun:addSkill("hs__ganglie")
xiahoudun:addCompanions("hs__xiahouyuan")
Fk:loadTranslationTable{
  ["hs__xiahoudun"] = "夏侯惇",
  ["#hs__xiahoudun"] = "独眼的罗刹",
  ["illustrator:hs__xiahoudun"] = "KayaK",
  ["~hs__xiahoudun"] = "诸多败绩，有负丞相重托……",
}

General:new(extension, "hs__zhangliao", "wei", 4):addSkill("ex__tuxi")
Fk:loadTranslationTable{
  ["hs__zhangliao"] = "张辽",
  ["#zhangliao"] = "前将军",
  ["illustrator:zhangliao"] = "KayaK",
  ["~hs__zhangliao"] = "被敌人占了先机……呃……",
}

General:new(extension, "hs__xuchu", "wei", 4):addSkill("hs__luoyi")
Fk:loadTranslationTable{
  ["hs__xuchu"] = "许褚",
  ["#xuchu"] = "虎痴",
  ["illustrator:xuchu"] = "KayaK",
  ["~hs__xuchu"] = "冷，好冷啊……",
}

General:new(extension, "hs__guojia", "wei", 3):addSkills{"hs__yiji", "tiandu"}
Fk:loadTranslationTable{
  ["hs__guojia"] = "郭嘉",
  ["#hs__guojia"] = "早终的先知",
  ["illustrator:hs__guojia"] = "绘聚艺堂",
  ["~hs__guojia"] = "咳，咳……",
}

local zhenji = General:new(extension, "hs__zhenji", "wei", 3, 3, General.Female)
zhenji:addSkills{ "hs__luoshen", "qingguo" }
zhenji:addCompanions("hs__caopi")
Fk:loadTranslationTable{
  ["hs__zhenji"] = "甄姬",
  ["#hs__zhenji"] = "薄幸的美人",
  ["illustrator:hs__zhenji"] = "DH",
  ["~hs__zhenji"] = "悼良会之永绝兮，哀一逝而异乡。",
}

General:new(extension, "hs__xiahouyuan", "wei", 5):addSkill("hs__shensu")
Fk:loadTranslationTable{
  ["hs__xiahouyuan"] = "夏侯渊",
  ["#hs__xiahouyuan"] = "虎步关右",
  ["illustrator:hs__xiahouyuan"] = "凡果",
  ["~hs__xiahouyuan"] = "竟然比我还…快……",
}

local zhanghe = General:new(extension, "hs__zhanghe", "wei", 4)
zhanghe:addSkill("qiaobian")
Fk:loadTranslationTable{
  ["hs__zhanghe"] = "张郃",
  ["#hs__zhanghe"] = "料敌机先",
  ["illustrator:hs__zhanghe"] = "张帅",
  ["~hs__zhanghe"] = "呃，膝盖中箭了……",
}

General:new(extension, "hs__xuhuang", "wei", 4):addSkill("hs__duanliang")
Fk:loadTranslationTable{
  ["hs__xuhuang"] = "徐晃",
  ["#hs__xuhuang"] = "周亚夫之风",
  ["illustrator:hs__xuhuang"] = "Tuu.",
  ["~hs__xuhuang"] = "一顿不吃饿得慌。",
}

General:new(extension, "hs__caoren", "wei", 4):addSkill("hs__jushou")
Fk:loadTranslationTable{
  ["hs__caoren"] = "曹仁",
  ["#hs__caoren"] = "大将军",
  ["illustrator:hs__caoren"] = "Ccat",
  ["~hs__caoren"] = "实在是守不住了……",
}

General:new(extension, "hs__dianwei", "wei", 4):addSkill("hs__qiangxi")
Fk:loadTranslationTable{
  ["hs__dianwei"] = "典韦",
  ["#hs__dianwei"] = "古之恶来",
  ["illustrator:hs__dianwei"] = "凡果",
  ["~hs__dianwei"] = "主公，快走！",
}

General:new(extension, "hs__xunyu", "wei", 3):addSkills{"quhu", "hs__jieming"}
Fk:loadTranslationTable{
  ["hs__xunyu"] = "荀彧",
  ["#hs__xunyu"] = "王佐之才",
  ["illustrator:hs__xunyu"] = "LiuHeng",
  ["~hs__xunyu"] = "主公要臣死，臣不得不死。",
}

General:new(extension, "hs__caopi", "wei", 3):addSkills{"xingshang", "hs__fangzhu"}
Fk:loadTranslationTable{
  ["hs__caopi"] = "曹丕",
  ["#hs__caopi"] = "霸业的继承者",
  ["illustrator:hs__caopi"] = "DH",
  ["~hs__caopi"] = "子建，子建……",
}

General:new(extension, "hs__yuejin", "wei", 4):addSkill("hs__xiaoguo")
Fk:loadTranslationTable{
  ["hs__yuejin"] = "乐进",
  ["yuejin"] = "乐进",
  ["#hs__yuejin"] = "奋强突固",
  ["illustrator:hs__yuejin"] = "巴萨小马",
  ["desinger:hs__yuejin"] = "淬毒",
  ["~hs__yuejin"] = "箭疮发作，吾命休矣。",
}

local liubei = General:new(extension, "hs__liubei", "shu", 4)
liubei:addSkill("ex__rende")
liubei:addCompanions({ "hs__guanyu", "hs__zhangfei", "hs__ganfuren" })
Fk:loadTranslationTable{
  ["hs__liubei"] = "刘备",
  ["#hs__liubei"] = "乱世的枭雄",
  ["illustrator:hs__liubei"] = "木美人",
  ["~hs__liubei"] = "汉室未兴，祖宗未耀，朕实不忍此时西去……",
}

local guanyu = General:new(extension, "hs__guanyu", "shu", 5)
guanyu:addSkill("hs__wusheng")
guanyu:addCompanions("hs__zhangfei")
Fk:loadTranslationTable{
  ["hs__guanyu"] = "关羽",
  ["#hs__guanyu"] = "威震华夏",
  ["illustrator:hs__guanyu"] = "凡果",
  ["~hs__guanyu"] = "什么？此地名叫麦城？",
}

General:new(extension, "hs__zhangfei", "shu", 4):addSkill("hs__paoxiao")
Fk:loadTranslationTable{
  ["hs__zhangfei"] = "张飞",
  ["#hs__zhangfei"] = "万夫不当",
  ["illustrator:hs__zhangfei"] = "KayaK",
  ["~hs__zhangfei"] = "实在是杀不动了……",
}

local zhugeliang = General:new(extension, "hs__zhugeliang", "shu", 3)
zhugeliang:addSkills{ "hs__guanxing", "hs__kongcheng" }
zhugeliang:addCompanions("hs__huangyueying")
Fk:loadTranslationTable{
  ["hs__zhugeliang"] = "诸葛亮",
  ["#hs__zhugeliang"] = "迟暮的丞相",
  ["illustrator:hs__zhugeliang"] = "木美人",
  ["~hs__zhugeliang"] = "将星陨落，天命难违。",
}

local zhaoyun = General:new(extension, "hs__zhaoyun", "shu", 4)
zhaoyun:addSkill("hs__longdan")
zhaoyun:addCompanions("hs__liushan")
Fk:loadTranslationTable{
  ["hs__zhaoyun"] = "赵云",
  ["#hs__zhaoyun"] = "虎威将军",
  ["illustrator:hs__zhaoyun"] = "DH",
  ["~hs__zhaoyun"] = "这，就是失败的滋味吗？",
}

General:new(extension, "hs__machao", "shu", 4):addSkills{ "hs_machao__mashu", "hs__tieqi" }
Fk:loadTranslationTable{
  ["hs__machao"] = "马超",
  ["#hs__machao"] = "一骑当千",
  ["illustrator:hs__machao"] = "KayaK&木美人&张帅",
  ["~hs__machao"] = "请将我，葬在西凉……",
}

local huangyueying = General:new(extension, "hs__huangyueying", "shu", 3, 3, General.Female)
huangyueying:addSkills{ "hs__jizhi", "qicai" }
huangyueying:addCompanions("hs__wolong")
Fk:loadTranslationTable{
  ["hs__huangyueying"] = "黄月英",
  ["#hs__huangyueying"] = "归隐的杰女",
  ["illustrator:hs__huangyueying"] = "木美人",
  ["~hs__huangyueying"] = "亮……",
}

local huangzhong = General:new(extension, "hs__huangzhong", "shu", 4)
huangzhong:addSkill("hs__liegong")
huangzhong:addCompanions("hs__weiyan")
Fk:loadTranslationTable{
  ["hs__huangzhong"] = "黄忠",
  ["#hs__huangzhong"] = "老当益壮",
  ["illustrator:hs__huangzhong"] = "凡果",
  ["~hs__huangzhong"] = "不得不服老了……",
}

General:new(extension, "hs__weiyan", "shu", 4):addSkill("hs__kuanggu")
Fk:loadTranslationTable{
  ["hs__weiyan"] = "魏延",
  ["#hs__weiyan"] = "嗜血的独狼",
  ["illustrator:hs__weiyan"] = "SoniaTang",
  ["~hs__weiyan"] = "谁敢杀我！呃啊！",
}

local pangtong = General:new(extension, "hs__pangtong", "shu",3)
pangtong:addSkills{ "lianhuan", "niepan" }
pangtong:addCompanions("hs__wolong")
Fk:loadTranslationTable{
  ["hs__pangtong"] = "庞统",
  ["#hs__pangtong"] = "凤雏",
  ["illustrator:hs__pangtong"] = "KayaK",
}

General:new(extension, "hs__wolong", "shu", 3):addSkills{ "bazhen", "huoji", "kanpo" }
Fk:loadTranslationTable{
  ["hs__wolong"] = "卧龙诸葛亮",
  ["#hs__wolong"] = "卧龙",
  ["illustrator:hs__wolong"] = "绘聚艺堂",
  ["~hs__wolong"] = "我的计谋竟被……",
}

General:new(extension, "hs__liushan", "shu", 3):addSkills{ "xiangle", "fangquan" }
Fk:loadTranslationTable{
  ["hs__liushan"] = "刘禅",
  ["#hs__liushan"] = "无为的真命主",
  ["illustrator:hs__liushan"] = "LiuHeng",
  ["~hs__liushan"] = "别打脸，我投降还不行吗？",
}

local menghuo = General:new(extension, "hs__menghuo", "shu", 4)
menghuo:addCompanions("hs__zhurong")
menghuo:addSkills{ "huoshou", "hs__zaiqi" }
Fk:loadTranslationTable{
  ["hs__menghuo"] = "孟获",
  ["#hs__menghuo"] = "南蛮王",
  ["illustrator:hs__menghuo"] = "废柴男",

  ["~hs__menghuo"] = "七纵之恩……来世……再报了……",
}

General:new(extension, "hs__zhurong", "shu", 4, 4, General.Female):addSkills{ "juxiang", "lieren" }
Fk:loadTranslationTable{
  ["hs__zhurong"] = "祝融",
  ["#hs__zhurong"] = "野性的女王",
  ["illustrator:hs__zhurong"] = "废柴男",
  ["~hs__zhurong"] = "大王，我，先走一步了。",
}

General(extension, "hs__ganfuren", "shu", 3, 3, General.Female):addSkills{ "hs__shenzhi", "hs__shushen" }
Fk:loadTranslationTable{
  ["hs__ganfuren"] = "甘夫人",
  ["ganfuren"] = "甘夫人",
  ["#hs__ganfuren"] = "昭烈皇后",
  ["illustrator:hs__ganfuren"] = "琛·美弟奇",
  ["designer:hs__ganfuren"] = "淬毒",
  ["~hs__ganfuren"] = "请替我照顾好阿斗……",
}

local sunquan = General:new(extension, "hs__sunquan", "wu", 4)
sunquan:addSkill("hs__zhiheng")
sunquan:addCompanions("hs__zhoutai")
Fk:loadTranslationTable{
  ["hs__sunquan"] = "孙权",
  ["#hs__sunquan"] = "年轻的贤君",
  ["illustrator:hs__sunquan"] = "KayaK",
  ["~hs__sunquan"] = "父亲，大哥，仲谋愧矣……",
}

General:new(extension, "hs__ganning", "wu", 4):addSkills{"qixi", "fenwei"}
Fk:loadTranslationTable{
  ["hs__ganning"] = "甘宁",
  ["#hs__ganning"] = "锦帆游侠",
  ["illustrator:hs__ganning"] = "巴萨小马",
  ["~hs__ganning"] = "二十年后，又是一条好汉！",
}

General:new(extension, "hs__lvmeng", "wu", 4):addSkills{ "hs__keji", "hs__mouduan" }
Fk:loadTranslationTable{
  ["hs__lvmeng"] = "吕蒙",
  ["#hs__lvmeng"] = "白衣渡江",
  ["illustrator:hs__lvmeng"] = "樱花闪乱",
  ["~hs__lvmeng"] = "种下恶因，必有恶果。",
}

local huanggai = General:new(extension, "hs__huanggai", "wu", 4)
huanggai:addSkill("hs__kurou")
huanggai:addCompanions("hs__zhouyu")
Fk:loadTranslationTable{
  ["hs__huanggai"] = "黄盖",
  ["#hs__huanggai"] = "轻身为国",
  ["illustrator:hs__huanggai"] = "G.G.G.",
  ["~hs__huanggai"] = "盖，有负公瑾重托……",
}

local zhouyu = General:new(extension, "hs__zhouyu", "wu", 3)
zhouyu:addSkills{ "ex__yingzi", "ex__fanjian" }
zhouyu:addCompanions("hs__xiaoqiao")
Fk:loadTranslationTable{
  ["hs__zhouyu"] = "周瑜",
  ["#hs__zhouyu"] = "大都督",
  ["illustrator:hs__zhouyu"] = "绘聚艺堂",
  ["~hs__zhouyu"] = "既生瑜，何生亮。既生瑜，何生亮！",
}

local daqiao = General:new(extension, "hs__daqiao", "wu", 3, 3, General.Female)
daqiao:addSkills{ "guose", "liuli" }
daqiao:addCompanions("hs__xiaoqiao")
Fk:loadTranslationTable{
  ["hs__daqiao"] = "大乔",
  ["#hs__daqiao"] = "矜持之花",
  ["illustrator:hs__daqiao"] = "KayaK",
  ["~hs__daqiao"] = "伯符，我去了……",
}

General:new(extension, "hs__luxun", "wu", 3):addSkills{ "hs__qianxun", "duoshi" }
Fk:loadTranslationTable{
  ["hs__luxun"] = "陆逊",
  ["#hs__luxun"] = "擎天之柱",
  ["illustrator:hs__luxun"] = "KayaK",
  ["~hs__luxun"] = "还以为我已经不再年轻……",
}

General:new(extension, "hs__sunshangxiang", "wu", 3, 3, General.Female):addSkills{ "hs__xiaoji", "jieyin" }
Fk:loadTranslationTable{
  ["hs__sunshangxiang"] = "孙尚香",
  ["#hs__sunshangxiang"] = "弓腰姬",
  ["illustrator:hs__sunshangxiang"] = "凡果",
  ["~hs__sunshangxiang"] = "不！还不可以死！",
}

General:new(extension, "hs__sunjian", "wu", 5):addSkill("hs__yinghun")
Fk:loadTranslationTable{
  ["hs__sunjian"] = "孙坚",
  ["#hs__sunjian"] = "魂佑江东",
  ["illustrator:hs__sunjian"] = "凡果",
  ["~hs__sunjian"] = "有埋伏！呃……啊！！",
}

General:new(extension, "hs__xiaoqiao", "wu", 3, 3, General.Female):addSkills{"hs__tianxiang", "hs__hongyan"}
Fk:loadTranslationTable{
  ["hs__xiaoqiao"] = "小乔",
  ["#hs__xiaoqiao"] = "矫情之花",
  ["illustrator:hs__xiaoqiao"] = "绘聚艺堂",
  ["~hs__xiaoqiao"] = "公瑾…我先走一步……",
}

General:new(extension, "hs__taishici", "wu", 4):addSkill("tianyi")
Fk:loadTranslationTable{
  ["hs__taishici"] = "太史慈",
  ["#hs__taishici"] = "笃烈之士",
  ["illustrator:hs__taishici"] = "Tuu.",
  ["~hs__taishici"] = "大丈夫，当带三尺之剑，立不世之功！",
}

General:new(extension, "hs__zhoutai", "wu", 4):addSkills{"hs__buqu", "hs__fenji"}
Fk:loadTranslationTable{
  ["hs__zhoutai"] = "周泰",
  ["#hs__zhoutai"] = "历战之躯",
  ["illustrator:hs__zhoutai"] = "Thinking",
  ["~hs__zhoutai"] = "敌众我寡，无力回天……",
}

General:new(extension, "hs__lusu", "wu", 3):addSkills{"haoshi", "dimeng"}
Fk:loadTranslationTable{
  ["hs__lusu"] = "鲁肃",
  ["#hs__lusu"] = "独断的外交家",
  ["illustrator:hs__lusu"] = "LiuHeng",
  ["~hs__lusu"] = "此联盟已破，吴蜀休矣。",
}

General:new(extension, "hs__zhangzhaozhanghong", "wu", 3):addSkills{"zhijian", "guzheng"}
Fk:loadTranslationTable{
  ["hs__zhangzhaozhanghong"] = "张昭张纮",
  ["#hs__zhangzhaozhanghong"] = "经天纬地",
  ["illustrator:hs__zhangzhaozhanghong"] = "废柴男",
  ["~hs__zhangzhaozhanghong"] = "竭力尽智，死而无憾。",
}

General:new(extension, "hs__dingfeng", "wu", 4):addSkills{ "duanbing", "fenxun" }
Fk:loadTranslationTable{
  ["hs__dingfeng"] = "丁奉",
  ["dingfeng"] = "丁奉",
  ["#hs__dingfeng"] = "清侧重臣",
  ["illustrator:hs__dingfeng"] = "魔鬼鱼",
  ["~hs__dingfeng"] = "这风，太冷了……",
}

General:new(extension, "hs__huatuo", "qun", 3):addSkills{ "jijiu", "hs__chuli" }
Fk:loadTranslationTable{
  ["hs__huatuo"] = "华佗",
  ["#hs__huatuo"] = "神医",
  ["illustrator:hs__huatuo"] = "琛·美弟奇",

  ["$jijiu_hs__huatuo1"] = "救死扶伤，悬壶济世。",
  ["$jijiu_hs__huatuo2"] = "妙手仁心，药到病除。",
  ["~hs__huatuo"] = "生老病死，命不可违。",
}

General:new(extension, "hs__lvbu", "qun", 5):addSkill("hs__wushuang")
Fk:loadTranslationTable{
  ["hs__lvbu"] = "吕布",
  ["#hs__lvbu"] = "戟指中原",
  ["illustrator:hs__lvbu"] = "凡果",
  ["~hs__lvbu"] = "不可能！",
}

local diaochan = General:new(extension, "hs__diaochan", "qun", 3, 3, General.Female)
diaochan:addSkills{"hs__lijian", "biyue"}
diaochan:addCompanions("hs__lvbu")
Fk:loadTranslationTable{
  ["hs__diaochan"] = "貂蝉",
  ["#hs__diaochan"] = "绝世的舞姬",
  ["illustrator:hs__diaochan"] = "LiuHeng",
  ["~hs__diaochan"] = "父亲大人，对不起……",
}

local yuanshao = General:new(extension, "hs__yuanshao", "qun", 4)
yuanshao:addSkill("hs__luanji")
yuanshao:addCompanions("hs__yanliangwenchou")
Fk:loadTranslationTable{
  ["hs__yuanshao"] = "袁绍",
  ["#hs__yuanshao"] = "高贵的名门",
  ["illustrator:hs__yuanshao"] = "北辰菌",
  ["~hs__yuanshao"] = "老天不助我袁家啊！",
}

General:new(extension, "hs__yanliangwenchou", "qun", 4):addSkills{ "hs__shuangxiong" }
Fk:loadTranslationTable{
  ["hs__yanliangwenchou"] = "颜良文丑",
  ["#hs__yanliangwenchou"] = "虎狼兄弟",
  ["illustrator:hs__yanliangwenchou"] = "KayaK",

  ["~hs__yanliangwenchou"] = "这红脸长须大将是……",
}

General:new(extension, "hs__jiaxu", "qun", 3):addSkills{ "wansha", "luanwu", "hs__weimu" }
Fk:loadTranslationTable{
  ["hs__jiaxu"] = "贾诩",
  ["#hs__jiaxu"] = "冷酷的毒士",
  ["illustrator:hs__jiaxu"] = "绘聚艺堂",
  ["~hs__jiaxu"] = "我的时辰也到了……",
}

General:new(extension, "hs__pangde", "qun", 4):addSkills{ "hs_pangde__mashu", "jianchu" }
Fk:loadTranslationTable{
  ["hs__pangde"] = "庞德",
  ["#hs__pangde"] = "人马一体",
  ["illustrator:hs__pangde"] = "凝聚永恒",
  ["~hs__pangde"] = "四面都是水……我命休矣。",
}

General:new(extension, "hs__zhangjiao", "qun", 3):addSkills{ "leiji", "guidao" }
Fk:loadTranslationTable{
  ["hs__zhangjiao"] = "张角",
  ["#hs__zhangjiao"] = "天公将军",
  ["illustrator:hs__zhangjiao"] = "LiuHeng",
  ["~hs__zhangjiao"] = "黄天…也死了……",
}

General:new(extension, "hs__caiwenji", "qun", 3, 3, General.Female):addSkills{ "beige", "hs__duanchang" }
Fk:loadTranslationTable{
  ["hs__caiwenji"] = "蔡文姬",
  ["#hs__caiwenji"] = "异乡的孤女",
  ["illustrator:hs__caiwenji"] = "SoniaTang",
  ["~hs__caiwenji"] = "人生几何时，怀忧终年岁。",
}

General:new(extension, "hs__mateng", "qun", 4):addSkills{ "hs_mateng__mashu", "xiongyi" }
Fk:loadTranslationTable{
  ["hs__mateng"] = "马腾",
  ["mateng"] = "马腾",
  ["#hs__mateng"] = "驰骋西陲",
  ["desinger:hs__mateng"] = "淬毒",
  ["illustrator:hs__mateng"] = "DH",
  ["~hs__mateng"] = "儿子，为爹报仇啊！",
}

General:new(extension, "hs__kongrong", "qun", 3):addSkills{ "mingshi", "lirang" }
Fk:loadTranslationTable{
  ["hs__kongrong"] = "孔融",
  ["kongrong"] = "孔融",
  ["#hs__kongrong"] = "凛然重义",
  ["desinger:hs__kongrong"] = "淬毒",
  ["illustrator:hs__kongrong"] = "苍月白龙",
  ["~hs__kongrong"] = "覆巢之下，岂有完卵……",
}

General:new(extension, "hs__jiling", "qun", 4):addSkill("shuangren")
Fk:loadTranslationTable{
  ["hs__jiling"] = "纪灵",
  ["jiling"] = "纪灵",
  ["#hs__jiling"] = "仲家的主将",
  ["illustrator:hs__jiling"] = "樱花闪乱",
  ["desinger:hs__jiling"] = "淬毒",
  ["~hs__jiling"] = "额，将军为何咆哮不断……",
}

General:new(extension, "hs__tianfeng", "qun", 3):addSkills{ "sijian", "suishi" }
Fk:loadTranslationTable{
  ["hs__tianfeng"] = "田丰",
  ["tianfeng"] = "田丰",
  ["#hs__tianfeng"] = "河北瑰杰",
  ["illustrator:hs__tianfeng"] = "地狱许",
  ["desinger:hs__tianfeng"] = "淬毒",
  ["~hs__tianfeng"] = "不纳吾言而反诛吾心，奈何奈何！！",
}

General:new(extension, "hs__panfeng", "qun", 4):addSkill("kuangfu")
Fk:loadTranslationTable{
  ["hs__panfeng"] = "潘凤",
  ["panfeng"] = "潘凤",
  ["#hs__panfeng"] = "联军上将",
  ["illustrator:hs__panfeng"] = "凡果",
  ["~hs__panfeng"] = "潘凤又被华雄斩了。",
}

General:new(extension, "hs__zoushi", "qun", 3, 3, General.Female):addSkills{ "huoshui", "qingcheng" }
Fk:loadTranslationTable{
  ["hs__zoushi"] = "邹氏",
  ["zoushi"] = "邹氏",
  ["#hs__zoushi"] = "惑心之魅",
  ["illustrator:hs__zoushi"] = "Tuu",
  ["~hs__zoushi"] = "年老色衰了吗？",
}

return extension
