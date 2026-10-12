local extension = Package:new("m_yj_ex")
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/yj_ex/skills")

Fk:loadTranslationTable{
  ["m_yj_ex"] = "手杀-界一将成名",
  ["m_ex"] = "手杀界",
}

General:new(extension, "m_ex__caozhi", "wei", 3):addSkills { "luoying", "m_ex__jiushi", "chengzhang" }
Fk:loadTranslationTable{
  ["m_ex__caozhi"] = "界曹植",
  ["#m_ex__caozhi"] = "八斗之才",
  ["illustrator:m_ex__caozhi"] = "青岛磐蒲",
  ["~m_ex__caozhi"] = "先民谁不死，知命复何忧？",

  ["$luoying_m_ex__caozhi1"] = "转蓬离本根，飘摇随长风。",
  ["$luoying_m_ex__caozhi2"] = "高树多悲风，海水扬其波。",
}

General:new(extension, "m_ex__yujin", "wei", 4):addSkills { "m_ex__jieyue" }
Fk:loadTranslationTable{
  ["m_ex__yujin"] = "界于禁",
  ["#m_ex__yujin"] = "讨暴坚垒",
  ["illustrator:m_ex__yujin"] = "biou09",
  ["~m_ex__yujin"] = "如今临危处难，却负丞相三十年之赏识，唉……",
}

General:new(extension, "m_ex__lingtong", "wu", 4):addSkills { "m_ex__xuanfeng" }
Fk:loadTranslationTable{
  ["m_ex__lingtong"] = "界凌统",
  ["#m_ex__lingtong"] = "豪情烈胆",
  ["illustrator:m_ex__lingtong"] = "青岛磐蒲",

  ["~m_ex__lingtong"] = "先……停一下吧……",
}

General:new(extension, "m_ex__wuguotai", "wu", 3, 3, General.Female):addSkills { "m_ex__ganlu", "buyi" }
Fk:loadTranslationTable{
  ["m_ex__wuguotai"] = "界吴国太",
  ["#m_ex__wuguotai"] = "慈怀瑾瑜",
  ["illustrator:m_ex__wuguotai"] = "李秀森",
  ["~m_ex__wuguotai"] = "诸位卿家，还请尽力辅佐仲谋啊……",

  ["$buyi_m_ex__wuguotai1"] = "有我在，定保贤婿无虞！",
  ["$buyi_m_ex__wuguotai2"] = "东吴岂容汝等儿戏！",
}

General:new(extension, "m_ex__xusheng", "wu", 4):addSkills { "m_ex__pojun" }
Fk:loadTranslationTable{
  ["m_ex__xusheng"] = "界徐盛",
  ["#m_ex__xusheng"] = "江东的铁壁",
  ["cv:m_ex__xusheng"] = "金垚",
  ["illustrator:m_ex__xusheng"] = "铁杵文化",
  ["~m_ex__xusheng"] = "盛只恨，不能再为主公，破敌致胜了。",
}

General:new(extension, "m_ex__gaoshun", "qun", 4):addSkills { "m_ex__xianzhen", "m_ex__jinjiu" }
Fk:loadTranslationTable{
  ["m_ex__gaoshun"] = "界高顺",
  ["#m_ex__gaoshun"] = "攻无不克",
  ["illustrator:m_ex__gaoshun"] = "蛋费鸡丁",
  ["~m_ex__gaoshun"] = "可叹主公知而不用啊！",
}

General:new(extension, "m_ex__caozhang", "wei", 4):addSkills { "m_ex__jiangchi" }
Fk:loadTranslationTable{
  ["m_ex__caozhang"] = "界曹彰",
  ["#m_ex__caozhang"] = "黄须儿",
  ["illustrator:m_ex__caozhang"] = "枭瞳",

  ["~m_ex__caozhang"] = "黄须金甲，也难敌骨肉毒心！",
}

General:new(extension, "m_ex__liaohua", "shu", 4):addSkills { "m_ex__dangxian", "m_ex__fuli" }
Fk:loadTranslationTable{
  ["m_ex__liaohua"] = "界廖化",
  ["#m_ex__liaohua"] = "历尽沧桑",
  ["illustrator:m_ex__liaohua"] = "聚一工作室",

  ["~m_ex__liaohua"] = "兴复大业，就靠你们了！",
}

General:new(extension, "m_ex__chengpu", "wu", 4):addSkills { "m_ex__lihuo", "chunlao" }
Fk:loadTranslationTable{
  ["m_ex__chengpu"] = "界程普",
  ["#m_ex__chengpu"] = "三朝虎臣",
  ["illustrator:m_ex__chengpu"] = "monkey",

  ["$chunlao_m_ex__chengpu1"] = "备下佳酿，以做庆功之用。",
  ["$chunlao_m_ex__chengpu2"] = "饮此壮行酒，当立先头功。",
  ["~m_ex__chengpu"] = "以暴讨贼，竟遭报应吗？",
}

General:new(extension, "m_ex__bulianshi", "wu", 3, 3, General.Female):addSkills { "m_ex__anxu", "zhuiyi" }
Fk:loadTranslationTable{
  ["m_ex__bulianshi"] = "界步练师",
  ["#m_ex__bulianshi"] = "无冕之后",
  ["illustrator:m_ex__bulianshi"] = "凡果",

  ["$zhuiyi_m_ex__bulianshi1"] = "化作桃园只为君。",
  ["$zhuiyi_m_ex__bulianshi2"] = "魂若有灵，当助夫君。",
  ["~m_ex__bulianshi"] = "今生先君逝，来世再侍君……",
  ["!m_ex__bulianshi"] = "壮我江东，人才济济！",
}

General:new(extension, "m_ex__handang", "wu", 4):addSkills { "m_ex__gongqi", "jiefan" }
Fk:loadTranslationTable{
  ["m_ex__handang"] = "界韩当",
  ["#m_ex__handang"] = "死守南郡",
  ["illustrator:m_ex__handang"] = "灵龙艺游",

  ["$jiefan_m_ex__handang1"] = "当率解烦兵士五千，但听主公调遣！",
  ["$jiefan_m_ex__handang2"] = "为解主公之忧，吾自当拱手待命！",
  ["~m_ex__handang"] = "当愿再效力，奈何老病加身……",
}

General:new(extension, "m_ex__liubiao", "qun", 3):addSkills { "re__zishou", "m_ex__zongshi" }
Fk:loadTranslationTable{
  ["m_ex__liubiao"] = "界刘表",
  ["#m_ex__liubiao"] = "跨蹈汉南",
  ["illustrator:m_ex__liubiao"] = "光域",

  ["$re__zishou_m_ex__liubiao1"] = "忍时待机，以期坐收渔利！",
  ["$re__zishou_m_ex__liubiao2"] = "按兵不动，徐图荆襄霸业！",
  ["~m_ex__liubiao"] = "垂垂老矣，已忘壮年雄心……",
}

General:new(extension, "m_ex__gongsunzan", "qun", 4):addSkills { "qiaomeng", "m_ex__yicong" }
Fk:loadTranslationTable{
  ["m_ex__gongsunzan"] = "界公孙瓒",
  ["#m_ex__gongsunzan"] = "白马将军",
  ["illustrator:m_ex__gongsunzan"] = "fingerling",

  ["$qiaomeng_m_ex__gongsunzan1"] = "夺汝兵刃战马，尔等必败无疑。",
  ["$qiaomeng_m_ex__gongsunzan2"] = "摧敌思折枯，荡寇如反掌。",
  ["~m_ex__gongsunzan"] = "啊！（马叫声）",
}

General:new(extension, "m_ex__zhonghui", "wei", 4):addSkills { "m_ex__quanji", "m_ex__zili" }
Fk:loadTranslationTable{
  ["m_ex__zhonghui"] = "界钟会",
  ["#m_ex__zhonghui"] = "桀骜的野心家",
  ["illustrator:m_ex__zhonghui"] = "monkey",

  ["$paiyi_m_ex__zhonghui1"] = "坏吾大计者，罪死不赦！",
  ["$paiyi_m_ex__zhonghui2"] = "攻讦此子，祸咎已除！",
  ["~m_ex__zhonghui"] = "父亲，吾能自知。却终不能自制……",
}

General:new(extension, "m_ex__guohuai", "wei", 4):addSkills { "m_ex__jingce" }
Fk:loadTranslationTable{
  ["m_ex__guohuai"] = "界郭淮",
  ["#m_ex__guohuai"] = "垂问秦雍",
  ["illustrator:m_ex__guohuai"] = "游漫美绘",

  ["~m_ex__guohuai"] = "是我……轻敌了！",
}

General:new(extension, "m_ex__manchong", "wei", 3):addSkills { "m_ex__junxing", "yuce" }
Fk:loadTranslationTable{
  ["m_ex__manchong"] = "界满宠",
  ["#m_ex__manchong"] = "政法兵谋",
  ["designer:m_ex__manchong"] = "Loun老萌",
  ["illustrator:m_ex__manchong"] = "YanBai",

  ["$yuce_m_ex__manchong1"] = "骄之以利，示之以慑！",
  ["$yuce_m_ex__manchong2"] = "虽举得于外，则福生于内矣。",
  ["~m_ex__manchong"] = "宠一生为公，无愧忠俭之节。",
}

General:new(extension, "m_ex__jianyong", "shu", 3):addSkills { "m_ex__qiaoshui", "m_ex__zongshij" }
Fk:loadTranslationTable{
  ["m_ex__jianyong"] = "界简雍",
  ["#m_ex__jianyong"] = "悠游风议",
  ["illustrator:m_ex__jianyong"] = "zoo",

  ["~m_ex__jianyong"] = "行事无矩，为人所恶矣。",
}

General:new(extension, "m_ex__panzhangmazhong", "wu", 4):addSkills { "m_ex__duodao", "m_ex__anjian" }
Fk:loadTranslationTable{
  ["m_ex__panzhangmazhong"] = "界潘璋马忠",
  ["#m_ex__panzhangmazhong"] = "擒龙伏虎",
  ["illustrator:m_ex__panzhangmazhong"] = "凝聚永恒",
  ["~m_ex__panzhangmazhong"] = "埋伏得这么好，怎会……",
}

General:new(extension, "m_ex__yufan", "wu", 3):addSkills { "m_ex__zongxuan", "zhiyan" }
Fk:loadTranslationTable{
  ["m_ex__yufan"] = "界虞翻",
  ["#m_ex__yufan"] = "狂直之士",
  ["illustrator:m_ex__yufan"] = "YanBai",

  ["$zhiyan_m_ex__yufan1"] = "此事，将军请听我一言。",
  ["$zhiyan_m_ex__yufan2"] = "还望主公多斟酌一番。",
  ["~m_ex__yufan"] = "还是顺应天意吧！",
}

General:new(extension, "m_ex__zhuran", "wu", 4):addSkills { "m_ex__danshou" }
Fk:loadTranslationTable{
  ["m_ex__zhuran"] = "界朱然",
  ["#m_ex__zhuran"] = "不动之督",
  ["illustrator:m_ex__zhuran"] = "zoo",

  ["~m_ex__zhuran"] = "大耳贼就在眼前，快追……",
}

General:new(extension, "m_ex__fuhuanghou", "qun", 3, 3, General.Female):addSkills { "m_ex__zhuikong", "m_ex__qiuyuan" }
Fk:loadTranslationTable{
  ["m_ex__fuhuanghou"] = "界伏皇后",
  ["#m_ex__fuhuanghou"] = "孤注一掷",
  ["illustrator:m_ex__fuhuanghou"] = "zoo",
  ["~m_ex__fuhuanghou"] = "父亲大人，你竟如此优柔寡断……",
}

General:new(extension, "m_ex__liru", "qun", 3):addSkills { "m_ex__juece", "m_ex__mieji", "fencheng" }
Fk:loadTranslationTable{
  ["m_ex__liru"] = "界李儒",
  ["#m_ex__liru"] = "魔仕",
  ["illustrator:m_ex__liru"] = "三道纹",
  ["~m_ex__liru"] = "吾等皆死于妇人之手矣！",

  ["$fencheng_m_ex__liru1"] = "千里皇城，尽作焦土！",
  ["$fencheng_m_ex__liru2"] = "荣耀、权力、欲望、统统让这大火焚灭吧！",
}

General:new(extension, "m_ex__caozhen", "wei", 4):addSkills { "m_ex__sidi" }
Fk:loadTranslationTable{
  ["m_ex__caozhen"] = "界曹真",
  ["#m_ex__caozhen"] = "荷国天督",
  ["illustrator:m_ex__caozhen"] = "鬼画府",
  ["~m_ex__caozhen"] = "雍凉动乱，皆吾之过也……",
}

General:new(extension, "m_ex__chenqun", "wei", 3):addSkills { "m_ex__dingpin", "nos__faen" }
Fk:loadTranslationTable{
  ["m_ex__chenqun"] = "界陈群",
  ["#m_ex__chenqun"] = "万世臣表",
  ["illustrator:m_ex__chenqun"] = "鬼画府",
  ["~m_ex__chenqun"] = "立身纯且粹，一死复何忧……",

  ["$nos__faen_m_ex__chenqun1"] = "法不可容之事，情或能原宥。",
  ["$nos__faen_m_ex__chenqun2"] = "严刑峻法，万望慎行。",
}

General:new(extension, "m_ex__zhoucang", "shu", 4):addSkills { "m_ex__zhongyong" }
Fk:loadTranslationTable{
  ["m_ex__zhoucang"] = "界周仓",
  ["#m_ex__zhoucang"] = "披肝沥胆",
  ["illustrator:m_ex__zhoucang"] = "腥鱼仔",
  ["~m_ex__zhoucang"] = "九泉之下，仓陪将军再走一遭……",
}

General:new(extension, "m_ex__wuyi", "shu", 4):addSkills { "m_ex__benxi" }
Fk:loadTranslationTable{
  ["m_ex__wuyi"] = "界吴懿",
  ["#m_ex__wuyi"] = "建兴鞍辔",
  ["illustrator:m_ex__wuyi"] = "鬼画府",
  ["~m_ex__wuyi"] = "吾等虽不惧蜀道之险，却亦难过这渭水长安……",
}

General:new(extension, "m_ex__guyong", "wu", 3):addSkills { "m_ex__shenxing", "m_ex__bingyi" }
Fk:loadTranslationTable{
  ["m_ex__guyong"] = "界顾雍",
  ["#m_ex__guyong"] = "表疏忠言",
  ["illustrator:m_ex__guyong"] = "秋呆呆",
  ["~m_ex__guyong"] = "此番患疾，吾必不起……",
}

General:new(extension, "m_ex__sunluban", "wu", 3, 3, General.Female):addSkills { "m_ex__zenhui", "m_ex__jiaojin" }
Fk:loadTranslationTable{
  ["m_ex__sunluban"] = "界孙鲁班",
  ["#m_ex__sunluban"] = "为虎作伥",
  ["illustrator:m_ex__sunluban"] = "鬼画府",
  ["~m_ex__sunluban"] = "妹妹，姐姐是迫不得已……",
}

General:new(extension, "m_ex__zhuhuan", "wu", 4):addSkills { "fenli", "m_ex__pingkou" }
Fk:loadTranslationTable{
  ["m_ex__zhuhuan"] = "界朱桓",
  ["#m_ex__zhuhuan"] = "中洲拒天人",
  ["illustrator:m_ex__zhuhuan"] = "聚一工作室",
  ["~m_ex__zhuhuan"] = "为将不行前而为人下，非可生受之辱……",

  ["$fenli_m_ex__zhuhuan1"] = "为主制客，乃百战百胜之势。",
  ["$fenli_m_ex__zhuhuan2"] = "诸位且与我勠力一战，自可得胜。",
}

General:new(extension, "m_ex__caifuren", "qun", 3, 3, General.Female):addSkills { "m_ex__qieting", "xianzhou" }
Fk:loadTranslationTable{
  ["m_ex__caifuren"] = "界蔡夫人",
  ["#m_ex__caifuren"] = "襄江的蒲苇",
  ["illustrator:m_ex__caifuren"] = "漫想族",
  ["~m_ex__caifuren"] = "琮儿！啊啊……",

  ["$xianzhou_m_ex__caifuren1"] = "既是诸位之议，妾身复有何疑？",
  ["$xianzhou_m_ex__caifuren2"] = "我虽女流，亦知献州乃为长久之计。",
}

local jushou = General:new(extension, "m_ex__jvshou", "qun", 2, 3)
jushou.shield = 3
jushou:addSkills { "m_ex__jianying", "shibei" }
Fk:loadTranslationTable{
  ["m_ex__jvshou"] = "界沮授",
  ["#m_ex__jvshou"] = "监军谋国",
  ["illustrator:m_ex__jvshou"] = "鬼画府",
  ["~m_ex__jvshou"] = "授，无愧主公之恩……",

  ["$shibei_m_ex__jvshou1"] = "只有杀身士，绝无降曹夫！",
  ["$shibei_m_ex__jvshou2"] = "心向袁氏，绝无背离可言！",
}

General:new(extension, "m_ex__caoxiu", "wei", 4):addSkills { "qianju", "m_ex__qingxi" }
Fk:loadTranslationTable{
  ["m_ex__caoxiu"] = "界曹休",
  ["#m_ex__caoxiu"] = "龙光骐骥",
  ["illustrator:m_ex__caoxiu"] = "西国红云",

  ["~m_ex__caoxiu"] = "背发毒疮，恐不能效力了……",
}

General:new(extension, "m_ex__zhangyi", "shu", 4):addSkills { "m_ex__wurong", "shizhi" }
Fk:loadTranslationTable{
  ["m_ex__zhangyi"] = "界张嶷",
  ["#m_ex__zhangyi"] = "通壮逾古",
  ["illustrator:m_ex__zhangyi"] = "成都琥羽",

  ["~m_ex__zhangyi"] = "北伐未捷，臣定杀身以报陛下！",
}

General:new(extension, "m_ex__quancong", "wu", 4):addSkills { "m_ex__yaoming" }
Fk:loadTranslationTable{
  ["m_ex__quancong"] = "界全琮",
  ["#m_ex__quancong"] = "慕势耀族",
  ["illustrator:m_ex__quancong"] = "YanBai",

  ["~m_ex__quancong"] = "吾逐名如筑室道谋，而是用终不溃于成。",
}

General:new(extension, "m_ex__sunxiu", "wu", 3):addSkills { "m_ex__yanzhu", "m_ex__xingxue", "zhaofu" }
Fk:loadTranslationTable{
  ["m_ex__sunxiu"] = "界孙休",
  ["#m_ex__sunxiu"] = "弥殇的景君",
  ["illustrator:m_ex__sunxiu"] = "君桓文化",

  ["~m_ex__sunxiu"] = "不求外取城地，但保大吴永安……",
}

General:new(extension, "m_ex__zhuzhi", "wu", 4):addSkills { "m_ex__anguo" }
Fk:loadTranslationTable{
  ["m_ex__zhuzhi"] = "界朱治",
  ["#m_ex__zhuzhi"] = "功崇信重",
  ["illustrator:m_ex__zhuzhi"] = "凝聚永恒",

  ["~m_ex__zhuzhi"] = "臣辅孙氏三代之业，今年近古稀，死而无憾。",
}

General:new(extension, "mobile__zhongyao", "wei", 3):addSkills { "mobile__huomo", "mobile__zuoding" }
Fk:loadTranslationTable{
  ["mobile__zhongyao"] = "钟繇",
  ["#mobile__zhongyao"] = "正楷萧曹",
  ["illustrator:mobile__zhongyao"] = "鬼画府",

  ["~mobile__zhongyao"] = "士季，切不可自恃才智，误入歧途……",
}

General:new(extension, "mobile__xuezong", "wu", 3):addSkills { "mobile__funan", "mobile__jiexun" }
Fk:loadTranslationTable{
  ["mobile__xuezong"] = "薛综",
  ["#mobile__xuezong"] = "彬彬之玊",
  ["illustrator:mobile__xuezong"] = "zoo",

  ["~mobile__xuezong"] = "唉！屡出忠言，为何无人信我……",
}

General:new(extension, "mobile__jikang", "wei", 3):addSkills { "mobile__qingxian", "mobile__juexiang" }
Fk:loadTranslationTable{
  ["mobile__jikang"] = "嵇康",
  ["#mobile__jikang"] = "峻峰孤松",
  ["illustrator:mobile__jikang"] = "黑羽",

  ["~mobile__jikang"] = "琴声依旧，伴我长眠……",
}

return extension
