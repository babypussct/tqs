local extension = Package:new("mobile_rare")
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/mobile_rare/skills")

Fk:loadTranslationTable{
  ["mobile_rare"] = "手杀-稀有专属",
  ["mobile"] = "手杀",
  ["mxing"] = "手杀星",
  ["m_friend"] = "友",
  ["m_thoroughbred"] = "骥",
}

--袖里乾坤：
General:new(extension, "sunru", "wu", 3, 3, General.Female):addSkills { "yingjian", "shixin" }
Fk:loadTranslationTable{
  ["sunru"] = "孙茹",
  ["#sunru"] = "出水青莲",
  ["illustrator:sunru"] = "撒呀酱",

  ["~sunru"] = "佑我江东，虽死无怨。",
}

General:new(extension, "lingcao", "wu", 4):addSkills { "dujin" }
Fk:loadTranslationTable{
  ["lingcao"] = "凌操",
  ["#lingcao"] = "激流勇进",
  ["illustrator:lingcao"] = "樱花闪乱",

  ["~lingcao"] = "呃啊！（扑通）此箭……何来……",
}

General:new(extension, "liuzan", "wu", 4):addSkills { "fenyin" }
Fk:loadTranslationTable{
  ["liuzan"] = "留赞",
  ["#liuzan"] = "啸天亢声",
  ["cv:liuzan"] = "腾格尔",
  ["designer:liuzan"] = "东郊易尘Noah",
  ["illustrator:liuzan"] = "酸包",

  ["~liuzan"] = "贼子们，来吧！啊…………",
}

General:new(extension, "miheng", "qun", 3):addSkills { "mobile__kuangcai", "mobile__shejian" }
Fk:loadTranslationTable{
  ["miheng"] = "祢衡",
  ["#miheng"] = "鸷鹗啄孤凤",
  ["designer:miheng"] = "千幻",
  ["illustrator:miheng"] = "Thinking",

  ["~miheng"] = "呵呵呵呵……这天地都容不下我！……",
}

General:new(extension, "caochun", "wei", 4):addSkills { "shanjia" }
Fk:loadTranslationTable{
  ["caochun"] = "曹纯",
  ["#caochun"] = "虎豹骑首",
  ["illustrator:caochun"] = "depp",

  ["~caochun"] = "银甲在身，竟败于你手！",
}

General:new(extension, "pangdegong", "qun", 3):addSkills { "pingcai", "yinship" }
Fk:loadTranslationTable{
  ["pangdegong"] = "庞德公",
  ["#pangdegong"] = "德懿举世",
  ["illustrator:pangdegong"] = "Town",

  ["~pangdegong"] = "吾知人而不自知，何等荒唐。",
}

General:new(extension, "majun", "wei", 3):addSkills { "jingxie", "qiaosi" }
Fk:loadTranslationTable{
  ["majun"] = "马钧",
  ["#majun"] = "没渊瑰璞",
  ["cv:majun"] = "金垚",
  ["designer:majun"] = "Loun老萌",
  ["illustrator:majun"] = "聚一_小道恩",

  ["~majun"] = "衡石不用，美玉见诬啊！",
  ["!majun"] = "吾巧益于世间，真乃幸事！",
}

General:new(extension, "zhengxuan", "qun", 3):addSkills { "zhengjing" }
Fk:loadTranslationTable{
  ["zhengxuan"] = "郑玄",
  ["#zhengxuan"] = "兼采定道",
  ["designer:zhengxuan"] = "Loun老萌",
  ["illustrator:zhengxuan"] = "monkey",

  ["~zhengxuan"] = "注易未毕，奈何寿数将近……",
}

General:new(extension, "nanhualaoxian", "qun", 3):addSkills { "mobile__yufeng", "mobile__tianshu" }
Fk:loadTranslationTable{
  ["nanhualaoxian"] = "南华老仙",
  ["#nanhualaoxian"] = "冯虚御风",
  ["cv:nanhualaoxian"] = "宋国庆",
  ["illustrator:nanhualaoxian"] = "君桓文化",

  ["~nanhualaoxian"] = "天机求而近，执而远……",
  ["!nanhualaoxian"] = "纷总总兮九州，何寿夭兮在予？",
}

local shichangshi = General:new(extension, "shichangshi", "qun", 1)
shichangshi:addSkills { "danggu", "mowang" }
shichangshi:addRelatedSkills{
  "changshi__taoluan",
  "changshi__chiyan",
  "changshi__zimou",
  "changshi__picai",
  "changshi__yaozhuo",
  "changshi__xiaolu",
  "changshi__kuiji",
  "changshi__chihe",
  "changshi__niqu",
  "changshi__miaoyu"
}
for _, name in ipairs({
  "changshi__zhangrang",
  "changshi__zhaozhong",
  "changshi__sunzhang",
  "changshi__bilan",
  "changshi__xiayun",
  "changshi__hankui",
  "changshi__lisong",
  "changshi__duangui",
  "changshi__guosheng",
  "changshi__gaowang",
}) do
  local changshi = General:new(extension, name, "qun", 1)
  changshi:addSkills { "danggu", "mowang" }
  changshi.total_hidden = true
end
Fk:loadTranslationTable{
  ["shichangshi"] = "十常侍",
  ["#shichangshi"] = "祸乱纲常",
  ["illustrator:shichangshi"] = "鱼仔",

  ["changshi"] = "常侍",
  ["changshi__zhangrang"] = "张让",
  ["illustrator:changshi__zhangrang"] = "凡果",
  ["changshi__zhaozhong"] = "赵忠",
  ["illustrator:changshi__zhaozhong"] = "凡果",
  ["changshi__sunzhang"] = "孙璋",
  ["illustrator:changshi__sunzhang"] = "鬼画府",
  ["changshi__bilan"] = "毕岚",
  ["illustrator:changshi__bilan"] = "鬼画府",
  ["changshi__xiayun"] = "夏恽",
  ["illustrator:changshi__xiayun"] = "铁杵文化",
  ["changshi__hankui"] = "韩悝",
  ["illustrator:changshi__hankui"] = "鬼画府",
  ["changshi__lisong"] = "栗嵩",
  ["illustrator:changshi__lisong"] = "铁杵文化",
  ["changshi__duangui"] = "段珪",
  ["illustrator:changshi__duangui"] = "鬼画府",
  ["changshi__guosheng"] = "郭胜",
  ["illustrator:changshi__guosheng"] = "鬼画府",
  ["changshi__gaowang"] = "高望",
  ["illustrator:changshi__gaowang"] = "鬼画府",

  ["!shichangshi"] = "十常侍威势更甚，再无人可掣肘。",

  ["$changshi__zhangrang_taunt1"] = "吾乃当今帝父，汝岂配与我同列？",
  ["$changshi__zhaozhong_taunt1"] = "汝此等语，何不以溺自照？",
  ["$changshi__sunzhang_taunt1"] = "闻谤而怒，见誉而喜，汝万万不能啊！",
  ["$changshi__bilan_taunt1"] = "吾虽鄙夫，亦远胜尔等狂叟！",
  ["$changshi__xiayun_taunt1"] = "贪财好贿，其罪尚小，不敬不逊，却为大逆！",
  ["$changshi__hankui_taunt1"] = "切！宁享短福，莫为汝等庸奴！",
  ["$changshi__lisong_taunt1"] = "区区不才，可为帝之耳目，试问汝有何能？",
  ["$changshi__duangui_taunt1"] = "哼，不过襟裾牛马，衣冠狗彘尓！",
  ["$changshi__guosheng_taunt1"] = "此昏聩之徒，吾羞与为伍。",
  ["$changshi__gaowang_taunt1"] = "若非吾之相助，汝安有今日？",
}

local cuifu = General:new(extension, "mobile__cuilingyi", "wei", 3, 3, General.Female)
cuifu:addSkills { "caiqiu", "xichang" }
cuifu:addRelatedSkills { "weizhuang", "mobile_dongjiao__weizhuang", "mobile_xiuge__weizhuang" }

local cuifu2 = General:new(extension, "mobile_dongjiao__cuilingyi", "wei", 3, 3, General.Female)
cuifu2:addSkills { "caiqiu", "xichang" }
cuifu2:addRelatedSkills { "weizhuang", "mobile_dongjiao__weizhuang", "mobile_xiuge__weizhuang" }
cuifu2.total_hidden = true

local cuifu3 = General:new(extension, "mobile_xiuge__cuilingyi", "wei", 3, 3, General.Female)
cuifu3:addSkills { "caiqiu", "xichang" }
cuifu3:addRelatedSkills { "weizhuang", "mobile_dongjiao__weizhuang", "mobile_xiuge__weizhuang" }
cuifu3.total_hidden = true
Fk:loadTranslationTable{
  ["mobile__cuilingyi"] = "崔芙",
  ["#mobile__cuilingyi"] = "戴冠金尾",
  ["illustrator:mobile__cuilingyi"] = "荧光笔",

  ["mobile_dongjiao"] = "手杀",
  ["mobile_dongjiao__cuilingyi"] = "崔芙",
  ["#mobile_dongjiao__cuilingyi"] = "戴冠金尾",
  ["illustrator:mobile_dongjiao__cuilingyi"] = "荧光笔",

  ["mobile_xiuge"] = "手杀",
  ["mobile_xiuge__cuilingyi"] = "崔芙",
  ["#mobile_xiuge__cuilingyi"] = "戴冠金尾",
  ["illustrator:mobile_xiuge__cuilingyi"] = "荧光笔",

  ["!mobile__cuilingyi"] = "若论衣装点绛，谁可胜我半分？",
  ["~mobile__cuilingyi"] = "铅华难驻容千载，贵贱同归土一丘。",
}

General:new(extension, "mobile__zhangfen", "wu", 4):addSkills { "quchong", "mobile__xunjie" }
Fk:loadTranslationTable{
  ["mobile__zhangfen"] = "张奋",
  ["#mobile__zhangfen"] = "究械菁杰",
  ["illustrator:mobile__zhangfen"] = "铁杵",

  ["~mobile__zhangfen"] = "而立之年，未立功名，实憾也……",
  ["!mobile__zhangfen"] = "治于神者，众人当知其功！",
}

General:new(extension, "zhujic", "wu", 4):addSkills { "jiezhu", "huanshiz" }
Fk:loadTranslationTable{
  ["zhujic"] = "朱绩",
  ["#zhujic"] = "克绍箕裘",
  ["illustrator:zhujic"] = "腥鱼仔",

  ["~zhujic"] = "诸葛融何以引军不发，致我有此惨败。",
}

local shiji = General:new(extension, "shijic", "wu", 4)
shiji:addSkills { "jiezhu", "huanshiz" }
shiji.total_hidden = true
Fk:loadTranslationTable{
  ["shijic"] = "施绩",
  ["#shijic"] = "克绍箕裘",
  --["illustrator:shijic"] = "",

  ["$jiezhu_shijic1"] = "趁魏军退走，我等可急令进军。",
  ["$jiezhu_shijic2"] = "虽攻敌不足，然退守有余矣。",

  ["~shijic"] = "唉，内忧致此，回天无力啊。",
}

General:new(extension, "mobile__cheliji", "qun", 4):addSkills { "qusheng", "qiangyong" }
Fk:loadTranslationTable{
  ["mobile__cheliji"] = "彻里吉",
  ["#mobile__cheliji"] = "北境寒锋",
  --["illustrator:mobile__cheliji"] = "",

  ["~mobile__cheliji"] = "诸葛妖人，害我雄师。",
}

General:new(extension, "mobile__godlvbu", "god", 5):addSkills { "kuangbao", "mobile__wumou", "mobile__wuqian", "shenfen" }
Fk:loadTranslationTable{
  ["mobile__godlvbu"] = "神吕布",
  ["#mobile__godlvbu"] = "修罗之道",
  ["illustrator:mobile__godlvbu"] = "蛋费鸡丁",

  ["$kuangbao_mobile__godlvbu1"] = "嗯→↗↗↗啊！",
  ["$kuangbao_mobile__godlvbu2"] = "哼！",
  ["$shenfen_mobile__godlvbu1"] = "睁开眼睛看看吧，这活生生的地狱！",
  ["$shenfen_mobile__godlvbu2"] = "尔等即将化为齑粉！",
  ["$wushuang_mobile__godlvbu1"] = "统统臣服于我脚下吧！",
  ["$wushuang_mobile__godlvbu2"] = "我来送你下炼狱！",
  ["~mobile__godlvbu"] = "我在修罗炼狱等着尔等，哈哈哈哈，啊哈哈哈哈!",
}

General:new(extension, "mobile__godsimayi", "god", 4):addSkills { "mobile__renjie", "mobile__baiyin", "mobile__lianpo" }
Fk:loadTranslationTable{
  ["mobile__godsimayi"] = "神司马懿",
  ["#mobile__godsimayi"] = "三分一统",
  ["illustrator:mobile__godsimayi"] = "深圳枭瞳",

  ["~mobile__godsimayi"] = "洛水滔滔，难诉吾一生坎坷……",
}

--将星独具：
General:new(extension, "mxing__zhangliao", "qun", 4):addSkills { "weifeng" }
Fk:loadTranslationTable{
  ["mxing__zhangliao"] = "星张辽",
  ["#mxing__zhangliao"] = "蹈锋饮血",
  ["illustrator:mxing__zhangliao"] = "王强",

  ["~mxing__zhangliao"] = "惑于女子而尽失战机，庸主误我啊。",
  ["!mxing__zhangliao"] = "并州雄骑，自当扫清六合！",
}

General:new(extension, "mxing__zhanghe", "qun", 4):addSkills { "zhilve" }
Fk:loadTranslationTable{
  ["mxing__zhanghe"] = "星张郃",
  ["#mxing__zhanghe"] = "宁国中郎将",
  ["illustrator:mxing__zhanghe"] = "王强",

  ["~mxing__zhanghe"] = "若非小人作梗，何至官渡之败……",
  ["!mxing__zhanghe"] = "水因地制流，兵因敌制胜！",
}

General:new(extension, "mxing__xuhuang", "qun", 4):addSkills { "mxing__zhiyan" }
Fk:loadTranslationTable{
  ["mxing__xuhuang"] = "星徐晃",
  ["#mxing__xuhuang"] = "沉详性严",
  ["illustrator:mxing__xuhuang"] = "王强",

  ["~mxing__xuhuang"] = "唉，明主未遇，大功未成……",
  ["!mxing__xuhuang"] = "幸遇明主，更应立功报效国君。",
}

General:new(extension, "mxing__ganning", "qun", 4):addSkills { "jinfan", "sheque" }
Fk:loadTranslationTable{
  ["mxing__ganning"] = "星甘宁",
  ["#mxing__ganning"] = "铃震没羽",
  ["illustrator:mxing__ganning"] = "王强",

  ["~mxing__ganning"] = "铜铃声……怕是听不到了……",
  ["!mxing__ganning"] = "又是大丰收啊！弟兄们，扬帆起航！",
}

General:new(extension, "mxing__huangzhong", "qun", 4):addSkills { "shidi", "xing__yishi", "qishe" }
Fk:loadTranslationTable{
  ["mxing__huangzhong"] = "星黄忠",
  ["#mxing__huangzhong"] = "强挚烈弓",
  ["illustrator:mxing__huangzhong"] = "漫想族",

  ["~mxing__huangzhong"] = "关云长义释黄某，吾又安忍射之……",
}

local weiyan = General:new(extension, "mxing__weiyan", "qun", 4)
weiyan.shield = 1
weiyan:addSkills { "guli", "aosi" }
Fk:loadTranslationTable{
  ["mxing__weiyan"] = "星魏延",
  ["#mxing__weiyan"] = "骜勇孤战",
  ["illustrator:mxing__weiyan"] = "鬼画府",

  ["~mxing__weiyan"] = "使君为何弃我而去……呃啊！",
}

General:new(extension, "mxing__zhoubuyi", "wei", 3):addSkills { "huiyao", "quesong" }
Fk:loadTranslationTable{
  ["mxing__zhoubuyi"] = "星周不疑",
  ["#mxing__zhoubuyi"] = "稚雀清声",
  ["illustrator:mxing__zhoubuyi"] = "君桓文化",

  ["~mxing__zhoubuyi"] = "慧童亡，天下伤……",
}

General:new(extension, "mxing__dongzhuo", "qun", 3, 4):addSkills { "xiongjin", "zhenbian", "baoxi" }
Fk:loadTranslationTable{
  ["mxing__dongzhuo"] = "星董卓",
  ["#mxing__dongzhuo"] = "破羌安边",
  ["illustrator:mxing__dongzhuo"] = "凝聚永恒",

  ["~mxing__dongzhuo"] = "本欲坐观时变，奈何天不遂我啊。",
}

General:new(extension, "mxing__fazheng", "qun", 3):addSkills { "cangjia", "duohui", "yueyuan" }
Fk:loadTranslationTable{
  ["mxing__fazheng"] = "星法正",
  ["#mxing__fazheng"] = "弹铗待试",
  ["illustrator:mxing__fazheng"] = "凝聚永恒",

  ["!mxing__fazheng"] = "益州形胜之地，可为将军复汉之基。",
  ["~mxing__fazheng"] = "将军今若不取，必为他人所图。",
}

General:new(extension, "mxing__wanglang", "qun", 4):addSkills { "fuyu", "zhanshi" }
Fk:loadTranslationTable{
  ["mxing__wanglang"] = "星王朗",
  ["#mxing__wanglang"] = "负固不服",
  --["illustrator:mxing__wanglang"] = "",

  ["~mxing__wanglang"] = "朗不能死节，愧对汉室英烈！",
}

--老友季：
General:new(extension, "m_friend__zhugeliang", "qun", 3):addSkills { "yance", "fangqiu", "zhugeliang__gongli" }
Fk:loadTranslationTable{
  ["m_friend__zhugeliang"] = "友诸葛亮",
  ["#m_friend__zhugeliang"] = "龙骧九天",
  ["illustrator:m_friend__zhugeliang"] = "zoo",

  ["~m_friend__zhugeliang"] = "吾既得明主，纵不得良时，亦当全力一试……",
  ["!m_friend__zhugeliang"] = "鼎足之势若成，则将军中原可图也。",
}

General:new(extension, "m_friend__pangtong", "qun", 3):addSkills { "friend__manjuan", "friend__yangming", "pangtong__gongli" }
Fk:loadTranslationTable{
  ["m_friend__pangtong"] = "友庞统",
  ["#m_friend__pangtong"] = "凤翥南地",
  ["illustrator:m_friend__pangtong"] = "zoo",

  ["~m_friend__pangtong"] = "大事未竟，惜哉，惜哉……",
}

General:new(extension, "m_friend__xushu", "qun", 3):addSkills { "xiaxing", "qihui", "xushu__gongli" }
Fk:loadTranslationTable{
  ["m_friend__xushu"] = "友徐庶",
  ["#m_friend__xushu"] = "潜悟诲人",
  ["illustrator:m_friend__xushu"] = "zoo",

  ["~m_friend__xushu"] = "百姓陷于苦海，而吾却难以济之……",
}

--千里之骥：
General:new(extension, "m_thoroughbred__zhangliao", "wei", 4):addSkills { "chonglei", "dangshi", "zhangliao__heyu" }
Fk:loadTranslationTable{
  ["m_thoroughbred__zhangliao"] = "骥张辽",
  ["#m_thoroughbred__zhangliao"] = "气夺三军",
  ["illustrator:m_thoroughbred__zhangliao"] = "六爻",

  ["!m_thoroughbred__zhangliao"] = "二位将军，今日方知吾等同心之利！",
  ["~m_thoroughbred__zhangliao"] = "人生世间，谁无一死乎……",
}

General:new(extension, "m_thoroughbred__lidian", "wei", 3):addSkills { "duanjin", "gaigong", "lidian__heyu" }
Fk:loadTranslationTable{
  ["m_thoroughbred__lidian"] = "骥李典",
  ["#m_thoroughbred__lidian"] = "义忘私隙",
  ["illustrator:m_thoroughbred__lidian"] = "凝聚永恒",

  ["~m_thoroughbred__lidian"] = "大丈夫死则死矣，唯声名不容有污！",
}

General:new(extension, "m_thoroughbred__yuejin", "wei", 4):addSkills { "xianjian", "zherui", "yuejin__heyu" }
Fk:loadTranslationTable{
  ["m_thoroughbred__yuejin"] = "骥乐进",
  ["#m_thoroughbred__yuejin"] = "折冲御侮",
  ["illustrator:m_thoroughbred__yuejin"] = "凝聚永恒",

  ["~m_thoroughbred__yuejin"] = "箭疮崩裂，犹可杀贼！",
}

local weapon__xianjian = fk.CreateCard{
  name = "&weapon__xianjian",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
}
extension:loadCardSkels{weapon__xianjian}
extension:addCardSpec("weapon__xianjian")

local armor__xianjian = fk.CreateCard{
  name = "&armor__xianjian",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
}
extension:loadCardSkels{armor__xianjian}
extension:addCardSpec("armor__xianjian")

local offensive_horse__xianjian = fk.CreateCard{
  name = "&offensive_horse__xianjian",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeOffensiveRide,
}
extension:loadCardSkels{offensive_horse__xianjian}
extension:addCardSpec("offensive_horse__xianjian")

local defensive_horse__xianjian = fk.CreateCard{
  name = "&defensive_horse__xianjian",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeDefensiveRide,
}
extension:loadCardSkels{defensive_horse__xianjian}
extension:addCardSpec("defensive_horse__xianjian")

local treasure__xianjian = fk.CreateCard{
  name = "&treasure__xianjian",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
}
extension:loadCardSkels{treasure__xianjian}
extension:addCardSpec("treasure__xianjian")
Fk:loadTranslationTable{
  ["weapon__xianjian"] = "陷坚",
  ["armor__xianjian"] = "陷坚",
  ["offensive_horse__xianjian"] = "陷坚",
  ["defensive_horse__xianjian"] = "陷坚",
  ["treasure__xianjian"] = "陷坚",
  [":weapon__xianjian"] = "这是一张“陷坚”武器。",
  [":armor__xianjian"] = "这是一张“陷坚”防具。",
  [":offensive_horse__xianjian"] = "这是一张“陷坚”进攻坐骑。",
  [":defensive_horse__xianjian"] = "这是一张“陷坚”防御坐骑。",
  [":treasure__xianjian"] = "这是一张“陷坚”宝物。",
}


return extension
