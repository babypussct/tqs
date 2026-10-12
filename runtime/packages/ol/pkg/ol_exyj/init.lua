local extension = Package:new("ol_exyj")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_exyj/skills")

Fk:loadTranslationTable{
  ["ol_exyj"] = "OL-界一将",
}

General:new(extension, "ol_ex__caozhi", "wei", 3):addSkills { "luoying", "ol_ex__jiushi" }
Fk:loadTranslationTable{
  ["ol_ex__caozhi"] = "界曹植",
  ["#ol_ex__caozhi"] = "酒虎诗龙",
  ["illustrator:ol_ex__caozhi"] = "君桓文化",

  ["$luoying_ol_ex__caozhi1"] = "绿蚁洗墨锋，入喉酒香浓。",
  ["$luoying_ol_ex__caozhi2"] = "新酒赋旧词，墨香正醉人。",
  ["~ol_ex__caozhi"] = "酒醉不知归路，唯见星河漫天。",
}

General:new(extension, "ol_ex__yujin", "wei", 4):addSkills { "ol_ex__zhenjun", "ol_ex__yizhong" }
Fk:loadTranslationTable{
  ["ol_ex__yujin"] = "界于禁",
  ["#ol_ex__yujin"] = "治法御人",

  ["~ol_ex__yujin"] = "这漫天大雨，终究是忘不掉吗？",
}

General:new(extension, "ol_ex__zhangchunhua", "wei", 3, 3, General.Female):addSkills { "jueqing", "shangshi", "jianmie" }
Fk:loadTranslationTable{
  ["ol_ex__zhangchunhua"] = "界张春华",
  ["#ol_ex__zhangchunhua"] = "翦草除根",
  ["illustrator:ol_ex__zhangchunhua"] = "君桓文化",

  ["$jueqing_ol_ex__zhangchunhua1"] = "情丝如雪，难当暖阳。",
  ["$jueqing_ol_ex__zhangchunhua2"] = "有情总被无情负，绝情方无软肋生。",
  ["$shangshi_ol_ex__zhangchunhua1"] = "伤我最深的，竟是你司马懿。",
  ["$shangshi_ol_ex__zhangchunhua2"] = "世间刀剑数万，何以情字伤人？",
  ["~ol_ex__zhangchunhua"] = "我不负懿，懿负我。",
}

General:new(extension, "ol_ex__fazheng", "shu", 3):addSkills { "ol_ex__xuanhuo", "ol_ex__enyuan" }
Fk:loadTranslationTable{
  ["ol_ex__fazheng"] = "界法正",
  ["#ol_ex__fazheng"] = "明理审事",
  ["illustrator:ol_ex__fazheng"] = "君桓文化",

  ["~ol_ex__fazheng"] = "孝直不忠，不能佑主公复汉室了……",
}

General:new(extension, "ol_ex__lingtong", "wu", 4):addSkills { "ol_ex__xuanfeng" }
Fk:loadTranslationTable{
  ["ol_ex__lingtong"] = "界凌统",
  ["#ol_ex__lingtong"] = "血涕津渚",
  ["designer:ol_ex__lingtong"] = "玄蝶既白",
  ["illustrator:ol_ex__lingtong"] = "君桓文化",

  ["~ol_ex__lingtong"] = "先……停一下吧……",
}

General:new(extension, "ol_ex__wuguotai", "wu", 3, 3, General.Female):addSkills { "ol_ex__ganlu", "ol_ex__buyi" }
Fk:loadTranslationTable{
  ["ol_ex__wuguotai"] = "界吴国太",
  ["#ol_ex__wuguotai"] = "慈怀瑾瑜",
  ["illustrator:ol_ex__wuguotai"] = "君桓文化",

  ["~ol_ex__wuguotai"] = "竖子，何以胞妹为饵乎？",
}

General:new(extension, "ol_ex__xusheng", "wu", 4):addSkills { "ol_ex__pojun" }
Fk:loadTranslationTable{
  ["ol_ex__xusheng"] = "界徐盛",
  ["#ol_ex__xusheng"] = "誓卫吴疆",
  ["illustrator:ol_ex__xusheng"] = "黯荧岛",

  ["~ol_ex__xusheng"] = "长江犹在，铁壁已残……",
}

General:new(extension, "ol_ex__gaoshun", "qun", 4):addSkills { "ol_ex__xianzhen", "ol_ex__jinjiu"}
Fk:loadTranslationTable{
  ["ol_ex__gaoshun"] = "界高顺",
  ["#ol_ex__gaoshun"] = "装精将肃",
  ["illustrator:ol_ex__gaoshun"] = "蛋费鸡丁",

  ["~ol_ex__gaoshun"] = "可叹主公知而不用啊！",
}

General:new(extension, "ol_ex__caozhang", "wei", 4):addSkills { "ol_ex__jiangchi" }
Fk:loadTranslationTable{
  ["ol_ex__caozhang"] = "界曹彰",
  ["#ol_ex__caozhang"] = "任城威王",
  ["designer:ol_ex__caozhang"] = "玄蝶既白",
  ["illustrator:ol_ex__caozhang"] = "枭瞳",

  ["~ol_ex__caozhang"] = "黄须儿，愧对父亲……",
}

General:new(extension, "ol_ex__wangyi", "wei", 3, 3, General.Female):addSkills { "ol_ex__zhenlie", "ol_ex__miji" }
Fk:loadTranslationTable{
  ["ol_ex__wangyi"] = "界王异",
  ["#ol_ex__wangyi"] = "翳月之夷光",

  ["~ol_ex__wangyi"] = "匹夫，还我儿命来！",
}

General:new(extension, "ol_ex__madai", "shu", 4):addSkills { "mashu", "ol_ex__qianxi" }
Fk:loadTranslationTable{
  ["ol_ex__madai"] = "界马岱",
  ["#ol_ex__madai"] = "狮宗继血",
  ["illustrator:ol_ex__madai"] = "曲面流动",

  ["~ol_ex__madai"] = "文……文长，君何兀自回头？",
}

General:new(extension, "ol_ex__liaohua", "shu", 4):addSkills { "ol_ex__dangxian", "ol_ex__fuli" }
Fk:loadTranslationTable{
  ["ol_ex__liaohua"] = "界廖化",
  ["#ol_ex__liaohua"] = "果敢刚直",
  ["illustrator:ol_ex__liaohua"] = "黯荧岛",

  ["~ol_ex__liaohua"] = "国破家亡，老卒死有余辜……",
}

General:new(extension, "ol_ex__guanxingzhangbao", "shu", 4):addSkills { "ol_ex__fuhun" }
Fk:loadTranslationTable{
  ["ol_ex__guanxingzhangbao"] = "界关兴张苞",
  ["#ol_ex__guanxingzhangbao"] = "父魂子魄",
  ["illustrator:ol_ex__guanxingzhangbao"] = "错落宇宙",

  ["$ex__wusheng_ol_ex__guanxingzhangbao"] = "水淹七军犹在目，今化陇上断后锋！",
  ["$ex__paoxiao_ol_ex__guanxingzhangbao"] = "当阳桥头雷未绝，祁山阵前再显威！",
  ["~ol_ex__guanxingzhangbao"] = "兴/苞死无碍，唯汉志长存！",
}

General:new(extension, "ol_ex__chengpu", "wu", 4):addSkills { "ol_ex__lihuo", "ol_ex__chunlao" }
Fk:loadTranslationTable{
  ["ol_ex__chengpu"] = "界程普",
  ["#ol_ex__chengpu"] = "兴王定霸",
  ["illustrator:ol_ex__chengpu"] = "monkey",

  ["~ol_ex__chengpu"] = "以暴讨贼，竟遭报应吗？",
}

General:new(extension, "ol_ex__bulianshi", "wu", 3, 3, General.Female):addSkills { "ol_ex__anxu", "ol_ex__zhuiyi" }
Fk:loadTranslationTable{
  ["ol_ex__bulianshi"] = "界步练师",
  ["#ol_ex__bulianshi"] = "淑懿宽惠",
  --["illustrator:ol_ex__bulianshi"] = "",

  ["~ol_ex__bulianshi"] = "朔风如解意，容易莫摧残……",
}

General:new(extension, "ol_ex__liubiao", "qun", 3):addSkills { "ol_ex__zishou", "ol_ex__zongshi" }
Fk:loadTranslationTable{
  ["ol_ex__liubiao"] = "界刘表",
  ["#ol_ex__liubiao"] = "儁才秀拔",
  ["illustrator:ol_ex__liubiao"] = "错落宇宙",

  ["~ol_ex__liubiao"] = "乱世无义，尽是失德之徒……",
}

General:new(extension, "ol_ex__zhonghui", "wei", 4):addSkills { "ol_ex__quanji", "ol_ex__zili" }
Fk:loadTranslationTable{
  ["ol_ex__zhonghui"] = "界钟会",
  --["#ol_ex__zhonghui"] = "",
  --["illustrator:ol_ex__zhonghui"] = "",

  ["~ol_ex__zhonghui"] = "",
}

General:new(extension, "ol_ex__caochong", "wei", 3):addSkills { "ol_ex__chengxiang", "ol_ex__renxin" }
Fk:loadTranslationTable{
  ["ol_ex__caochong"] = "界曹冲",
  ["#ol_ex__caochong"] = "聪察岐嶷",
  ["illustrator:ol_ex__caochong"] = "君桓文化",

  ["~ol_ex__caochong"] = "性慧早夭，为之奈何？",
}

General:new(extension, "ol_ex__guohuai", "wei", 4):addSkills { "ol_ex__jingce" }
Fk:loadTranslationTable{
  ["ol_ex__guohuai"] = "界郭淮",
  ["#ol_ex__guohuai"] = "临危济难",
  ["illustrator:ol_ex__guohuai"] = "鬼画府",

  ["~ol_ex__guohuai"] = "无五子，亦无淮也……",
}

General:new(extension, "ol_ex__guanping", "shu", 4):addSkills { "longyin", "jieyong" }
Fk:loadTranslationTable{
  ["ol_ex__guanping"] = "界关平",
  ["#ol_ex__guanping"] = "龙吟四海",
  --["illustrator:ol_ex__guanping"] = "",

  ["$longyin_ol_ex__guanping1"] = "鼠辈怎敢！",
  ["$longyin_ol_ex__guanping2"] = "吴狗何在？",
  ["~ol_ex__guanping"] = "父亲……",
}

General:new(extension, "ol_ex__jianyong", "shu", 3):addSkills { "ol_ex__qiaoshui", "zongshij" }
Fk:loadTranslationTable{
  ["ol_ex__jianyong"] = "界简雍",
  ["#ol_ex__jianyong"] = "简傲跌宕",
  ["illustrator:ol_ex__jianyong"] = "zoo",

  ["~ol_ex__jianyong"] = "行事无据，为人所误矣……",
}

General:new(extension, "ol_ex__liufeng", "shu", 4):addSkills { "ol_ex__xiansi", "qinling" }
Fk:loadTranslationTable{
  ["ol_ex__liufeng"] = "界刘封",
  --["#ol_ex__liufeng"] = "",
  --["illustrator:ol_ex__liufeng"] = "",

  ["~ol_ex__liufeng"] = "",
}

General:new(extension, "ol_ex__yufan", "wu", 3):addSkills { "ol_ex__zongxuan", "ol_ex__zhiyan" }
Fk:loadTranslationTable{
  ["ol_ex__yufan"] = "界虞翻",
  ["#ol_ex__yufan"] = "犯颜谏争",
  ["illustrator:ol_ex__yufan"] = "YanBai",

  ["~ol_ex__yufan"] = "彼皆死人，何语神仙？",
}

General:new(extension, "ol_ex__zhuran", "wu", 4):addSkills { "ol_ex__danshou" }
Fk:loadTranslationTable{
  ["ol_ex__zhuran"] = "界朱然",
  --["#ol_ex__zhuran"] = "",
  --["illustrator:ol_ex__zhuran"] = "",

  ["~ol_ex__zhuran"] = "",
}

General:new(extension, "ol_ex__fuhuanghou", "qun", 3, 3, General.Female):addSkills { "ol_ex__zhuikong", "ol_ex__qiuyuan" }
Fk:loadTranslationTable{
  ["ol_ex__fuhuanghou"] = "界伏皇后",
  ["#ol_ex__fuhuanghou"] = "巾帼拚生",
  ["illustrator:ol_ex__fuhuanghou"] = "黯荧岛",

  ["~ol_ex__fuhuanghou"] = "只恨邪风不静，不能杀了老贼……",
}

General:new(extension, "ol_ex__liru", "qun", 3):addSkills { "ol_ex__juece", "ol_ex__mieji", "ty_ex__fencheng" }
Fk:loadTranslationTable{
  ["ol_ex__liru"] = "界李儒",
  ["#ol_ex__liru"] = "坼地摧天",
  ["illustrator:ol_ex__liru"] = "君桓文化",

  ["$ty_ex__fencheng_ol_ex__liru1"] = "愿这火光，照亮董公西行之路！",
  ["$ty_ex__fencheng_ol_ex__liru2"] = "诸公且看，此火可戏天下诸侯否？",
  ["~ol_ex__liru"] = "火熄人亡，都结束了……",
}

General:new(extension, "ol_ex__zhangsong", "shu", 3):addSkills { "ol_ex__qiangzhi", "ol_ex__xiantu" }
Fk:loadTranslationTable{
  ["ol_ex__zhangsong"] = "界张松",
  ["#ol_ex__zhangsong"] = "跻路踌躇",
  --["illustrator:ol_ex__zhangsong"] = "",

  ["~ol_ex__zhangsong"] = "在下真是庄松啊！",
}

General:new(extension, "ol_ex__sunluban", "wu", 3, 3, General.Female):addSkills { "ol_ex__zenhui", "ol_ex__jiaojin" }
Fk:loadTranslationTable{
  ["ol_ex__sunluban"] = "界孙鲁班",
  ["#ol_ex__sunluban"] = "",
  --["illustrator:ol_ex__sunluban"] = "",

  ["~ol_ex__sunluban"] = "此皆熊、损所白，我实不知。",
}

General:new(extension, "ol_ex__zhuhuan", "wu", 4):addSkills { "ol_ex__fenli", "ol_ex__pingkou" }
Fk:loadTranslationTable{
  ["ol_ex__zhuhuan"] = "界朱桓",
  --["#ol_ex__zhuhuan"] = "",
  --["illustrator:ol_ex__zhuhuan"] = "",

  ["~ol_ex__zhuhuan"] = "",
}

General:new(extension, "ol_ex__caifuren", "qun", 3, 3, General.Female):addSkills { "ol_ex__qieting", "xianzhou" }
Fk:loadTranslationTable{
  ["ol_ex__caifuren"] = "界蔡夫人",
  ["#ol_ex__caifuren"] = "怙恩恃宠",
  ["illustrator:ol_ex__caifuren"] = "黯荧岛",

  ["$xianzhou_ol_ex__caifuren1"] = "今献州以降，请丞相善待我孤儿寡母。",
  ["$xianzhou_ol_ex__caifuren2"] = "我儿志短才疏，只求方寸之地安享富贵。",
  ["~ol_ex__caifuren"] = "这哪里是荆州，分明是黄泉……",
}

General:new(extension, "ol_ex__caoxiu", "wei", 4):addSkills { "ol_ex__qianju", "ol_ex__qingxi" }
Fk:loadTranslationTable{
  ["ol_ex__caoxiu"] = "界曹休",
  ["#ol_ex__caoxiu"] = "",
  --["illustrator:ol_ex__caoxiu"] = "",

  ["~ol_ex__caoxiu"] = "贾梁道，汝何迟也！",
}

General:new(extension, "ol_ex__xiahoushi", "shu", 3, 3, General.Female):addSkills { "ol_ex__qiaoshi", "ol_ex__yanyu" }
Fk:loadTranslationTable{
  ["ol_ex__xiahoushi"] = "界夏侯氏",
  ["#ol_ex__xiahoushi"] = "疾冲之恋",
  --["illustrator:ol_ex__xiahoushi"] = "",

  ["~ol_ex__xiahoushi"] = "好似听得，那日伐木丁声……",
}

General:new(extension, "ol_ex__quancong", "wu", 4):addSkills { "ol_ex__yaoming", "ol_ex__zhenshan" }
Fk:loadTranslationTable{
  ["ol_ex__quancong"] = "界全琮",
  ["#ol_ex__quancong"] = "其时声名",
  --["illustrator:ol_ex__quancong"] = "",

  ["~ol_ex__quancong"] = "",
}

General:new(extension, "ol_ex__guohuanghou", "wei", 3, 3, General.Female):addSkills { "ol_ex__jiaozhao", "ol_ex__danxin" }
Fk:loadTranslationTable{
  ["ol_ex__guohuanghou"] = "界郭皇后",
  ["#ol_ex__guohuanghou"] = "垂宪后叶",
  --["illustrator:ol_ex__guohuanghou"] = "",

  ["~ol_ex__guohuanghou"] = "五刑之罪，莫大于不孝。",
}

General:new(extension, "ol_ex__xinxianying", "wei", 3, 3, General.Female):addSkills { "ol_ex__caishi", "ol_ex__zhongjian" }
Fk:loadTranslationTable{
  ["ol_ex__xinxianying"] = "界辛宪英",
  ["#ol_ex__xinxianying"] = "镜鉴",
  --["illustrator:ol_ex__xinxianying"] = "",

  ["~ol_ex__xinxianying"] = "虽无文景之惠，后亦不至天下愍怀。",
}

General:new(extension, "ol_ex__caojie", "qun", 3, 3, General.Female):addSkills { "ol_ex__shouxi", "ol_ex__huimin" }
Fk:loadTranslationTable{
  ["ol_ex__caojie"] = "界曹节",
  ["#ol_ex__caojie"] = "澜江投珠",
  --["illustrator:ol_ex__caojie"] = "",

  ["~ol_ex__caojie"] = "父子溘然，此为天罚！",
}

return extension
