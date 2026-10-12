local extension = Package:new("overseas_yizhu")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_yizhu/skills")

Fk:loadTranslationTable{
  ["overseas_yizhu"] = "国际服-沧海遗珠",
}

--贵
General:new(extension, "os__liuhong", "qun", 4):addSkills { "os__yujue", "os__gezhi", "os__fengqil" }
Fk:loadTranslationTable{
  ["os__liuhong"] = "刘宏",
  ["#os__liuhong"] = "汉灵帝",
  ["illustrator:os__liuhong"] = "biou09",

  ["~os__liuhong"] = "汉室中兴，还需尔等忠良。",
}

General:new(extension, "os__hejin", "qun", 4):addSkills { "os__mouzhu", "os__yanhuo" }
Fk:loadTranslationTable{
  ["os__hejin"] = "何进",
  ["#os__hejin"] = "色厉内荏",
  ["cv:os__hejin"] = "冷泉月夜",
  ["illustrator:os__hejin"] = "G.G.G.",

  ["~os__hejin"] = "不能遗祸世间……",
}

General:new(extension, "caozhao", "wei", 4):addSkills { "os__fuzuan", "os__chongqi" }
Fk:loadTranslationTable{
  ["caozhao"] = "曹肇",
  ["#caozhao"] = "宛童啖桃",
  ["illustrator:caozhao"] = "匠人绘",
  ["designer:caozhao"] = "世外高v狼",

  ["~caozhao"] = "虽极荣宠，亦有尽时。",
}

General:new(extension, "yuantan", "qun", 4):addSkills { "os__qiaosih", "os__baizu" }
Fk:loadTranslationTable{
  ["yuantan"] = "袁谭",
  ["#yuantan"] = "兄弟阋墙",
  ["illustrator:yuantan"] = "鬼画府",

  ["~yuantan"] = "咄，儿过我，必使富贵……呃啊！",
}

General:new(extension, "os__caohua", "wei", 3, 3, General.Female):addSkills { "os__caiyi", "guili" }
Fk:loadTranslationTable{
  ["os__caohua"] = "曹华",
  ["#os__caohua"] = "殊凰求凤",
  ["illustrator:os__caohua"] = "圆子", -- 彩蝶恋花

  ["$guili_os__caohua1"] = "凤非梧桐不栖，小女遍寻城中未见一木。",
  ["$guili_os__caohua2"] = "魏王与我相看两厌，不如归离，相忘江湖。",
  ["~os__caohua"] = "妾虽生于曹家，然绝无异心！",
}

General:new(extension, "os__zhangyao", "wu", 3, 3, General.Female):addSkills { "os__yuanyu", "os__xiyan" }
Fk:loadTranslationTable{
  ["os__zhangyao"] = "张媱",
  ["#os__zhangyao"] = "琼楼孤蒂",
  ["illustrator:os__zhangyao"] = "木美人", -- 双姝绰约

  ["~os__zhangyao"] = "寻常良家妇，胜过君王妃。",
}

General:new(extension, "os__wangchang", "wei", 3):addSkills { "os__kaiji", "os__shepan" }
Fk:loadTranslationTable{
  ["os__wangchang"] = "王昶",
  ["#os__wangchang"] = "识度良臣",
  ["illustrator:os__wangchang"] = "鬼画府",

  ["~os__wangchang"] = "吾切至之言，望尔等引以为戒。",
}

--樽
General:new(extension, "zhanghong", "wu", 3):addSkills { "os__quanqian", "os__rouke" }
Fk:loadTranslationTable{
  ["zhanghong"] = "张纮",
  ["#zhanghong"] = "为世令器",
  ["illustrator:zhanghong"] = "腥鱼仔",

  ["~zhanghong"] = "惟愿主公从善如流，老臣去矣……",
}

General:new(extension, "zhangzhao", "wu", 3):addSkills { "os__lijians", "os__chungang" }
Fk:loadTranslationTable{
  ["zhangzhao"] = "张昭",
  ["#zhangzhao"] = "功勳克举",
  ["illustrator:zhangzhao"] = "YanBai",

  ["~zhangzhao"] = "哼哼！此皆老臣罪责，陛下岂会有过……",
}

General:new(extension, "zhangjih", "wei", 3):addSkills { "os__dingzhen", "os__youye" }
Fk:loadTranslationTable{
  ["zhangjih"] = "张既",
  ["#zhangjih"] = "边安人宁",
  ["illustrator:zhangjih"] = "depp",
  ["designer:zhangjih"] = "Loun老萌",

  ["~zhangjih"] = "恨不见四海肃眘，羌胡徕服。",
}

General:new(extension, "os__tianyu", "wei", 4):addSkills { "os__zhenxi", "os__yangshi" }
Fk:loadTranslationTable{
  ["os__tianyu"] = "田豫",
  ["#os__tianyu"] = "规略明练",
  ["illustrator:os__tianyu"] = "鬼画府",
  ["designer:os__tianyu"] = "梦魇狂朝 & Loun老萌",

  ["~os__tianyu"] = "钟鸣漏尽，夜行不休……",
}

General:new(extension, "jiangji", "wei", 3):addSkills { "os__jichou", "os__jilun" }
Fk:loadTranslationTable{
  ["jiangji"] = "蒋济",
  ["#jiangji"] = "盛魏昌杰",
  ["designer:jiangji"] = "千幻",
  ["illustrator:jiangji"] = "铁杵文化",

  ["~jiangji"] = "洛水之誓，言犹在耳……咳咳咳",
}

General:new(extension, "os__huangquan", "shu", 4):addSkills { "quanjian", "os__tujue" }
Fk:loadTranslationTable{
  ["os__huangquan"] = "黄权",
  ["#os__huangquan"] = "忠事三朝",
  ["illustrator:os__huangquan"] = "错落宇宙", -- 沸江焚役

  ["$quanjian_os__huangquan1"] = "臣请为先锋当敌，一探吴寇之虚实。",
  ["$quanjian_os__huangquan2"] = "军情叵测，陛下万金之躯岂能驱险！",
  ["~os__huangquan"] = "臣有恨大江无路，无愧陛下知遇。",
}

--野
General:new(extension, "zhugejun", "qun", 3):addSkills { "os__shouzhu", "os__daigui", "os__cairu" }
Fk:loadTranslationTable{
  ["zhugejun"] = "诸葛均",
  ["#zhugejun"] = "待兄归乡",
  ["illustrator:zhugejun"] = "错落宇宙",

  ["~zhugejin"] = "战火延绵，不知兄长归期。",
}

General:new(extension, "bingyuan", "qun", 3):addSkills { "os__bingde", "os__qingtao" }
Fk:loadTranslationTable{
  ["bingyuan"] = "邴原",
  ["#bingyuan"] = "峰名谷怀",
  ["designer:bingyuan"] = "Loun老萌",
  ["illustrator:bingyuan"] = "鬼画府",

  ["~bingyuan"] = "人能弘道，非道弘人。",
}

General:new(extension, "os__pangshanmin", "wei", 4):addSkills { "caisi", "zhuoli" }
Fk:loadTranslationTable{
  ["os__pangshanmin"] = "庞山民",
  ["#os__pangshanmin"] = "抱玉向晚",
  ["illustrator:os__pangshanmin"] = "梦想君",  --鸿门锦书

  ["~os__pangshanmin"] = "荆襄草木胜，可牵黄犬出东门。",
}

--杰
General:new(extension, "zhangmancheng", "qun", 4):addSkills { "os__fengji", "os__yiju", "os__budao" }
Fk:loadTranslationTable{
  ["zhangmancheng"] = "张曼成",
  ["#zhangmancheng"] = "南阳渠帅",
  ["illustrator:zhangmancheng"] = "RF",

  ["~zhangmancheng"] = "天师，曼成尽力了。",
}

General:new(extension, "wufuluo", "qun", 6):addSkills { "os__jiekuang", "os__neirao" }
Fk:loadTranslationTable{
  ["wufuluo"] = "于夫罗",
  ["#wufuluo"] = "援汉雄狼",
  ["illustrator:wufuluo"] = "biou09",

  ["~wufuluo"] = "胡马依北风，越鸟巢南枝……",
}

General:new(extension, "duosidawang", "qun", 4, 5):addSkills { "os__equan", "os__manji" }
Fk:loadTranslationTable{
  ["duosidawang"] = "朵思大王",
  ["#duosidawang"] = "踞泉毒蛟",
  ["illustrator:duosidawang"] = "蚂蚁君",

  ["~duosidawang"] = "快快放箭！快快放箭！",
}

General:new(extension, "os__zangba", "wei", 4):addSkills { "os__hanyu", "os__hengjiang" }
Fk:loadTranslationTable{
  ["os__zangba"] = "臧霸",
  ["#os__zangba"] = "横行江表",
  ["illustrator:os__zangba"] = "HOOO",

  ["~os__zangba"] = "短刃沉江，负主重托……",
}

--香
General:new(extension, "liufuren", "qun", 3, 3, General.Female):addSkills { "os__zhuidu", "os__shigong" }
Fk:loadTranslationTable{
  ["liufuren"] = "刘夫人",
  ["#liufuren"] = "酷妒的海棠",
  ["illustrator:liufuren"] = "Jzeo",
  ["designer:liufuren"] = "梦魇狂朝",

  ["~liufuren"] = "害人终害己，最毒妇人心……",
}

General:new(extension, "os__zhangning", "qun", 3, 3, General.Female):addSkills { "os__xingzhui", "os__juchen" }
Fk:loadTranslationTable{
  ["os__zhangning"] = "张宁",
  ["#os__zhangning"] = "大贤后人",
  ["illustrator:os__zhangning"] = "biou09",

  ["~os__zhangning"] = "风过烟尘散，雨罢雷音绝。",
}

General:new(extension, "os__xiahoulingnv", "wei", 4, 4, General.Female):addSkills { "fuping", "os__weilie" }
Fk:loadTranslationTable{
  ["os__xiahoulingnv"] = "夏侯令女",
  ["#os__xiahoulingnv"] = "女义如山",
  ["illustrator:os__xiahoulingnv"] = "鬼画府", -- 琼英缀寒

  ["$fuping_os__xiahoulingnv1"] = "滚滚江水东流去，别有孤萍朝夕浮。",
  ["$fuping_os__xiahoulingnv2"] = "去后故人双别泪，春深逐客一浮萍。",
  ["~os__xiahoulingnv"] = "父亲无须多言，女儿宁死不从！",
}

General:new(extension, "os__yanfuren", "qun", 3, 3, General.Female):addSkills { "channi", "os__nifu" }
Fk:loadTranslationTable{
  ["os__yanfuren"] = "严夫人",
  ["#os__yanfuren"] = "霜天薄裳",
  ["illustrator:os__yanfuren"] = "随随", -- 长乐未央

  ["$channi_os__yanfuren1"] = "细雨春风语七九，河开燕来芳菲流。",
  ["$channi_os__yanfuren2"] = "莺语燕歌引春风，双瞳剪柳绿意浓。",
  ["~os__yanfuren"] = "春寒料峭，此身不胜寒。",
}

--戈
General:new(extension, "yanliang", "qun", 4):addSkills { "os__duwang", "os__yanshih" }
Fk:loadTranslationTable{
  ["yanliang"] = "颜良",
  ["#yanliang"] = "何惧华雄",
  ["illustrator:yanliang"] = "Mr_Sleeping",

  ["~yanliang"] = "哥哥，切不可轻敌……",
}

General(extension, "wenchou", "qun", 4):addSkills { "os__juexing", "os__xiayong" }
Fk:loadTranslationTable{
  ["wenchou"] = "文丑",
  ["#wenchou"] = "有去无回",
  ["illustrator:wenchou"] = "Mr_Sleeping",

  ["~wenchou"] = "黄泉路上，你我兄弟亦不可独行……",
}

General:new(extension, "os__jiling", "qun", 4):addSkills { "os__shuangren" }
Fk:loadTranslationTable{
  ["os__jiling"] = "纪灵",
  ["#os__jiling"] = "仲家的主将",

  ["~os__jiling"] = "额，将军为何咆哮不断……",
}

General:new(extension, "os__mateng", "qun", 4):addSkills { "mashu", "os__xiongzheng", "os__luannian" }
Fk:loadTranslationTable{
  ["os__mateng"] = "马腾",
  ["#os__mateng"] = "驰骋西陲",
  ["illustrator:os__mateng"] = "游江",
  ["designer:os__mateng"] = "步穗",

  ["~os__mateng"] = "皇叔，剩下的就靠你了……",
}

General:new(extension, "baoxin", "qun", 4):addSkills { "os__mutao", "os__yimou" }
Fk:loadTranslationTable{
  ["baoxin"] = "鲍信",
  ["#baoxin"] = "坚朴的忠相",
  ["illustrator:baoxin"] = "凡果",
  ["designer:baoxin"] = "jcj熊",

  ["~baoxin"] = "区区黄巾流寇，如何挡我？呃啊……",
}

General:new(extension, "xiahoushang", "wei", 4):addSkill("os__tanfeng")
Fk:loadTranslationTable{
  ["xiahoushang"] = "夏侯尚",
  ["illustrator:xiahoushang"] = "云涯",
  ["#xiahoushang"] = "魏胤前驱",
  ["designer:xiahoushang"] = "耑端瑞湍",

  ["~xiahoushang"] = "陛下垂怜至此，臣纵死无憾……",
}

General:new(extension, "os__niujin", "wei", 4):addSkills { "os__cuorui", "os__liewei" }
Fk:loadTranslationTable{
  ["os__niujin"] = "牛金",
  ["#os__niujin"] = "独进的兵胆",
  ["illustrator:os__niujin"] = "青骑士",

  ["~os__niujin"] = "这包围圈太厚，老牛，尽力了……",
}

General:new(extension, "os__wuban", "shu", 4):addSkill("os__jintao")
Fk:loadTranslationTable{
  ["os__wuban"] = "吴班",
  ["#os__wuban"] = "碧血的英豪",
  ["illustrator:os__wuban"] = "铁杵文化",

  ["~os__wuban"] = "恨，杀不尽吴狗！",
}

--附
General:new(extension, "os__zhangxun", "qun", 4):addSkills { "os2__suizheng" }
Fk:loadTranslationTable{
  ["os__zhangxun"] = "张勋",
  ["#os__zhangxun"] = "仲家将军",
  ["illustrator:os__zhangxun"] = "一意动漫", -- 七部伐吕

  ["~os__zhangxun"] = "伯符，恐不复相见。",
}

General:new(extension, "os__jiachong", "qun", 3):addSkills { "os__beini", "os__dingfa" }
Fk:loadTranslationTable{
  ["os__jiachong"] = "贾充",
  ["#os__jiachong"] = "凶凶踽行",
  ["designer:os__jiachong"] = "Loun老萌",
  ["illustrator:os__jiachong"] = "铁杵文化",
  ["cv:os__jiachong"] = "虞晓旭",

  ["~os__jiachong"] = "此生从势忠命，此刻，只乞不获恶谥……",
}

General:new(extension, "xiahouen", "wei", 5):addSkills { "os__fujian", "os__jianwei" }
Fk:loadTranslationTable{
  ["xiahouen"] = "夏侯恩",
  ["#xiahouen"] = "长坂剑灵",
  ["designer:xiahouen"] = "会玩的许劭",
  ["illustrator:xiahouen"] = "蚂蚁君",

  ["~xiahouen"] = "长坂剑神，也陨落了……",
}

General:new(extension, "yanxiang", "qun", 3):addSkills { "os__kujian", "os__ruilian" }
Fk:loadTranslationTable{
  ["yanxiang"] = "阎象",
  ["#yanxiang"] = "明尚夙达",
  ["illustrator:yanxiang"] = "zoo",

  ["~yanxiang"] = "若遇明主，或可青史留名……",
}

General:new(extension, "os__puyangxing", "wu", 4):addSkills { "os__zhengjian", "os__zhongchi" }
Fk:loadTranslationTable{
  ["os__puyangxing"] = "濮阳兴",
  ["#os__puyangxing"] = "协邪肆民",
  ["illustrator:os__puyangxing"] = "铁杵文化",
  ["designer:os__puyangxing"] = "步穗",

  ["~os__puyangxing"] = "陛下已流放吾等，为何……啊！",
}

General:new(extension, "liwei", "shu", 4):addSkill("os__jiaohua")
Fk:loadTranslationTable{
  ["liwei"] = "李遗",
  ["#liwei"] = "伏被俞元",
  ["illustrator:liwei"] = "付玉",

  ["~liwei"] = "安南重任，万不可轻之……",
}

--散
General:new(extension, "gongsunfan", "qun", 4):addSkills { "os__huiyuan", "os__shoushou" }
Fk:loadTranslationTable{
  ["gongsunfan"] = "公孙范",
  ["#gongsunfan"] = "助瓒讨袁",
  ["illustrator:gongsunfan"] = "鱼仔",

  ["~gongsunfan"] = "公孙氏之业，终付之一炬……",
}

General:new(extension, "yangang", "qun", 4):addSkills { "os__zhiqu", "os__xianfeng" }
Fk:loadTranslationTable{
  ["yangang"] = "严纲",
  ["#yangang"] = "马下败将",
  ["illustrator:yangang"] = "鱼仔",

  ["~yangang"] = "诸将，冲锋！呃啊……",
}

General:new(extension, "niufudongxie", "qun", 4, 4, General.Bigender):addSkills { "os__juntun", "os__xiongxi", "os__xiafeng" }
Fk:loadTranslationTable{
  ["niufudongxie"] = "牛辅董翓",
  ["#niufudongxie"] = "虺伴蝎行",
  ["illustrator:niufudongxie"] = "王立雄",

  ["~niufudongxie"] = "董公遗命，谁可继之……",
}

General:new(extension, "jianshuo", "qun", 6):addSkill("os__kunsi")
Fk:loadTranslationTable{
  ["jianshuo"] = "蹇硕",
  ["#jianshuo"] = "西园硕犀",
  ["illustrator:jianshuo"] = "XXX",

  ["~jianshuo"] = "郭胜，汝竟下此狠手！",
}

General:new(extension, "huchuquan", "qun", 4):addSkill("os__fupan")
Fk:loadTranslationTable{
  ["huchuquan"] = "呼厨泉",
  ["#huchuquan"] = "踞北桀鹰",
  ["illustrator:huchuquan"] = "小牛",
  ["designer:huchuquan"] = "步穗",

  ["~huchuquan"] = "久困汉庭，无力再叛……",
}

General:new(extension, "yuejiu", "qun", 4):addSkill("os__cuijin")
Fk:loadTranslationTable{
  ["yuejiu"] = "乐就",
  ["#yuejiu"] = "仲家军督",
  ["designer:yuejiu"] = "Loun老萌",
  ["illustrator:yuejiu"] = "铁杵文化",

  ["~yuejiu"] = "哼，动手吧！",
}

--遗
General:new(extension, "os__heyan", "wei", 3):addSkills { "yachai", "os__qingtan" }
Fk:loadTranslationTable{
  ["os__heyan"] = "何晏",
  ["#os__heyan"] = "傅粉何郎",
  ["illustrator:os__heyan"] = "匪萌十月", -- 忆梦慕蝶

  ["$yachai_os__heyan1"] = "附会者升进，违忤者罢退。",
  ["$yachai_os__heyan2"] = "铦巧好利，莫敢忤旨。",
  ["~os__heyan"] = "司马懿加害于吾，玄学不存。",
}

General:new(extension, "licuilianquanding", "shu", 3, 3, General.Bigender):addSkills { "os__ciyin", "os__chenglong" }
Fk:loadTranslationTable{
  ["licuilianquanding"] = "李翠莲全定",
  ["#licuilianquanding"] = "望子成龙",
  ["illustrator:licuilianquanding"] = "凝聚永恒",

  ["~licuilianquanding"] = "吾儿，前路坎坷，为母恐不能再行……/母亲！母亲……",
}

--沙
General:new(extension, "zhangnan", "shu", 4):addSkill("os__fenwu")
Fk:loadTranslationTable{
  ["zhangnan"] = "张南",
  ["#zhangnan"] = "澄辉的义烈",
  ["illustrator:zhangnan"] = "Aaron",

  ["~zhangnan"] = "骨埋吴地，魂归汉土……",
}

General:new(extension, "fengxi", "shu", 4):addSkill("os__qingkou")
Fk:loadTranslationTable{
  ["fengxi"] = "冯习",
  ["#fengxi"] = "赤胆的忠魂",
  ["illustrator:fengxi"] = "陈鑫",

  ["~fengxi"] = "陛下，速退白帝……",
}

return extension
