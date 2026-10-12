local extension = Package:new("overseas_heg")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/overseas_heg/skills")

Fk:loadTranslationTable{
  ["overseas_heg"] = "国战-国际服专属",
  ["os_heg"] = "国际国战",
}

local generals = {}  --绕过变量上限的东西

generals.os_heg__zhugejin = General:new(extension, "os_heg__zhugejin", "wu", 3)
generals.os_heg__zhugejin:addCompanions("hs__sunquan")
generals.os_heg__zhugejin:addSkills{ "huanshi", "hongyuan", "mingzhe" }
Fk:loadTranslationTable{
  ["os_heg__zhugejin"] = "诸葛瑾",
  ["#os_heg__zhugejin"] = "联盟的维系者",
  ["illustrator:os_heg__zhugejin"] = "G.G.G.",

  ["~os_heg__zhugejin"] = "君臣不相负，来世复君臣。",
}

General:new(extension, "os_heg__yangxiu", "wei", 3):addSkills{ "danlao", "jilei" }
Fk:loadTranslationTable{
  ["os_heg__yangxiu"] = "杨修",
  ["#os_heg__yangxiu"] = "恃才放旷",
  ["designer:os_heg__yangxiu"] = "KayaK",
  ["illustrator:os_heg__yangxiu"] = "张可",

  ["~os_heg__yangxiu"] = "我固自以死之晚也……",
}

generals.os_heg__chendao = General:new(extension, "os_heg__chendao", "shu", 4)
generals.os_heg__chendao:addCompanions("hs__zhaoyun")
generals.os_heg__chendao:addSkill("wangliec")
Fk:loadTranslationTable{
  ["os_heg__chendao"] = "陈到",
  ["#os_heg__chendao"] = "白毦督",
  ["designer:os_heg__chendao"] = "荼蘼",
  ["illustrator:os_heg__chendao"] = "王立雄",
  ["~os_heg__chendao"] = "我的白毦兵，再也不能为先帝出力了。",
}

General:new(extension, "os_heg__zumao", "wu", 4):addSkills{ "yinbing", "juedi" }
Fk:loadTranslationTable{
  ["os_heg__zumao"] = "祖茂",
  ["#os_heg__zumao"] = "碧血染赤帻",
  ["designer:os_heg__zumao"] = "红莲的焰神",
  ["illustrator:os_heg__zumao"] = "DH",

  ["~os_heg__zumao"] = "孙将军，已经，安全了吧……",
}

General:new(extension, "os_heg__fuwan", "qun", 4):addSkills{ "os__moukui" }
Fk:loadTranslationTable{
  ["os_heg__fuwan"] = "伏完",
  ["#os_heg__fuwan"] = "沉毅的国丈",
  ["illustrator:os_heg__fuwan"] = "LiuHeng",

  ["~os_heg__fuwan"] = "后会有期……",
}

generals.os_heg__liaohua = General:new(extension, "os_heg__liaohua", "shu", 4)
generals.os_heg__liaohua:addCompanions("hs__guanyu")
generals.os_heg__liaohua:addSkills { "dangxian", "os_heg__fuli" }
Fk:loadTranslationTable{
  ["os_heg__liaohua"] = "廖化",
  ["#os_heg__liaohua"] = "历尽沧桑",
  ["illustrator:os_heg__liaohua"] = "天空之城",

  ["~os_heg__liaohua"] = "今后，就靠你们啦……",
}

General:new(extension, "os_heg__tianyu", "wei", 4):addSkills { "os__zhenxi", "os__yangshi" }
Fk:loadTranslationTable{
  ["os_heg__tianyu"] = "田豫",
  ["#os_heg__tianyu"] = "规略明练",
  ["illustrator:os_heg__tianyu"] = "鬼画府",
  ["designer:os_heg__tianyu"] = "梦魇狂朝",

  ["~os_heg__tianyu"] = "钟鸣漏尽，夜行不休……",
}

General:new(extension, "os_heg__liufuren", "qun", 3, 3, General.Female):addSkills { "os__zhuidu", "os__shigong" }
Fk:loadTranslationTable{
  ["os_heg__liufuren"] = "刘夫人",
  ["#os_heg__liufuren"] = "酷妒的海棠",
  ["illustrator:os_heg__liufuren"] = "Jzeo",
  ["designer:os_heg__liufuren"] = "梦魇狂朝",

  ["~os_heg__liufuren"] = "害人终害己，最毒妇人心……",
}

General:new(extension, "os_heg__huaxiong", "qun", 4):addSkills{ "nos__yaowu" }
Fk:loadTranslationTable{
  ["os_heg__huaxiong"] = "华雄",
  ["#os_heg__huaxiong"] = "飞扬跋扈",
  ["illustrator:os_heg__huaxiong"] = "地狱许",

  ["~os_heg__huaxiong"] = "皮厚不挡刀啊……",
}

generals.os_heg__xiahoushang = General:new(extension, "os_heg__xiahoushang", "wei", 4)
generals.os_heg__xiahoushang:addCompanions("hs__caopi")
generals.os_heg__xiahoushang:addSkill("os__tanfeng")
Fk:loadTranslationTable{
  ["os_heg__xiahoushang"] = "夏侯尚",
  ["#os_heg__xiahoushang"] = "魏胤前驱",
  ["designer:os_heg__xiahoushang"] = "豌豆&Loun老萌",
  ["illustrator:os_heg__xiahoushang"] = "M云涯",

  ["~os_heg__xiahoushang"] = "陛下垂怜至此，臣纵死无憾……",
}

General:new(extension, "os_heg__guohuai", "wei", 4):addSkills { "os_ex__jingce", "os_ex__yuzhang" }
Fk:loadTranslationTable{
  ["os_heg__guohuai"] = "郭淮",
  ["#os_heg__guohuai"] = "垂问秦雍",
  ["illustrator:os_heg__guohuai"] = "凝聚永恒",

  ["~os_heg__guohuai"] = "姜维小儿，竟然……",
}

General:new(extension, "os_heg__chengjiw", "wei", 4):addSkills { "kuangli", "xiongsi" }
Fk:loadTranslationTable{
  ["os_heg__chengjiw"] = "成济",
  ["#os_heg__chengjiw"] = "劣犬良弓",
  ["illustrator:os_heg__chengjiw"] = "凝聚永恒",

  ["~os_heg__chengjiw"] = "汝等要卸磨杀驴吗？呃啊……",
}

General:new(extension, "os_heg__chengyu", "wei", 3):addSkills { "shefu", "benyu" }
Fk:loadTranslationTable{
  ["os_heg__chengyu"] = "程昱",
  ["#os_heg__chengyu"] = "泰山捧日",
  ["illustrator:os_heg__chengyu"] = "GH",

  ["~os_heg__chengyu"] = "此诚报效国家之时，吾却休矣！",
}

General:new(extension, "os_heg__maojie", "wei", 3):addSkills { "bingqing" }
Fk:loadTranslationTable{
  ["os_heg__maojie"] = "毛玠",
  ["#os_heg__maojie"] = "清公素履",
  ["cv:os_heg__maojie"] = "刘强",
  ["illustrator:os_heg__maojie"] = "君桓文化",

  ["~os_heg__maojie"] = "废立大事，公不可不慎……",
}

General:new(extension, "os_heg__zhongyao", "wei", 3):addSkills { "huomo", "zuoding" }
Fk:loadTranslationTable{
  ["os_heg__zhongyao"] = "钟繇",
  ["#os_heg__zhongyao"] = "正楷萧曹",
  ["designer:os_heg__zhongyao"] = "怀默",
  ["illustrator:os_heg__zhongyao"] = "eshao111",

  ["~os_heg__zhongyao"] = "墨尽，岁终。",
}

General:new(extension, "os_heg__caizhenji", "wei", 3, 3, General.Female):addSkills { "sheyi", "tianyin" }
Fk:loadTranslationTable{
  ["os_heg__caizhenji"] = "蔡贞姬",
  ["#os_heg__caizhenji"] = "舍心顾复",
  ["illustrator:os_heg__caizhenji"] = "M云涯",

  ["~os_heg__caizhenji"] = "世誉吾为贤妻，吾愧终不为良母……",
}

General:new(extension, "os_heg__zhangchangpu", "wei", 3, 3, General.Female):addSkills { "difei", "mobile__yanjiao" }
Fk:loadTranslationTable{
  ["os_heg__zhangchangpu"] = "张昌蒲",
  ["#os_heg__zhangchangpu"] = "厉色严教",
  ["illustrator:os_heg__zhangchangpu"] = "君桓文化",

  ["~os_heg__zhangchangpu"] = "钟氏门楣，待我儿光耀……",
}

General:new(extension, "os_heg__zhangchunhua", "wei", 3, 3, General.Female):addSkills { "jueqing", "shangshi" }
Fk:loadTranslationTable{
  ["os_heg__zhangchunhua"] = "张春华",
  ["#os_heg__zhangchunhua"] = "冷血皇后",
  ["designer:os_heg__zhangchunhua"] = "JZHIEI",
  ["illustrator:os_heg__zhangchunhua"] = "樱花闪乱",

  ["~os_heg__zhangchunhua"] = "怎能如此对我！",
}

General:new(extension, "os_heg__yanghuiyu", "wei", 3, 3, General.Female):addSkills { "hongyi", "quanfeng" }
Fk:loadTranslationTable{
  ["os_heg__yanghuiyu"] = "羊徽瑜",
  ["#os_heg__yanghuiyu"] = "温慧母仪",
  ["designer:os_heg__yanghuiyu"] = "Loun老萌",
  ["illustrator:os_heg__yanghuiyu"] = "石蝉",

  ["~os_heg__yanghuiyu"] = "桃符，一定要平安啊……",
}

generals.os_heg__wangling = General:new(extension, "os_heg__wangling", "wei", 4)
generals.os_heg__wangling:addSkills { "os__mibei", "os__xingqi" }
Fk:loadTranslationTable{
  ["os_heg__wangling"] = "王凌",
  ["#os_heg__wangling"] = "风节格尚",
  ["illustrator:os_heg__wangling"] = "游漫美绘",

  ["~os_heg__wangling"] = "一生尽忠事魏，不料，今日晚节尽毁啊！",
}

General:new(extension, "os_heg__caorui", "wei", 3):addSkills { "huituo", "mingjian" }
Fk:loadTranslationTable{
  ["os_heg__caorui"] = "曹叡",
  ["#os_heg__caorui"] = "天姿的明君",
  ["designer:os_heg__caorui"] = "Ptolemy_M7",
  ["illustrator:os_heg__caorui"] = "Thinking",

  ["~os_heg__caorui"] = "悔不该耽于逸乐，至有今日……",
}

General:new(extension, "os_heg__yanrou", "wei", 4):addSkills { "choutao", "xiangshu" }
Fk:loadTranslationTable{
  ["os_heg__yanrou"] = "阎柔",
  ["#os_heg__yanrou"] = "冠玉啸北",
  ["illustrator:os_heg__yanrou"] = "凝聚永恒",

  ["~os_heg__yanrou"] = "寒风折戍矛，铁衣裹枯骨……",
}

General:new(extension, "os_heg__simashi", "wei", 4):addSkills { "os__baiyi", "os__jinglue" }
Fk:loadTranslationTable{
  ["os_heg__simashi"] = "司马师",
  ["#os_heg__simashi"] = "摧坚荡异",
  ["illustrator:os_heg__simashi"] = "M云涯",

  ["~os_heg__simashi"] = "吾家夙愿，得偿与否，尽看子上……",
}

General(extension, "os_heg__guanqiujian", "wei", 4):addSkills { "os__zhengrong", "os__hongju" }
Fk:loadTranslationTable{
  ["os_heg__guanqiujian"] = "毌丘俭",
  ["#os_heg__guanqiujian"] = "镌功铭征荣",
  ["illustrator:os_heg__guanqiujian"] = "猎枭",

  ["~os_heg__guanqiujian"] = "好谋而不达，此事必有隐患。",
}

General:new(extension, "os_heg__lizhaojiaobo", "wei", 4):addSkills { "zuoyou", "shishoul" }
Fk:loadTranslationTable{
  ["os_heg__lizhaojiaobo"] = "李昭焦伯",
  ["#os_heg__lizhaojiaobo"] = "竭诚尽节",
  ["illustrator:os_heg__lizhaojiaobo"] = "凝聚永恒",

  ["~os_heg__lizhaojiaobo"] = "陛下！！尔等乱臣，安敢弑君！呃啊……",
}

General:new(extension, "os_heg__shie", "wei", 4):addSkills { "os__dengjian", "os__xinshou" }
Fk:loadTranslationTable{
  ["os_heg__shie"] = "史阿",
  ["#os_heg__shie"] = "剑术登峰",
  ["illustrator:os_heg__shie"] = "凝聚永恒",

  ["~os_heg__shie"] = "江湖路远，吾等终会有再见之时。",
}

General:new(extension, "os_heg__wuban", "shu", 4):addSkill("os__jintao")
Fk:loadTranslationTable{
  ["os_heg__wuban"] = "吴班",
  ["#os_heg__wuban"] = "碧血的英豪",
  ["illustrator:os_heg__wuban"] = "铁杵文化",

  ["~os_heg__wuban"] = "恨，杀不尽吴狗！",
}

General:new(extension, "os_heg__zhaotongzhaoguang", "shu", 4):addSkills { "yizan", "longyuan" }
Fk:loadTranslationTable{
  ["os_heg__zhaotongzhaoguang"] = "赵统赵广",
  ["#os_heg__zhaotongzhaoguang"] = "翊赞季兴",
  ["designer:os_heg__zhaotongzhaoguang"] = "Loun老萌",
  ["illustrator:os_heg__zhaotongzhaoguang"] = "蛋费鸡丁",

  ["~os_heg__zhaotongzhaoguang"] = "守业死战，不愧初心。",
}

General:new(extension, "os_heg__mayunlu", "shu", 4, 4, General.Female):addSkills { "os_heg_mayunlu__mashu", "os__fengpo" }
Fk:loadTranslationTable{
  ["os_heg__mayunlu"] = "马云騄",
  ["cv:os_heg__mayunlu"] = "水原",
  ["illustrator:os_heg__mayunlu"] = "木美人",

  ["~os_heg__mayunlu"] = "呜呜……是你们欺负人……",
}

General:new(extension, "os_heg__huojun", "shu", 4):addSkills { "os__sidai", "os__jieyu" }
Fk:loadTranslationTable{
  ["os_heg__huojun"] = "霍峻",
  ["#os_heg__huojun"] = "葭萌铁狮",
  ["illustrator:os_heg__huojun"] = "枭瞳",
  ["designer:os_heg__huojun"] = "步穗",

  ["~os_heg__huojun"] = "恨，不能与使君共成霸业……",
}

General:new(extension, "os_heg__feiyi", "shu", 3):addSkills { "os__shengxi", "os__kuanji" }
Fk:loadTranslationTable{
  ["os_heg__feiyi"] = "费祎",
  ["#os_heg__feiyi"] = "蜀汉名相",
  ["designer:os_heg__feiyi"] = "Loun老萌",
  ["illustrator:os_heg__feiyi"] = "凝聚永恒",

  ["~os_heg__feiyi"] = "臣请告陛下，宦权日盛，必乱社稷也。",
}

General(extension, "os_heg__xingcai", "shu", 3, 3, General.Female):addSkills { "shenxian", "qiangwu" }
Fk:loadTranslationTable{
  ["os_heg__xingcai"] = "张星彩",
  ["#os_heg__xingcai"] = "敬哀皇后",
  ["designer:os_heg__xingcai"] = "韩旭",
  ["illustrator:os_heg__xingcai"] = "depp",
  ["cv:os_heg__xingcai"] = "shourei小N",

  ["~os_heg__xingcai"] = "复兴汉室之路，臣妾再也不能陪伴左右了……",
}

General:new(extension, "os_heg__liwei", "shu", 4):addSkill("os__jiaohua")
Fk:loadTranslationTable{
  ["os_heg__liwei"] = "李遗",
  ["#os_heg__liwei"] = "伏被俞元",
  ["illustrator:os_heg__liwei"] = "付玉",

  ["~os_heg__liwei"] = "安南重任，万不可轻之……",
}

General:new(extension, "os_heg__qinmi", "shu", 3):addSkills { "jianzhengq", "zhuandui", "tianbian" }
Fk:loadTranslationTable{
  ["os_heg__qinmi"] = "秦宓",
  ["#os_heg__qinmi"] = "彻天之舌",
  ["cv:os_heg__qinmi"] = "曹真",
  ["designer:os_heg__qinmi"] = "凌天翼",
  ["illustrator:os_heg__qinmi"] = "Thinking",

  ["~os_heg__qinmi"] = "我竟然，也百口莫辩了……",
}

General:new(extension, "os_heg__fuqian", "shu", 4):addSkills { "poxiang", "jueyong" }
Fk:loadTranslationTable{
  ["os_heg__fuqian"] = "傅佥",
  ["#os_heg__fuqian"] = "危汉绝勇",
  ["illustrator:os_heg__fuqian"] = "君桓文化",
  ["cv:os_heg__fuqian"] = "杨超然",

  ["~os_heg__fuqian"] = "生为蜀臣，死……亦当为蜀！",
}

General:new(extension, "os_heg__dongyun", "shu", 3):addSkills { "bingzheng", "sheyan" }
Fk:loadTranslationTable{
  ["os_heg__dongyun"] = "董允",
  ["#os_heg__dongyun"] = "骨鲠良相",
  ["designer:os_heg__dongyun"] = "如释帆飞",
  ["illustrator:os_heg__dongyun"] = "玖等仁品",

  ["~os_heg__dongyun"] = "大汉，要亡于宦官之手了……",
}

General:new(extension, "os_heg__huangquan", "shu", 4):addSkills { "quanjian", "os__tujue" }
Fk:loadTranslationTable{
  ["os_heg__huangquan"] = "黄权",
  ["#os_heg__huangquan"] = "忠事三朝",
  ["designer:os_heg__huangquan"] = "头发好借好还",
  ["illustrator:os_heg__huangquan"] = "匠人绘",

  ["~os_heg__huangquan"] = "败军之将，何言忠乎？",
}

General:new(extension, "os_heg__furong", "shu", 4):addSkills { "os__xuewei", "os__liechi" }
Fk:loadTranslationTable{
  ["os_heg__furong"] = "傅肜",
  ["#os_heg__furong"] = "危汉义烈",
  ["illustrator:os_heg__furong"] = "三道纹",

  ["~os_heg__furong"] = "吾主既然得返，此番已是功成……",
}

General:new(extension, "os_heg__zhugezhan", "shu", 3):addSkills { "zuilun", "fuyin" }
Fk:loadTranslationTable{
  ["os_heg__zhugezhan"] = "诸葛瞻",
  ["#os_heg__zhugezhan"] = "临难死义",
  ["cv:os_heg__zhugezhan"] = "漠桀",
  ["illustrator:os_heg__zhugezhan"] = "zoo",

  ["~os_heg__zhugezhan"] = "临难而死义，无愧先父。",
}

General:new(extension, "os_heg__zhangyiy", "shu", 4):addSkills { "zhiyi" }
Fk:loadTranslationTable{
  ["os_heg__zhangyiy"] = "张翼",
  ["#os_heg__zhangyiy"] = "亢锐怀忠",
  ["illustrator:os_heg__zhangyiy"] = "王强",

  ["~os_heg__zhangyiy"] = "唯愿百姓，不受此乱所害，哎……",
}

General:new(extension, "os_heg__fengxi", "shu", 4):addSkill("os__qingkou")
Fk:loadTranslationTable{
  ["os_heg__fengxi"] = "冯习",
  ["#os_heg__fengxi"] = "赤胆的忠魂",
  ["illustrator:os_heg__fengxi"] = "陈鑫",

  ["~os_heg__fengxi"] = "陛下，速退白帝……",
}

General:new(extension, "os_heg__sunluban", "wu", 3, 3, General.Female):addSkills { "zenhui", "jiaojin" }
Fk:loadTranslationTable{
  ["os_heg__sunluban"] = "孙鲁班",
  ["#os_heg__sunluban"] = "为虎作伥",
  ["illustrator:os_heg__sunluban"] = "FOOLTOWN",

  ["~os_heg__sunluban"] = "本公主，何罪之有？",
}

General:new(extension, "os_heg__sundeng", "wu", 4):addSkills { "kuangbi" }
Fk:loadTranslationTable{
  ["os_heg__sundeng"] = "孙登",
  ["#os_heg__sundeng"] = "才高德茂",
  ["designer:os_heg__sundeng"] = "过客",
  ["illustrator:os_heg__sundeng"] = "DH",

  ["~os_heg__sundeng"] = "愿陛下留意听采，儿臣虽死犹生。",
}

General:new(extension, "os_heg__quancong", "wu", 4):addSkills { "m_ex__yaoming" }
Fk:loadTranslationTable{
  ["os_heg__quancong"] = "全琮",
  ["#os_heg__quancong"] = "慕势耀族",
  ["illustrator:os_heg__quancong"] = "YanBai",

  ["~os_heg__quancong"] = "吾逐名如筑室道谋，而是用终不溃于成。",
}

General:new(extension, "os_heg__guyong", "wu", 3):addSkills { "os_ex__shenxing", "os_ex__bingyi" }
Fk:loadTranslationTable{
  ["os_heg__guyong"] = "顾雍",
  ["#os_heg__guyong"] = "庙堂的玉磬",
  ["illustrator:os_heg__guyong"] = "三道纹",

  ["~os_heg__guyong"] = "陛下厚爱，雍……",
}

General:new(extension, "os_heg__cenhun", "wu", 3):addSkills { "jishe", "lianhuo" }
Fk:loadTranslationTable{
  ["os_heg__cenhun"] = "岑昏",
  ["#os_heg__cenhun"] = "伐梁倾瓴",
  ["designer:os_heg__cenhun"] = "韩旭",
  ["illustrator:os_heg__cenhun"] = "心中一凛",

  ["~os_heg__cenhun"] = "我为主上出过力！呃啊！",
}

General:new(extension, "os_heg__sunyi", "wu", 4):addSkills { "os__zaoli" }
Fk:loadTranslationTable{
  ["os_heg__sunyi"] = "孙翊",
  ["#os_heg__sunyi"] = "骁悍激躁",
  ["illustrator:os_heg__sunyi"] = "凡果",

  ["~os_heg__sunyi"] = "叛我贼子，虽死亦不饶之……",
}

General:new(extension, "os_heg__zhugeke", "wu", 3):addSkills { "aocai", "duwu" }
Fk:loadTranslationTable{
  ["os_heg__zhugeke"] = "诸葛恪",
  ["#os_heg__zhugeke"] = "兴家赤族",
  ["designer:os_heg__zhugeke"] = "韩旭",
  ["illustrator:os_heg__zhugeke"] = "LiuHeng",

  ["~os_heg__zhugeke"] = "重权震主，是我疏忽了……",
}

General:new(extension, "os_heg__wuguotai", "wu", 3, 3, General.Female):addSkills { "m_ex__ganlu", "buyi" }
Fk:loadTranslationTable{
  ["os_heg__wuguotai"] = "吴国太",
  ["#os_heg__wuguotai"] = "慈怀瑾瑜",
  ["illustrator:os_heg__wuguotai"] = "李秀森",

  ["~os_heg__wuguotai"] = "诸位卿家，还请尽力辅佐仲谋啊……",
}

General:new(extension, "os_heg__bulianshi", "wu", 3, 3, General.Female):addSkills { "m_ex__anxu", "zhuiyi" }
Fk:loadTranslationTable{
  ["os_heg__bulianshi"] = "步练师",
  ["#os_heg__bulianshi"] = "无冕之后",
  ["illustrator:os_heg__bulianshi"] = "凡果",

  ["~os_heg__bulianshi"] = "今生先君逝，来世再侍君……",
}

General:new(extension, "os_heg__wujing", "wu", 4):addSkills { "os__fenghan", "os__congji" }
Fk:loadTranslationTable{
  ["os_heg__wujing"] = "吴景",
  ["#os_heg__wujing"] = "坚攻勉策",
  ["cv:os_heg__wujing"] = "虞晓旭",
  ["illustrator:os_heg__wujing"] = "匠人绘",

  ["~os_heg__wujing"] = "贼寇未除，奈何吾身先丧……",
}

General:new(extension, "os_heg__lvdai", "wu", 4):addSkills { "qinguo" }
Fk:loadTranslationTable{
  ["os_heg__lvdai"] = "吕岱",
  ["#os_heg__lvdai"] = "清身奉公",
  ["illustrator:os_heg__lvdai"] = "biou09",
  ["designer:os_heg__lvdai"] = "笔枔",

  ["~os_heg__lvdai"] = "再也不能，为吴国奉身了。",
}

General:new(extension, "os_heg__zhuran", "wu", 4):addSkills { "m_ex__danshou" }
Fk:loadTranslationTable{
  ["os_heg__zhuran"] = "朱然",
  ["#os_heg__zhuran"] = "不动之督",
  ["illustrator:os_heg__zhuran"] = "zoo",

  ["~os_heg__zhuran"] = "大耳贼就在眼前，快追……",
}

General:new(extension, "os_heg__zhouchu", "wu", 4):addSkills { "os__guoyi", "os__chuhai" }
Fk:loadTranslationTable{
  ["os_heg__zhouchu"] = "周处",
  ["#os_heg__zhouchu"] = "英情天逸",
  ["illustrator:os_heg__zhouchu"] = "枭瞳",
  ["designer:os_heg__zhouchu"] = "梦魇狂朝",

  ["~os_heg__zhouchu"] = "改励自砥，誓除三害……",
}

General:new(extension, "os_heg__yanjun", "wu", 3):addSkills { "guanchao", "xunxian" }
Fk:loadTranslationTable{
  ["os_heg__yanjun"] = "严畯",
  ["#os_heg__yanjun"] = "志存补益",
  ["illustrator:os_heg__yanjun"] = "YanBai",
  ["cv:os_heg__yanjun"] = "小思无邪强",

  ["~os_heg__yanjun"] = "著作，还……没完成……",
}

General:new(extension, "os_heg__zhuhuan", "wu", 4):addSkills { "fenli", "m_ex__pingkou" }
Fk:loadTranslationTable{
  ["os_heg__zhuhuan"] = "朱桓",
  ["#os_heg__zhuhuan"] = "中洲拒天人",
  ["illustrator:os_heg__zhuhuan"] = "聚一工作室",

  ["~os_heg__zhuhuan"] = "为将不行前而为人下，非可生受之辱……",
}

General:new(extension, "os_heg__lingcao", "wu", 4):addSkills { "dujin" }
Fk:loadTranslationTable{
  ["os_heg__lingcao"] = "凌操",
  ["#os_heg__lingcao"] = "激流勇进",
  ["illustrator:os_heg__lingcao"] = "樱花闪乱",

  ["~os_heg__lingcao"] = "呃啊！（扑通）此箭……何来……",
}

General:new(extension, "os_heg__liuzan", "wu", 4):addSkills { "fenyin" }
Fk:loadTranslationTable{
  ["os_heg__liuzan"] = "留赞",
  ["#os_heg__liuzan"] = "啸天亢声",
  ["cv:os_heg__liuzan"] = "腾格尔",
  ["designer:os_heg__liuzan"] = "东郊易尘Noah",
  ["illustrator:os_heg__liuzan"] = "酸包",

  ["~os_heg__liuzan"] = "贼子们，来吧！啊…………",
}

General:new(extension, "os_heg__dingyuan", "qun", 4):addSkills { "beizhu" }
Fk:loadTranslationTable{
  ["os_heg__dingyuan"] = "丁原",
  ["#os_heg__dingyuan"] = "饲虎成患",
  ["illustrator:os_heg__dingyuan"] = "M云涯",

  ["~os_heg__dingyuan"] = "奉先何故心变，啊！",
}

General(extension, "os_heg__liuxie", "qun", 3):addSkills { "tianming", "mizhao" }
Fk:loadTranslationTable{
  ["os_heg__liuxie"] = "刘协",
  ["#os_heg__liuxie"] = "受困天子",
  ["designer:os_heg__liuxie"] = "韩旭",
  ["illustrator:os_heg__liuxie"] = "LiuHeng",

  ["~os_heg__liuxie"] = "为什么，不把复兴汉室的权力交给我……",
}

General:new(extension, "os_heg__zhanglu", "qun", 3):addSkills { "yishe", "bushi", "midao" }
Fk:loadTranslationTable{
  ["os_heg__zhanglu"] = "张鲁",
  ["#os_heg__zhanglu"] = "政宽教惠",
  ["designer:os_heg__zhanglu"] = "逍遥鱼叔",
  ["illustrator:os_heg__zhanglu"] = "銘zmy",

  ["~os_heg__zhanglu"] = "但，归置于道，无意凡事争斗。",
}

General:new(extension, "os_heg__liangxing", "qun", 4):addSkills { "lulue", "zhuixi" }
Fk:loadTranslationTable{
  ["os_heg__liangxing"] = "梁兴",
  ["#os_heg__liangxing"] = "凶豺掠豹",
  ["cv:os_heg__liangxing"] = "虞晓旭",
  ["illustrator:os_heg__liangxing"] = "匠人绘",

  ["~os_heg__liangxing"] = "夏侯渊，你竟敢！",
}

General:new(extension, "os_heg__jiachong", "qun", 3):addSkills { "os__beini", "os__dingfa" }
Fk:loadTranslationTable{
  ["os_heg__jiachong"] = "贾充",
  ["#os_heg__jiachong"] = "凶凶踽行",
  ["illustrator:os_heg__jiachong"] = "铁杵文化",
  ["cv:os_heg__jiachong"] = "虞晓旭",

  ["~os_heg__jiachong"] = "此生从势忠命，此刻，只乞不获恶谥……",
}

General:new(extension, "os_heg__wangyue", "qun", 4):addSkills { "os__yulong", "os__jianming" }
Fk:loadTranslationTable{
  ["os_heg__wangyue"] = "王越",
  ["#os_heg__wangyue"] = "驭龙在天",
  ["illustrator:os_heg__wangyue"] = "鱼仔",

  ["~os_heg__wangyue"] = "汉室中兴，不系于吾一人……",
}

General:new(extension, "os_heg__xiahouzieh", "qun", 4, 4, General.Female):addSkill("os__chengxi")
Fk:loadTranslationTable{
  ["os_heg__xiahouzieh"] = "夏侯子萼",
  ["#os_heg__xiahouzieh"] = "承继婆娑",
  ["illustrator:os_heg__xiahouzieh"] = "错落宇宙",

  ["~os_heg__xiahouzieh"] = "蔷薇凋零，永沉血海……",
}

General:new(extension, "os_heg__zhangxiu", "qun", 4):addSkills { "xiongluan", "congjian" }
Fk:loadTranslationTable{
  ["os_heg__zhangxiu"] = "张绣",
  ["#os_heg__zhangxiu"] = "北地枪王",
  ["cv:os_heg__zhangxiu"] = "Aaron", -- 秦宇
  ["illustrator:os_heg__zhangxiu"] = "PCC",

  ["~os_heg__zhangxiu"] = "若失文和……吾将何归……",
}

General:new(extension, "os_heg__liuqi", "qun", 3):addSkills { "wenji", "ld__tunjiang" }
Fk:loadTranslationTable{
  ["os_heg__liuqi"] = "刘琦",
  ["#os_heg__liuqi"] = "居外而安",
  ["cv:os_heg__liuqi"] = "戴超行",
  ["illustrator:os_heg__liuqi"] = "NOVART",

  ["~os_heg__liuqi"] = "父亲，孩儿来见你了。",
}

General:new(extension, "os_heg__gaolan", "qun", 4):addSkills { "jungong", "dengli" }
Fk:loadTranslationTable{
  ["os_heg__gaolan"] = "高览",
  ["#os_heg__gaolan"] = "绝击坚营",
  ["cv:os_heg__gaolan"] = "曹真",
  ["illustrator:os_heg__gaolan"] = "兴游",

  ["~os_heg__gaolan"] = "满腹忠肝，难抵一句谮言……唉！",
}

General:new(extension, "os_heg__gongsunfan", "qun", 4):addSkills { "os__huiyuan", "os__shoushou" }
Fk:loadTranslationTable{
  ["os_heg__gongsunfan"] = "公孙范",
  ["#os_heg__gongsunfan"] = "助瓒讨袁",
  ["illustrator:os_heg__gongsunfan"] = "鱼仔",

  ["~os_heg__gongsunfan"] = "公孙氏之业，终付之一炬……",
}

General:new(extension, "os_heg__duanwei", "qun", 4):addSkills { "ty__langmie" }
Fk:loadTranslationTable{
  ["os_heg__duanwei"] = "段煨",
  ["#os_heg__duanwei"] = "凉国之英",
  ["illustrator:os_heg__duanwei"] = "匠人绘",

  ["~os_heg__duanwei"] = "狼伴其侧，终不胜防。",
}

generals.os_heg__yangfeng = General:new(extension, "os_heg__yangfeng", "qun", 4)
generals.os_heg__yangfeng:addSkills { "xuetu", "weiming" }
Fk:loadTranslationTable{
  ["os_heg__yangfeng"] = "杨奉",
  ["#os_heg__yangfeng"] = "忠勇半途",
  ["illustrator:os_heg__yangfeng"] = "铁杵文化",

  ["~os_heg__yangfeng"] = "刘备！本共图吕布，何设鸿门相欺！",
}

General:new(extension, "os_heg__xushu", "qun", 4):addSkills { "os__jiange", "os__xiawang" }
Fk:loadTranslationTable{
  ["os_heg__xushu"] = "侠徐庶",
  ["#os_heg__xushu"] = "仗剑为侠",
  ["illustrator:os_heg__xushu"] = "zoo",

  ["~os_heg__xushu"] = "天下为公……",
}

General(extension, "os_heg__liubei", "shu", 4):addSkills { "os__shenyi", "os__xinghan" }
Fk:loadTranslationTable{
  ["os_heg__liubei"] = "侠刘备",
  ["#os_heg__liubei"] = "为国为民",
  ["illustrator:os_heg__liubei"] = "特特肉",

  ["~os_heg__liubei"] = "楼桑羽葆，终是一梦……",
}

generals.os_heg__zhaoyun = General:new(extension, "os_heg__zhaoyun", "shu", 4)
generals.os_heg__zhaoyun:addSkills { "os__jiezhan", "os__longjin" }
Fk:loadTranslationTable{
  ["os_heg__zhaoyun"] = "幻赵云",
  ["#os_heg__zhaoyun"] = "天武耆龙",
  ["illustrator:os_heg__zhaoyun"] = "铁杵",

  ["$longdan_os_heg__zhaoyun1"] = "进退有度，百战无伤！",
  ["$longdan_os_heg__zhaoyun2"] = "龙魂缠身，虎威犹在！",
  ["$chongzhen_os_heg__zhaoyun1"] = "众将士，且随老夫再战一场！",
  ["$chongzhen_os_heg__zhaoyun2"] = "出入千军万马，经年横战八方！",
  ["~os_heg__zhaoyun"] = "转战一生，终得见兴汉之日。",
}

General:new(extension, "os_heg__zhangsong", "shu", 3):addSkills { "qiangzhi", "xiantu" }
Fk:loadTranslationTable{
  ["os_heg__zhangsong"] = "张松",
  ["#os_heg__zhangsong"] = "怀璧待凤仪",
  ["designer:os_heg__zhangsong"] = "冷王无双",
  ["illustrator:os_heg__zhangsong"] = "尼乐小丑",

  ["~os_heg__zhangsong"] = "皇叔不听吾谏言，悔时晚矣！",
}

General:new(extension, "os_heg__guanping", "shu", 4):addSkills { "longyin" }
Fk:loadTranslationTable{
  ["os_heg__guanping"] = "关平",
  ["#os_heg__guanping"] = "忠臣孝子",
  ["designer:os_heg__guanping"] = "昂翼天使",
  ["illustrator:os_heg__guanping"] = "樱花闪乱",

  ["~os_heg__guanping"] = "父亲快走，孩儿断后……",
}

return extension
