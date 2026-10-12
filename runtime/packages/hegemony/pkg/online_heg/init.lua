local extension = Package:new("online_heg")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/online_heg/skills")

Fk:loadTranslationTable{
  ["online_heg"] = "国战-OL专属",
  ["ol_heg"] = "OL国战",
  ["ol_ex_heg"] = "OL国战",
  ["#heg_swap_deputy"] = "%from 与 %to 交换了副将",
  ["heg__yiwei"] = "易位：发起武将易位后，若目标角色选择执行，则易位双方交换对应武将。<br>"..
  "一名角色只能对相同势力的其他角色发起武将易位。易位武将不会影响你的体力上限，也不会获得珠联璧合、阴阳鱼标记。"..
  "易位武将不会移除武将牌上的牌，如“屯田”等，也不会影响技能状态，比如限定技、每回合限一次、断肠、铁骑等。",
}

local generals = {}  --绕过变量上限的东西

General:new(extension, "ol_heg__hetaihou", "qun", 3, 3, General.Female):addSkills{ "ol__zhendu", "ol__qiluan" }
Fk:loadTranslationTable{
  ["ol_heg__hetaihou"] = "何太后",
  ["#ol_heg__hetaihou"] = "弄权之蛇蝎",
  ["illustrator:ol_heg__hetaihou"] = "琛·美弟奇",

  ["~ol_heg__hetaihou"] = "扰乱朝堂之事，我怎么会做……",
}

General:new(extension, "ol_heg__bianfuren", "wei", 3, 3, General.Female):addSkills{ "ol__wanwei", "nos_heg__yuejian" }
Fk:loadTranslationTable{
  ["ol_heg__bianfuren"] = "卞夫人",
  ["#ol_heg__bianfuren"] = "奕世之雍容",
  ["illustrator:ol_heg__bianfuren"] = "凡果",

  ["~ol_heg__bianfuren"] = "",
}

General:new(extension, "ol_heg__zhangchunhua", "jin", 3, 3, General.Female):addSkills{ "ol__huishi", "qingleng" }
Fk:loadTranslationTable{
  ["ol_heg__zhangchunhua"] = "张春华",
  ["#ol_heg__zhangchunhua"] = "宣穆皇后",
  ["illustrator:ol_heg__zhangchunhua"] = "biou09",

  ["~ol_heg__zhangchunhua"] = "冷眸残情，孤苦为一人。",
}

generals.ol_heg__simayi = General:new(extension, "ol_heg__simayi", "jin", 3)
generals.ol_heg__simayi:addCompanions({ "ol_heg__zhangchunhua", "ol_heg__shibao", "heg__zhangchunhua" })
generals.ol_heg__simayi:addSkills { "yingshis", "xiongzhi", "quanbian" }
Fk:loadTranslationTable{
  ["ol_heg__simayi"] = "司马懿",
  ["#ol_heg__simayi"] = "通权达变",
  ["illustrator:ol_heg__simayi"] = "biou09",

  ["~ol_heg__simayi"] = "虎入骷冢，司马难兴。",
}

General:new(extension, "ol_heg__yanghuiyu", "jin", 3, 3, General.Female):addSkills{ "ciwei", "caiyuan" }
Fk:loadTranslationTable{
  ["ol_heg__yanghuiyu"] = "羊徽瑜",
  ["#ol_heg__yanghuiyu"] = "景献皇后",
  ["illustrator:ol_heg__yanghuiyu"] = "depp",

  ["~ol_heg__yanghuiyu"] = "韶华易老，佳容不再……",
}

generals.ol_heg__simashi = General:new(extension, "ol_heg__simashi", "jin", 3)
generals.ol_heg__simashi:addCompanions({ "ol_heg__xiahouhui", "ol_heg__yanghuiyu" })
generals.ol_heg__simashi:addSkills{ "yimie", "tairan" }
Fk:loadTranslationTable{
  ["ol_heg__simashi"] = "司马师",
  ["#ol_heg__simashi"] = "晋景王",
  ["illustrator:ol_heg__simashi"] = "凝聚永恒",

  ["~ol_heg__simashi"] = "子上，这是为兄给你打下的江山……",
}

General:new(extension, "ol_heg__xiahouhui", "jin", 3, 3, General.Female):addSkills{ "yishi", "shidu" }
Fk:loadTranslationTable{
  ["ol_heg__xiahouhui"] = "夏侯徽",
  ["#ol_heg__xiahouhui"] = "景怀皇后",
  ["illustrator:ol_heg__xiahouhui"] = "凝聚永恒",

  ["~ol_heg__xiahouhui"] = "夫君，你怎么对我如此狠心……",
}

generals.ol_heg__simazhao = General:new(extension, "ol_heg__simazhao", "jin", 3)
generals.ol_heg__simazhao:addCompanions{ "ol_heg__wangyuanji", "heg__wangyuanji" }
generals.ol_heg__simazhao:addSkills { "choufa", "zhaoran" }
Fk:loadTranslationTable{
  ["ol_heg__simazhao"] = "司马昭",
  ["#ol_heg__simazhao"] = "晋文帝",
  ["illustrator:ol_heg__simazhao"] = "凝聚永恒",

  ["~ol_heg__simazhao"] = "司马三代，一梦成空……",
}

General:new(extension, "ol_heg__wangyuanji", "jin", 3, 3, General.Female):addSkills{ "yanxi" }
Fk:loadTranslationTable{
  ["ol_heg__wangyuanji"] = "王元姬",
  ["#ol_heg__wangyuanji"] = "文明皇后",
  ["illustrator:ol_heg__wangyuanji"] = "凝聚永恒",

  ["~ol_heg__wangyuanji"] = "祖父已逝，哀凄悲戚。",
}

General:new(extension, "ol_heg__duyu", "jin", 4):addSkills{ "ol_heg__sanchen" }
Fk:loadTranslationTable{
  ["ol_heg__duyu"] = "杜预",
  ["#ol_heg__duyu"] = "文成武德",
  ["illustrator:ol_heg__duyu"] = "一串糖葫芦",

  ["$pozhu_ol_heg__duyu1"] = "时机已至，当奋破竹之势，一举得胜！",
  ["$pozhu_ol_heg__duyu2"] = "兵威已振，应如以刀劈竹，迎刃而解！",
  ["~ol_heg__duyu"] = "佳人已去，幽梦犹存。",
}

General:new(extension, "ol_heg__shibao", "jin", 4):addSkills{ "ol_heg__zhuosheng" }
Fk:loadTranslationTable{
  ["ol_heg__shibao"] = "石苞",
  ["#ol_heg__shibao"] = "乐陵郡公",
  ["illustrator:ol_heg__shibao"] = "凡果",

  ["~ol_heg__shibao"] = "寒门出身，难以擢升。",
}

General:new(extension, "ol_heg__simazhou", "jin", 4):addSkills{ "ol_heg__caiwang", "naxiang" }
Fk:loadTranslationTable{
  ["ol_heg__simazhou"] = "司马伷",
  ["#ol_heg__simazhou"] = "琅琊武王",
  ["illustrator:ol_heg__simazhou"] = "西国红云",

  ["~ol_heg__simazhou"] = "恩赐重物，病身难消受……",
}

General:new(extension, "ol_heg__zhanghuyuechen", "jin", 4):addSkills{ "ol_heg__xijue" }
Fk:loadTranslationTable{
  ["ol_heg__zhanghuyuechen"] = "张虎乐綝",
  ["#ol_heg__zhanghuyuechen"] = "不辱门庭",
  ["illustrator:ol_heg__zhanghuyuechen"] = "妙喵",

  ["$ex__tuxi_ol_heg__zhanghuyuechen1"] = "动如霹雳，威震宵小！",
  ["$ex__tuxi_ol_heg__zhanghuyuechen2"] = "行略如风，摧枯拉朽！",
  ["$nos__xiaoguo_ol_heg__zhanghuyuechen1"] = "大丈夫生于世，当沙场效忠！",
  ["$nos__xiaoguo_ol_heg__zhanghuyuechen2"] = "骁勇善战，刚毅果断！",
  ["~ol_heg__zhanghuyuechen"] = "儿有辱……父亲威名……",
}

--他山之石
General:new(extension, "ol_heg__wangrongh", "qun", 3, 3, General.Female):addSkills{ "fengzi", "jizhan", "fusong" }
Fk:loadTranslationTable{
  ["ol_heg__wangrongh"] = "王荣",
  ["#ol_heg__wangrongh"] = "灵怀皇后",
  ["illustrator:ol_heg__wangrongh"] = "君桓文化",

  ["~ol_heg__wangrongh"] = "只求吾儿，一生平安……",
}

generals.ol_ex_heg__xusheng = General:new(extension, "ol_ex_heg__xusheng", "wu", 4)
generals.ol_ex_heg__xusheng:addCompanions("hs__dingfeng")
generals.ol_ex_heg__xusheng:addSkills{ "ol_ex__pojun" }
Fk:loadTranslationTable{
  ["ol_ex_heg__xusheng"] = "界徐盛",
  ["#ol_ex_heg__xusheng"] = "誓卫吴疆",
  ["illustrator:ol_ex_heg__xusheng"] = "黯荧岛",

  ["~ol_ex_heg__xusheng"] = "长江犹在，铁壁已残……",
}

generals.ol_ex_heg__lvbu = General:new(extension, "ol_ex_heg__lvbu", "qun", 5)
generals.ol_ex_heg__lvbu:addCompanions("hs__diaochan")
generals.ol_ex_heg__lvbu:addSkills{ "wushuang", "liyu" }
Fk:loadTranslationTable{
  ["ol_ex_heg__lvbu"] = "界吕布",
  ["#ol_ex_heg__lvbu"] = "武的化身",
  ["cv:ol_ex_heg__lvbu"] = "金垚",
  ["illustrator:ol_ex_heg__lvbu"] = "张帅",

  ["$wushuang_ol_ex_heg__lvbu1"] = "还有哪个敢挑战我！？",
  ["$wushuang_ol_ex_heg__lvbu2"] = "三个齐上，也不是我的对手！",
  ["~ol_ex_heg__lvbu"] = "我竟然输了……不可能！",
}

General:new(extension, "ol_ex_heg__taishici", "wu", 4):addSkills{ "tianyi", "hanzhan" }
Fk:loadTranslationTable{
  ["ol_ex_heg__taishici"] = "界太史慈",
  ["#ol_ex_heg__taishici"] = "信义笃烈",
  ["illustrator:ol_ex_heg__taishici"] = "biou09",

  ["$tianyi_ol_ex_heg__taishici1"] = "天降大任，速战解围！",
  ["$tianyi_ol_ex_heg__taishici2"] = "义不从之，天必不佑！",
  ["~ol_ex_heg__taishici"] = "无妄之灾，难以避免……",
}

General:new(extension, "ol_heg__mayunlu", "shu", 4, 4, General.Female):addSkills{ "ol_heg__mayunlu__mashu", "fengpo" }
Fk:loadTranslationTable{
  ["ol_heg__mayunlu"] = "马云騄",
  ["#ol_heg__mayunlu"] = "剑胆琴心",
  ["cv:ol_heg__mayunlu"] = "水原",
  ["illustrator:ol_heg__mayunlu"] = "木美人",

  ["~ol_heg__mayunlu"] = "呜呜……是你们欺负人……",
}

General:new(extension, "ol_heg__luzhiw", "wei", 3):addSkills { "qingzhong", "weijing" }
Fk:loadTranslationTable{
  ["ol_heg__luzhiw"] = "鲁芝",
  ["#ol_heg__luzhiw"] = "夷夏慕德",
  ["designer:ol_heg__luzhiw"] = "世外高v狼",
  ["illustrator:ol_heg__luzhiw"] = "秋呆呆",

  ["~ol_heg__luzhiw"] = "年迈力微，是该告老还乡了……",
}

--礼
generals.ol_heg__chengpu = General:new(extension, "ol_heg__chengpu", "wu", 4)
generals.ol_heg__chengpu:addCompanions{ "hs__zhouyu", "hs__huanggai" }
generals.ol_heg__chengpu:addSkills{ "ol_heg__daohuo","ol_heg__chunlao" }
Fk:loadTranslationTable{
  ["ol_heg__chengpu"] = "程普",
  ["#ol_heg__chengpu"] = "三朝虎臣",
  --["illustrator:ol_heg__chengpu"] = "",

  ["~ol_heg__chengpu"] = "没，没有酒了……",
}

General:new(extension, "ol_heg__sunjun", "wu", 4):addSkills{ "ol_heg__suchao", "ol_heg__zhulian" }
Fk:loadTranslationTable {
  ["ol_heg__sunjun"] = "孙峻",
  --["#ol_heg__sunjun"] = "",
  --["illustrator:ol_heg__sunjun"] = "",
  ["designer:ol_heg__sunjun"] = "紫髯的小乔",

  ["~ol_heg__sunjun"] = "最后，只能是故氏吗？",
}

Fk:loadTranslationTable {
  ["ol_heg__gaotanglong"] = "高堂隆",
  --["#ol_heg__gaotanglong"] = "",
  --["illustrator:ol_heg__gaotanglong"] = "",

  ["~ol_heg__gaotanglong"] = "",
}

--谦
General:new(extension, "ol_heg__xuyou", "qun", 3):addSkills { "ol_heg__chenglue", "ol_heg__fushi" }
Fk:loadTranslationTable {
  ["ol_heg__xuyou"] = "许攸",
  ["#ol_heg__xuyou"] = "朝秦暮楚",
  --["cv:ol_heg__xuyou"] = "",
  --["illustrator:ol_heg__xuyou"] = "",

  ["~ol_heg__xuyou"] = "阿瞒，没有我你得不到冀州啊！",
}

General:new(extension, "ol_heg__jianshuo", "qun", 4):addSkills{ "ol_heg__shantong", "ol_heg__qunchou" }
Fk:loadTranslationTable {
  ["ol_heg__jianshuo"] = "蹇硕",
  --["#ol_heg__jianshuo"] = "",
  --["illustrator:ol_heg__jianshuo"] = "",

  ["~ol_heg__jianshuo"] = "我死无妨，唯愧董侯……",
}

Fk:loadTranslationTable {
  ["ol_heg__guoyouzhi"] = "郭攸之",
  --["#ol_heg__guoyouzhi"] = "",
  --["illustrator:ol_heg__guoyouzhi"] = "",

  ["~ol_heg__guoyouzhi"] = "",
}

--辞
generals.ol_heg__wuyi = General:new(extension, "ol_heg__wuyi", "shu", 4)
generals.ol_heg__wuyi:addCompanions("hs__weiyan")
generals.ol_heg__wuyi:addSkills{ "ol_heg__benxi", "ol_heg__zhuanzheng"}
Fk:loadTranslationTable{
  ["ol_heg__wuyi"] = "吴懿",
  ["#ol_heg__wuyi"] = "建兴鞍辔",
  ["illustrator:ol_heg__wuyi"] = "官方",

  ["~ol_heg__wuyi"] = "奔波已疲，难以，再战。",
}

generals.ol_heg__caozhi = General:new(extension, "ol_heg__caozhi", "wei", 3)
generals.ol_heg__caozhi:addCompanions("hs__caopi")
generals.ol_heg__caozhi:addSkills{ "ol_heg__jiushi", "ol_heg__zongpei" }
Fk:loadTranslationTable{
  ["ol_heg__caozhi"] = "曹植",
  --["#ol_heg__caozhi"] = "",
  --["illustrator:ol_heg__caozhi"] = "",

  ["~ol_heg__caozhi"] = "",
}

Fk:loadTranslationTable {
  ["ol_heg__sunluban"] = "孙鲁班",
  --["#ol_heg__sunluban"] = "",
  --["illustrator:ol_heg__sunluban"] = "",

  ["~ol_heg__sunluban"] = "",
}

--诈
generals.ol_heg__zhonghui = General:new(extension, "ol_heg__zhonghui", "wei", 4)
generals.ol_heg__zhonghui.mainMaxHpAdjustedValue = -1
generals.ol_heg__zhonghui:addSkills{ "ol_heg__quanji", "ol_heg__paiyi", "ol_heg__yaopan" }
Fk:loadTranslationTable{
  ["ol_heg__zhonghui"] = "钟会",
  ["#ol_heg__zhonghui"] = "桀骜的野心家",
  ["illustrator:ol_heg__zhonghui"] = "官方",

  ["~ol_heg__zhonghui"] = "伯约，让你失望了。",
}

generals.ol_heg__liaohua = General:new(extension, "ol_heg__liaohua", "shu", 4)
generals.ol_heg__liaohua:addSkills{ "ol_heg__zhengxian" }
Fk:loadTranslationTable{
  ["ol_heg__liaohua"] = "廖化",
  ["#ol_heg__liaohua"] = "历尽沧桑",
  ["illustrator:ol_heg__liaohua"] = "天空之城",

  ["~ol_heg__liaohua"] = "今后，就靠你们了……",
}

Fk:loadTranslationTable {
  ["ol_heg__gongsunzan"] = "公孙瓒",
  --["#ol_heg__gongsunzan"] = "",
  --["illustrator:ol_heg__gongsunzan"] = "",

  ["~ol_heg__gongsunzan"] = "",
}

return extension
