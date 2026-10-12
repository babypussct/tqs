local extension = Package:new("m_shzl_ex")
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/shzl_ex/skills")

Fk:loadTranslationTable{
  ["m_shzl_ex"] = "手杀-界限突破",
}

General:new(extension, "mobile__yuanshu", "qun", 4):addSkills { "mobile__wangzun", "mobile__tongji" }
Fk:loadTranslationTable{
  ["mobile__yuanshu"] = "袁术",
  ["#mobile__yuanshu"] = "野心渐增",
  ["illustrator:mobile__yuanshu"] = "叶子",

  ["~mobile__yuanshu"] = "嗯哼，没……没有蜜水了……",
}

General:new(extension, "m_ex__zhangfei", "shu", 4):addSkills { "os_ex__paoxiao", "liyong" }
Fk:loadTranslationTable{
  ["m_ex__zhangfei"] = "界张飞",
  ["#m_ex__zhangfei"] = "万夫不当",
  ["illustrator:m_ex__zhangfei"] = "木美人",

  ["$os_ex__paoxiao_m_ex__zhangfei1"] = "百万军中，看我取上将首级。",
  ["$os_ex__paoxiao_m_ex__zhangfei2"] = "丈八蛇矛在吾手，汝等害怕了吗？",
  ["~m_ex__zhangfei"] = "终是小人难防啊……",
}

General:new(extension, "m_ex__xiahoudun", "wei", 4):addSkills { "ex__ganglie", "m_ex__qingjian" }
Fk:loadTranslationTable{
  ["m_ex__xiahoudun"] = "界夏侯惇",
  ["#m_ex__xiahoudun"] = "独眼的罗刹",
  ["illustrator:m_ex__xiahoudun"] = "木美人",

  ["$ex__ganglie_m_ex__xiahoudun1"] = "壮情豪胆，小伤何惧！",
  ["$ex__ganglie_m_ex__xiahoudun2"] = "以命搏命，则敌，必怯矣！",
  ["~m_ex__xiahoudun"] = "独目残躯，不惧生死。",
}

General:new(extension, "m_ex__huatuo", "qun", 3):addSkills { "jijiu", "m_ex__qingnang" }
Fk:loadTranslationTable{
  ["m_ex__huatuo"] = "界华佗",
  ["#m_ex__huatuo"] = "神医",
  ["illustrator:m_ex__huatuo"] = "刘小狼Syaoran",

  ["$jijiu_m_ex__huatuo1"] = "救死扶伤，悬壶济世。",
  ["$jijiu_m_ex__huatuo2"] = "妙手仁心，药到病除。",
  ["~m_ex__huatuo"] = "生老病死，命不可违。",
}

General:new(extension, "m_ex__yuanshu", "qun", 4):addSkills { "m_ex__yongsi", "jixiy" }
Fk:loadTranslationTable{
  ["m_ex__yuanshu"] = "界袁术",
  ["#m_ex__yuanshu"] = "仲家帝",
  ["illustrator:m_ex__yuanshu"] = "魔奇士",

  ["$mobile__wangzun_m_ex__yuanshu1"] = "四世三公算什么？朕乃九五至尊！",
  ["$mobile__wangzun_m_ex__yuanshu2"] = "追随我的人，都是开国元勋！",
  ["~m_ex__yuanshu"] = "朕，要千秋万代……",
}

General:new(extension, "m_ex__weiyan", "shu", 4):addSkills { "ol_ex__kuanggu", "m_ex__qimou" }
Fk:loadTranslationTable{
  ["m_ex__weiyan"] = "界魏延",
  ["#m_ex__weiyan"] = "嗜血的独狼",
  ["illustrator:m_ex__weiyan"] = "瞌瞌一休",

  ["$ol_ex__kuanggu_m_ex__weiyan1"] = "狂骨凛然，何必与他人为伍。",
  ["$ol_ex__kuanggu_m_ex__weiyan2"] = "汉中之地，有我一人足矣。",
  ["~m_ex__weiyan"] = "汝，且勿为杨仪奸计所蔽……呃啊！",
}

General:new(extension, "m_ex__xiaoqiao", "wu", 3, 3, General.Female):addSkills { "m_ex__tianxiang", "mou__hongyan" }
Fk:loadTranslationTable{
  ["m_ex__xiaoqiao"] = "界小乔",
  ["#m_ex__xiaoqiao"] = "矫情之花",
  ["illustrator:m_ex__xiaoqiao"] = "凝聚永恒",

  ["~m_ex__xiaoqiao"] = "周郎，等我。",
}

General:new(extension, "m_ex__zhoutai", "wu", 4):addSkills { "ol__buqu", "m_ex__fenji" }
Fk:loadTranslationTable{
  ["m_ex__zhoutai"] = "界周泰",
  ["#m_ex__zhoutai"] = "历战之躯",
  ["illustrator:m_ex__zhoutai"] = "魔奇士",

  ["$ol__buqu_m_ex__zhoutai1"] = "力战之躯，岂能倒下。",
  ["$ol__buqu_m_ex__zhoutai2"] = "休想过我这关。",
  ["~m_ex__zhoutai"] = "这点，小伤……",
}

General:new(extension, "m_ex__zhangjiao", "qun", 3):addSkills { "ex__leiji", "guidao", "huangtian" }
Fk:loadTranslationTable{
  ["m_ex__zhangjiao"] = "界张角",
  ["#m_ex__zhangjiao"] = "大贤良师",
  ["illustrator:m_ex__zhangjiao"] = "LiuHeng",

  ["$guidao_m_ex__zhangjiao1"] = "道势所向，皆由我控。",
  ["$guidao_m_ex__zhangjiao2"] = "哼哼，天意如此！",
  ["$huangtian_m_ex__zhangjiao1"] = "苍天不复，黄天将替！",
  ["$huangtian_m_ex__zhangjiao2"] = "黄天立，民心顺，天下平！",
  ["~m_ex__zhangjiao"] = "黄天既覆，苍生何存……",
}

General:new(extension, "m_ex__yuji", "qun", 3):addSkills { "m_ex__guhuo" }
Fk:loadTranslationTable{
  ["m_ex__yuji"] = "界于吉",
  ["#m_ex__yuji"] = "太平道人",
  ["illustrator:m_ex__yuji"] = "魔鬼鱼",

  ["~m_ex__yuji"] = "道法玄机，竟被参破……",
}

General:new(extension, "m_ex__dianwei", "wei", 4):addSkills { "m_ex__qiangxi" }
Fk:loadTranslationTable{
  ["m_ex__dianwei"] = "界典韦",
  ["#m_ex__dianwei"] = "古之恶来",
  ["illustrator:m_ex__dianwei"] = "凝聚永恒",

  ["~m_ex__dianwei"] = "汝等小儿，竟敢害我！拿命来！",
}

General:new(extension, "m_ex__xunyu", "wei", 3):addSkills { "quhu", "m_ex__jieming" }
Fk:loadTranslationTable{
  ["m_ex__xunyu"] = "界荀彧",
  ["#m_ex__xunyu"] = "王佐之才",
  ["illustrator:m_ex__xunyu"] = "青岛磐蒲",

  ["$quhu_m_ex__xunyu1"] = "驱虎伤敌，保我无虞。",
  ["$quhu_m_ex__xunyu2"] = "无需费我一兵一卒。",
  ["~m_ex__xunyu"] = "命不由人，徒叹奈何……",
}

General:new(extension, "m_ex__wolong", "shu", 3):addSkills { "bazhen", "m_ex__huoji", "m_ex__kanpo" }
Fk:loadTranslationTable{
  ["m_ex__wolong"] = "界卧龙诸葛亮",
  ["#m_ex__wolong"] = "卧龙",
  ["illustrator:m_ex__wolong"] = "YanBai",

  ["~m_ex__wolong"] = "我的计谋竟被……",
}

General:new(extension, "m_ex__pangtong", "shu", 3):addSkills { "m_ex__lianhuan", "m_ex__niepan" }
Fk:loadTranslationTable{
  ["m_ex__pangtong"] = "界庞统",
  ["#m_ex__pangtong"] = "凤雏",
  ["illustrator:m_ex__pangtong"] = "青岛磐蒲",

  ["~m_ex__pangtong"] = "落……凤……坡……",
}

General:new(extension, "m_ex__pangde", "qun", 4):addSkills { "mashu", "m_ex__jianchu" }
Fk:loadTranslationTable{
  ["m_ex__pangde"] = "界庞德",
  ["#m_ex__pangde"] = "周苛之节",
  ["illustrator:m_ex__pangde"] = "凝聚永恒",

  ["~m_ex__pangde"] = "我宁为国家鬼，不为贼将也！",
}

General:new(extension, "m_ex__yanliangwenchou", "qun", 4):addSkills { "m_ex__shuangxiong" }
Fk:loadTranslationTable{
  ["m_ex__yanliangwenchou"] = "界颜良文丑",
  ["#m_ex__yanliangwenchou"] = "虎狼兄弟",
  ["illustrator:m_ex__yanliangwenchou"] = "凝聚永恒",

  ["~m_ex__yanliangwenchou"] = "不是叫你看好我身后吗……",
}

General:new(extension, "m_ex__yuanshao", "qun", 4):addSkills { "m_ex__luanji", "xueyi" }
Fk:loadTranslationTable{
  ["m_ex__yuanshao"] = "界袁绍",
  ["#m_ex__yuanshao"] = "高贵的名门",
  ["illustrator:m_ex__yuanshao"] = "17号工坊",

  ["$xueyi_m_ex__yuanshao1"] = "名门思召，朝野敬仰。",
  ["$xueyi_m_ex__yuanshao2"] = "吾乃名门望族，岂能与汝等为伍？",
  ["~m_ex__yuanshao"] = "袁门不幸啊……",
}

General:new(extension, "m_ex__xuhuang", "wei", 4):addSkills { "m_ex__duanliang", "m_ex__jiezi" }
Fk:loadTranslationTable{
  ["m_ex__xuhuang"] = "界徐晃",
  ["#m_ex__xuhuang"] = "周亚夫之风",
  ["illustrator:m_ex__xuhuang"] = "波子",

  ["~m_ex__xuhuang"] = "敌军防备周全，是吾轻敌……",
}

General:new(extension, "m_ex__caopi", "wei", 3):addSkills { "m_ex__xingshang", "m_ex__fangzhu", "songwei" }
Fk:loadTranslationTable{
  ["m_ex__caopi"] = "界曹丕",
  ["#m_ex__caopi"] = "霸业的继承者",
  ["illustrator:m_ex__caopi"] = "YanBai",

  ["$songwei_m_ex__caopi1"] = "藩屏大宗，御侮厌难。",
  ["$songwei_m_ex__caopi2"] = "朕承符运，终受革命。",
  ["~m_ex__caopi"] = "建平所言八十，谓昼夜也，吾其决矣……",
}

General:new(extension, "m_ex__sunjian", "wu", 4):addSkills { "yinghun", "polus" }
Fk:loadTranslationTable{
  ["m_ex__sunjian"] = "界孙坚",
  ["#m_ex__sunjian"] = "武烈帝",
  ["illustrator:m_ex__sunjian"] = "漫想族",

  ["$yinghun_m_ex__sunjian1"] = "义定四野，武匡海内。",
  ["$yinghun_m_ex__sunjian2"] = "江东男儿，皆胸怀匡扶天下之志。",
  ["~m_ex__sunjian"] = "吾身虽死，忠勇须传。",
}

General:new(extension, "m_ex__dengai", "wei", 4):addSkills { "m_ex__tuntian", "zaoxian" }
Fk:loadTranslationTable{
  ["m_ex__dengai"] = "界邓艾",
  ["#m_ex__dengai"] = "矫然的壮士",
  ["illustrator:m_ex__dengai"] = "凝聚永恒",

  ["$zaoxian_m_ex__dengai1"] = "用兵以险，则战之以胜！",
  ["$zaoxian_m_ex__dengai2"] = "已至马阁山，宜速进军破蜀！",
  ["$jixi_m_ex__dengai1"] = "攻敌之不备，斩将夺辎！",
  ["$jixi_m_ex__dengai2"] = "奇兵正攻，敌何能为？",
  ["~m_ex__dengai"] = "一片忠心，换来这般田地。",
}

General:new(extension, "m_ex__jiangwei", "shu", 4):addSkills { "m_ex__tiaoxin", "m_ex__zhiji" }
Fk:loadTranslationTable{
  ["m_ex__jiangwei"] = "界姜维",
  ["#m_ex__jiangwei"] = "龙的衣钵",
  ["illustrator:m_ex__jiangwei"] = "石蝉",

  ["$ex__guanxing_m_ex__jiangwei1"] = "知天易则观之，逆天难亦行之。",
  ["$ex__guanxing_m_ex__jiangwei2"] = "欲尽人事，亦先听天命。",
  ["~m_ex__jiangwei"] = "可惜大计未成，吾已身陨。",
}

General:new(extension, "m_ex__liushan", "shu", 3):addSkills { "xiangle", "m_ex__fangquan", "ruoyu" }
Fk:loadTranslationTable{
  ["m_ex__liushan"] = "界刘禅",
  ["#m_ex__liushan"] = "无为的真命主",
  ["illustrator:m_ex__liushan"] = "绘聚艺堂",

  ["$xiangle_m_ex__liushan1"] = "天府之国，自然民安国泰。",
  ["$xiangle_m_ex__liushan2"] = "战事扰乱民生，不如作罢。",
  ["$ruoyu_m_ex__liushan1"] = "唯有自认庸主之名，方能保蜀地官民无虞啊。",
  ["$ruoyu_m_ex__liushan2"] = "既无争雄天下之才，只好做守成之主。",
  ["$jijiang_m_ex__liushan1"] = "还望诸卿勠力同心，以保国祚。",
  ["$jijiang_m_ex__liushan2"] = "哪位爱卿愿意报效国家？",
  ["~m_ex__liushan"] = "实在有愧父皇与相父啊……",
}

General:new(extension, "m_ex__sunce", "wu", 4):addSkills { "jiang", "m_ex__hunzi", "zhiba" }
Fk:loadTranslationTable{
  ["m_ex__sunce"] = "界孙策",
  ["#m_ex__sunce"] = "江东的小霸王",
  ["illustrator:m_ex__sunce"] = "凝聚永恒",

  ["$jiang_m_ex__sunce1"] = "我会把胜利带回江东。",
  ["$jiang_m_ex__sunce2"] = "天下英雄，谁能与我一战？",
  ["$zhiba_m_ex__sunce1"] = "我的霸业才刚刚开始。",
  ["$zhiba_m_ex__sunce2"] = "汝是战是降，我皆奉陪。",
  ["$ex__yingzi_m_ex__sunce1"] = "有公瑾助我，可平天下。",
  ["$ex__yingzi_m_ex__sunce2"] = "所到之处，战无不胜。",
  ["$yinghun_m_ex__sunce1"] = "武烈之魂，助我扬名。",
  ["$yinghun_m_ex__sunce2"] = "江东之主，众望所归。",
  ["~m_ex__sunce"] = "大业未就，中世而殒……",
}

General:new(extension, "m_ex__zhangzhaozhanghong", "wu", 3):addSkills { "m_ex__zhijian", "guzheng" }
Fk:loadTranslationTable{
  ["m_ex__zhangzhaozhanghong"] = "界张昭张纮",
  ["#m_ex__zhangzhaozhanghong"] = "经天纬地",
  ["illustrator:m_ex__zhangzhaozhanghong"] = "绘聚艺堂",

  ["$guzheng_m_ex__zhangzhaozhanghong1"] = "为君者，不可肆兴土木，奢费物力。",
  ["$guzheng_m_ex__zhangzhaozhanghong2"] = "安民固国，方可思动。",
  ["~m_ex__zhangzhaozhanghong"] = "只恨不能为东吴百姓再谋一日福祉……",
}

General:new(extension, "m_ex__caiwenji", "qun", 3, 3, General.Female):addSkills { "m_ex__beige", "duanchang" }
Fk:loadTranslationTable{
  ["m_ex__caiwenji"] = "界蔡文姬",
  ["#m_ex__caiwenji"] = "异乡的孤女",
  ["illustrator:m_ex__caiwenji"] = "青学",

  ["$duanchang_m_ex__caiwenji1"] = "雁飞高兮邈难寻，空断肠兮思愔愔。",
  ["$duanchang_m_ex__caiwenji2"] = "为天有眼兮，何不见我独飘流？",
  ["~m_ex__caiwenji"] = "今别子兮归故乡，旧怨平兮新怨长！",
}

General:new(extension, "m_ex__wangji", "wei", 3):addSkills { "m_ex__qizhi", "m_ex__jinqu" }
Fk:loadTranslationTable{
  ["m_ex__wangji"] = "界王基",
  ["#m_ex__wangji"] = "学行坚白",
  --["illustrator:m_ex__wangji"] = "",

  ["~m_ex__wangji"] = "此生学行坚白，已无愧己身……",
}

local yanyan = General:new(extension, "m_ex__yanyan", "qun", 4)
yanyan.subkingdom = "shu"
yanyan:addSkills { "m_ex__juzhan" }
Fk:loadTranslationTable{
  ["m_ex__yanyan"] = "界严颜",
  ["#m_ex__yanyan"] = "皎日震邦",
  --["illustrator:m_ex__yanyan"] = "",

  ["~m_ex__yanyan"] = "颜念将军仁义，愿为大汉献身！",
}

General:new(extension, "m_ex__zhoufei", "wu", 3, 3, General.Female):addSkills { "m_ex__liangyin", "m_ex__kongsheng" }
Fk:loadTranslationTable{
  ["m_ex__zhoufei"] = "界周妃",
  ["#m_ex__zhoufei"] = "舫玉游鸾",
  --["illustrator:m_ex__zhoufei"] = "",

  ["~m_ex__zhoufei"] = "相思相见知何日，此时此夜难为情。",
}

return extension
