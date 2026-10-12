local extension = Package:new("mobile_sp")
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/mobile_sp/skills")

Fk:loadTranslationTable{
  ["mobile_sp"] = "手杀-SP",
}

--SP1：马良
General:new(extension, "mobile__maliang", "shu", 3):addSkills { "mobile__zishu", "yingyuan" }
Fk:loadTranslationTable{
  ["mobile__maliang"] = "马良",
  ["#mobile__maliang"] = "白眉智士",
  ["illustrator:mobile__maliang"] = "云涯",

  ["~mobile__maliang"] = "此生行忠守义，已无愧我心。",
  ["!mobile__maliang"] = "良与主公一道，志为兴汉奋身！",
}

--SP2：孙鲁育 张宝 诸葛恪
General:new(extension, "mobile__sunluyu", "wu", 3, 3, General.Female):addSkills { "mobile__meibu", "mobile__mumu" }
Fk:loadTranslationTable{
  ["mobile__sunluyu"] = "孙鲁育",
  ["#mobile__sunluyu"] = "舍身饲虎",
  ["illustrator:mobile__sunluyu"] = "鬼画府",

  ["~mobile__sunluyu"] = "今朝遭诬含冤去，他日丹青还我清！",
}

General:new(extension, "mobile__zhangbao", "qun", 3):addSkills { "mobile__zhoufu", "mobile__yingbing" }
Fk:loadTranslationTable{
  ["mobile__zhangbao"] = "张宝",
  ["#mobile__zhangbao"] = "地公将军",
  ["illustrator:mobile__zhangbao"] = "4250工作室",

  ["~mobile__zhangbao"] = "黄天……为何？！",
}

General:new(extension, "zhugeke", "wu", 3):addSkills { "aocai", "duwu" }
Fk:loadTranslationTable{
  ["zhugeke"] = "诸葛恪",
  ["#zhugeke"] = "兴家赤族",
  ["designer:zhugeke"] = "韩旭",
  ["illustrator:zhugeke"] = "LiuHeng",

  ["~zhugeke"] = "重权震主，是我疏忽了……",
}

--SP3：关银屏
General:new(extension, "mobile__guanyinping", "shu", 3, 4, General.Female):addSkills { "mobile__xuehen", "mobile__huxiao", "mobile__wuji" }
Fk:loadTranslationTable{
  ["mobile__guanyinping"] = "关银屏",
  ["#mobile__guanyinping"] = "武姬",
  ["illustrator:mobile__guanyinping"] = "alien",

  ["~mobile__guanyinping"] = "父亲，兄长，银屏来见你们了……",
}

--SP4：贺齐
General:new(extension, "mobile__heqi", "wu", 4):addSkills { "mobile__qizhou", "mobile__shanxi" }
Fk:loadTranslationTable{
  ["mobile__heqi"] = "贺齐",
  ["#mobile__heqi"] = "马踏群峦",
  ["illustrator:mobile__heqi"] = "白夜零BYL",

  ["~mobile__heqi"] = "我军器精甲坚，竟也落败……",
}

General:new(extension, "mobile__chengyu", "wei", 3):addSkills { "mobile__shefu", "mobile__benyu" }
Fk:loadTranslationTable{
  ["mobile__chengyu"] = "程昱",
  ["#mobile__chengyu"] = "泰山捧日",
  ["illustrator:mobile__chengyu"] = "MUMU",

  ["~mobile__chengyu"] = "辗转五十载，幸哉乱世不复……",
}

--SP5：马忠 董白
General:new(extension, "mazhong", "shu", 4):addSkills { "fuman" }
Fk:loadTranslationTable{
  ["mazhong"] = "马忠",
  ["#mazhong"] = "笑合南中",
  ["designer:mazhong"] = "Virgopaladin",
  ["illustrator:mazhong"] = "Thinking",

  ["~mazhong"] = "丞相不在，你们竟然……",
}

General:new(extension, "mobile__dongbai", "qun", 3, 3, General.Female):addSkills { "mobile__lianzhu", "mobile__xiahui" }
Fk:loadTranslationTable{
  ["mobile__dongbai"] = "董白",
  ["#mobile__dongbai"] = "魔姬",
  ["illustrator:mobile__dongbai"] = "腥鱼仔",

  ["~mobile__dongbai"] = "放开我！你们怎敢……",
}

--SP6：董承 卫温诸葛直
General:new(extension, "mobile__dongcheng", "qun", 4):addSkills { "chengzhao" }
Fk:loadTranslationTable{
  ["mobile__dongcheng"] = "董承",
  ["#mobile__dongcheng"] = "沥胆卫汉",
  ["illustrator:mobile__dongcheng"] = "绘聚艺堂",

  ["~mobile__dongcheng"] = "九泉之下，我等着你曹贼到来！",
}

General:new(extension, "mobile__weiwenzhugezhi", "wu", 4):addSkills { "mobile__fuhaiw" }
Fk:loadTranslationTable{
  ["mobile__weiwenzhugezhi"] = "卫温诸葛直",
  ["#mobile__weiwenzhugezhi"] = "帆至夷洲",
  ["illustrator:mobile__weiwenzhugezhi"] = "biou09",

  ["~mobile__weiwenzhugezhi"] = "吾皆海岱清士，岂料生死易逝……",
}

--SP7：陶谦 杨仪 关索 士燮 孙皓
General:new(extension, "taoqian", "qun", 3):addSkills { "zhaohuo", "yixiang", "yirang" }
Fk:loadTranslationTable{
  ["taoqian"] = "陶谦",
  ["#taoqian"] = "膺秉温仁",
  ["illustrator:taoqian"] = "F.源",
  ["designer:taoqian"] = "Rivers",

  ["~taoqian"] = "悔不该差使小人，招此祸患。",
}

General:new(extension, "mobile__yangyi", "shu", 3):addSkills { "os__duoduan", "mobile__gongsun" }
Fk:loadTranslationTable{
  ["mobile__yangyi"] = "杨仪",
  ["#mobile__yangyi"] = "孤鹬",
  ["illustrator:mobile__yangyi"] = "铁杵文化",

  ["$os__duoduan_mobile__yangyi1"] = "度势而谋，断计求胜。",
  ["$os__duoduan_mobile__yangyi2"] = "逢敌先虑，定策后图。",
  ["~mobile__yangyi"] = "如今追悔，亦不可复及矣……",
}

General:new(extension, "guansuo", "shu", 4):addSkills { "zhengnan", "xiefang" }
Fk:loadTranslationTable{
  ["guansuo"] = "关索",
  ["#guansuo"] = "倜傥孑侠",
  ["designer:guansuo"] = "千幻",
  ["illustrator:guansuo"] = "depp",

  ["$wusheng_guansuo"] = "逆贼，可识得关氏之勇？",
  ["$dangxian_guansuo"] = "各位将军，且让小辈先行出战！",
  ["$zhiman_guansuo"] = "蛮夷可抚，不可剿！",
  ["~guansuo"] = "只恨天下未平，空留遗志。",
}

General:new(extension, "shixie", "qun", 3):addSkills { "biluan", "lixia" }
Fk:loadTranslationTable{
  ["shixie"] = "士燮",
  ["#shixie"] = "南交学祖",
  ["designer:shixie"] = "Rivers",
  ["illustrator:shixie"] = "銘zmy",

  ["~shixie"] = "我这一生，足矣……",
}

General:new(extension, "sunhao", "wu", 5):addSkills { "canshi", "chouhai", "guiming" }
Fk:loadTranslationTable{
  ["sunhao"] = "孙皓",
  ["#sunhao"] = "时日曷丧",
  ["illustrator:sunhao"] = "LiuHeng",

  ["~sunhao"] = "命啊！命！",
}

--SP8：吕凯 审配 王允
General:new(extension, "mobile__lvkai", "shu", 3):addSkills { "tunan", "mobile__bijing" }
Fk:loadTranslationTable{
  ["mobile__lvkai"] = "吕凯",
  ["#mobile__lvkai"] = "铁心司南",
  ["illustrator:mobile__lvkai"] = "L",

  ["~mobile__lvkai"] = "守节不易，吾愿舍身为蜀。",
}

General:new(extension, "mobile__shenpei", "qun", 2, 3):addSkills { "shouye", "liezhi" }
Fk:loadTranslationTable{
  ["mobile__shenpei"] = "审配",
  ["#mobile__shenpei"] = "正南义北",
  ["illustrator:mobile__shenpei"] = "YanBai",

  ["~mobile__shenpei"] = "吾君在北，但求面北而亡！",
}

General:new(extension, "mobile__wangyun", "qun", 3):addSkills { "mobile__lianji", "mobile__moucheng" }
Fk:loadTranslationTable{
  ["mobile__wangyun"] = "王允",
  ["#mobile__wangyun"] = "忠魂不泯",
  ["illustrator:mobile__wangyun"] = "鬼画府",

  ["~mobile__wangyun"] = "逆贼何必多言？今日有死而已！",
  ["!mobile__wangyun"] = "奸贼既除，乱世将定，大汉国祚永存。",
}

--SP9：苏飞 贾逵 张恭 许贡 曹婴 鲍三娘 徐荣
General:new(extension, "mobile__sufei", "wu", 4):addSkills { "zhengjian", "gaoyuan" }
Fk:loadTranslationTable{
  ["mobile__sufei"] = "苏飞",
  ["#mobile__sufei"] = "诤友投明",
  ["illustrator:mobile__sufei"] = "石蝉",

  ["~mobile__sufei"] = "本可共图大业，奈何主公量狭器小啊……",
}

General:new(extension, "tongqu__jiakui", "wei", 4):addSkills { "tongqu", "wanlan" }
Fk:loadTranslationTable{
  ["tongqu__jiakui"] = "贾逵",
  ["#tongqu__jiakui"] = "肃齐万里",
  ["illustrator:tongqu__jiakui"] = "福州暗金", -- 皮肤 水到渠成

  ["~tongqu__jiakui"] = "生怀死忠之心，死必为报国之鬼！",
}

General:new(extension, "mobile__zhanggong", "wei", 3):addSkills { "mobile__qianxinz", "zhenxing" }
Fk:loadTranslationTable{
  ["mobile__zhanggong"] = "张恭",
  ["#mobile__zhanggong"] = "西域长歌",
  ["illustrator:mobile__zhanggong"] = "B_LEE",
  ["designer:mobile__zhanggong"] = "笔枔",

  ["~mobile__zhanggong"] = "大漠孤烟，孤立无援啊……",
}

General:new(extension, "mobile__xugong", "wu", 3):addSkills { "mobile__biaozhao", "yechou" }
Fk:loadTranslationTable{
  ["mobile__xugong"] = "许贡",
  ["#mobile__xugong"] = "独计击流",
  ["illustrator:mobile__xugong"] = "君桓文化",

  ["$yechou_mobile__xugong1"] = "孙策小儿，你必还恶报！",
  ["$yechou_mobile__xugong2"] = "吾命丧黄泉，你也休想得安!",
  ["~mobile__xugong"] = "此表非我所写，岂可污我！",
}

General:new(extension, "mobile__caoying", "wei", 4, 4, General.Female):addSkills { "mobile__lingren", "mobile__fujian" }
Fk:loadTranslationTable{
  ["mobile__caoying"] = "曹婴",
  ["#mobile__caoying"] = "龙城凤鸣",
  ["cv:mobile__caoying"] = "水原",
  ["illustrator:mobile__caoying"] = "DH",
  ["designer:mobile__caoying"] = "韩旭",

  ["$jianxiong_mobile__caoying"] = "为大事者，当如祖父一般，眼界高远。",
  ["$xingshang_mobile__caoying"] = "将军忠魂不泯，应当厚葬。",

  ["~mobile__caoying"] = "吾虽身陨，无碍大魏之兴……",
  ["!mobile__caoying"] = "此战既胜，破蜀吞吴，指日可待！",
}

General:new(extension, "mobile__baosanniang", "shu", 3, 3, General.Female):addSkills { "shuyong", "mobile__xushen", "mobile__zhennan" }
Fk:loadTranslationTable{
  ["mobile__baosanniang"] = "鲍三娘",
  ["#mobile__baosanniang"] = "慕花之姝",
  ["illustrator:mobile__baosanniang"] = "迷走之音", -- 皮肤 嫣然一笑

  ["$wusheng_mobile__baosanniang"] = "此身武艺，皆承于关大将军。",
  ["$dangxian_mobile__baosanniang"] = "让我来与你一战。",
  ["$zhiman_mobile__baosanniang"] = "蛮人既降，何可徒造杀孽。",

  ["~mobile__baosanniang"] = "夫君，来世还愿与你相伴……",
}

General:new(extension, "mobile__xurong", "qun", 4):addSkills { "mobile__xionghuo", "mobile__shajue" }
Fk:loadTranslationTable{
  ["mobile__xurong"] = "徐荣",
  ["#mobile__xurong"] = "玄菟战魔",
  ["cv:mobile__xurong"] = "曹真",
  ["designer:mobile__xurong"] = "Loun老萌",
  ["illustrator:mobile__xurong"] = "青岛磐蒲",-- 烬灭神骇*徐荣 of 三国杀·移动版

  ["~mobile__xurong"] = "死于战场……是个不错的结局……",
}

--SP10：丁原 傅肜 邓芝 陈登 张翼 张琪瑛 王朗 胡车儿 公孙康 周群
General:new(extension, "dingyuan", "qun", 4):addSkills { "beizhu" }
Fk:loadTranslationTable{
  ["dingyuan"] = "丁原",
  ["#dingyuan"] = "饲虎成患",
  ["illustrator:dingyuan"] = "M云涯",

  ["~dingyuan"] = "奉先何故心变，啊！",
}

General:new(extension, "mobile__furong", "shu", 4):addSkills { "mobile__xuewei", "mobile__liechi" }
Fk:loadTranslationTable{
  ["mobile__furong"] = "傅肜",
  ["#mobile__furong"] = "危汉烈义",
  ["illustrator:mobile__furong"] = "黯荧岛",

  ["~mobile__furong"] = "成功断后，我死而无憾了……",
}

General:new(extension, "mobile__dengzhi", "shu", 3):addSkills { "mobile__jimeng", "mobile__shuaiyan" }
Fk:loadTranslationTable{
  ["mobile__dengzhi"] = "邓芝",
  ["#mobile__dengzhi"] = "绝境外交家",
  ["illustrator:mobile__dengzhi"] = "齐名", -- 皮肤 出使东吴

  ["~mobile__dengzhi"] = "一生为国，已然无憾矣。",
}

General:new(extension, "mobile__chendeng", "qun", 3):addSkills { "mobile__zhouxuanz", "mobile__fengji" }
Fk:loadTranslationTable{
  ["mobile__chendeng"] = "陈登",
  ["#mobile__chendeng"] = "雄气壮节",
  ["illustrator:mobile__chendeng"] = "小强",

  ["~mobile__chendeng"] = "诸卿何患无令君乎？",
}

General:new(extension, "mobile__zhangyiy", "shu", 4):addSkills { "zhiyi" }
Fk:loadTranslationTable{
  ["mobile__zhangyiy"] = "张翼",
  ["#mobile__zhangyiy"] = "亢锐怀忠",
  ["illustrator:mobile__zhangyiy"] = "王强",

  ["~mobile__zhangyiy"] = "唯愿百姓，不受此乱所害，哎……",
}

General:new(extension, "mobile__zhangqiying", "qun", 3, 3, General.Female):addSkills { "mobile__falu", "mobile__zhenyi", "mobile__dianhua" }
Fk:loadTranslationTable{
  ["mobile__zhangqiying"] = "张琪瑛",
  ["#mobile__zhangqiying"] = "禳祷西东",
  ["illustrator:mobile__zhangqiying"] = "蛋费鸡丁",

  ["~mobile__zhangqiying"] = "天地不仁，以万物为刍狗……",
  ["!mobile__zhangqiying"] = "谷神不死，是谓玄牝。",
}

General:new(extension, "wanglang", "wei", 3):addSkills { "gushe", "jici" }
Fk:loadTranslationTable{
  ["wanglang"] = "王朗",
  ["#wanglang"] = "凤鹛",
  ["designer:wanglang"] = "千幻",
  ["illustrator:wanglang"] = "銘zmy",

  ["~wanglang"] = "你，你！……哇啊……啊……",
}

General:new(extension, "hucheer", "qun", 4):addSkills { "daoji" }
Fk:loadTranslationTable{
  ["hucheer"] = "胡车儿",
  ["#hucheer"] = "夜盗神行",
  ["illustrator:hucheer"] = "李敏然",

  ["~hucheer"] = "未料一伸手，便被……敌酋捉……",
}

General:new(extension, "gongsunkang", "qun", 4):addSkills { "juliao", "taomie" }
Fk:loadTranslationTable{
  ["gongsunkang"] = "公孙康",
  ["#gongsunkang"] = "沸流腾蛟",
  ["illustrator:gongsunkang"] = "小强",

  ["~gongsunkang"] = "枭雄一世，何有所憾！",
}

General:new(extension, "zhouqun", "shu", 3):addSkills { "tiansuan" }
Fk:loadTranslationTable{
  ["zhouqun"] = "周群",
  ["#zhouqun"] = "后圣",
  ["illustrator:zhouqun"] = "张帅",

  ["~zhouqun"] = "及时止损，过犹不及…",
  ["!zhouqun"] = "占星问卜，莫不言精！",
}

--SP11：灵雎 兀突骨 阎圃 马元义 谯周 毛玠 傅佥 阮慧 马日磾 王濬
General:new(extension, "mobile__lingju", "qun", 3, 3, General.Female):addSkills { "mobile__jieyuan", "mobile__fenxin" }
Fk:loadTranslationTable{
  ["mobile__lingju"] = "灵雎",
  ["#mobile__lingju"] = "情随梦逝",
  ["illustrator:mobile__lingju"] = "第七个桔子",

  ["~mobile__lingju"] = "死士，最忌讳的便是动情……",
}

General:new(extension, "mobile__wutugu", "qun", 15):addSkills { "mobile__ranshang", "mobile__hanyong" }
Fk:loadTranslationTable{
  ["mobile__wutugu"] = "兀突骨",
  ["#mobile__wutugu"] = "霸体金刚",
  ["illustrator:mobile__wutugu"] = "陈层",

  ["~mobile__wutugu"] = "不可能，这不可能！",
}

General:new(extension, "yanpu", "qun", 3):addSkills { "huantu", "bihuoy" }
Fk:loadTranslationTable{
  ["yanpu"] = "阎圃",
  ["#yanpu"] = "盱衡识势",
  ["illustrator:yanpu"] = "鬼画府",

  ["~yanpu"] = "公皆听吾计，圃岂敢不专……",
}

General:new(extension, "mayuanyi", "qun", 4):addSkills { "jibing", "wangjingm", "moucuan" }
Fk:loadTranslationTable{
  ["mayuanyi"] = "马元义",
  ["#mayuanyi"] = "黄天擎炬",
  ["illustrator:mayuanyi"] = "丸点科技",

  ["~mayuanyi"] = "唐周……无耻！",
}

General:new(extension, "qiaozhou", "shu", 3):addSkills { "os__zhiming", "xingbu" }
Fk:loadTranslationTable{
  ["qiaozhou"] = "谯周",
  ["#qiaozhou"] = "观星知命",
  ["illustrator:qiaozhou"] = "匠人绘",

  ["~qiaozhou"] = "是非在己，毁誉由人……",
}

General:new(extension, "maojie", "wei", 3):addSkills { "bingqing" }
Fk:loadTranslationTable{
  ["maojie"] = "毛玠",
  ["#maojie"] = "清公素履",
  ["cv:maojie"] = "刘强",
  ["illustrator:maojie"] = "君桓文化",

  ["~maojie"] = "废立大事，公不可不慎……",
}

General:new(extension, "fuqian", "shu", 4):addSkills { "poxiang", "jueyong" }
Fk:loadTranslationTable{
  ["fuqian"] = "傅佥",
  ["#fuqian"] = "危汉绝勇",
  ["illustrator:fuqian"] = "君桓文化",
  ["cv:fuqian"] = "杨超然",

  ["~fuqian"] = "生为蜀臣，死……亦当为蜀！",
}

General:new(extension, "ruanhui", "wei", 3, 3, General.Female):addSkills { "mingcha", "jingzhong" }
Fk:loadTranslationTable{
  ["ruanhui"] = "阮慧",
  ["#ruanhui"] = "明察福祸",
  ["illustrator:ruanhui"] = "匠人绘",

  ["~ruanhui"] = "贱妾茕茕守空房，忧来思君不敢忘……",
}

General:new(extension, "mobile__mamidi", "qun", 3):addSkills { "chengye", "buxu" }
Fk:loadTranslationTable{
  ["mobile__mamidi"] = "马日磾",
  ["#mobile__mamidi"] = "少传融业",
  ["illustrator:mobile__mamidi"] = "君桓文化",

  ["~mobile__mamidi"] = "袁公路！汝怎可欺我！",
}

local wangjun = General:new(extension, "wangjun", "qun", 4)
wangjun.subkingdom = "jin"
wangjun:addSkills { "zhujian", "duansuo" }
Fk:loadTranslationTable{
  ["wangjun"] = "王濬",
  ["#wangjun"] = "首下石城",
  ["illustrator:wangjun"] = "凝聚永恒",

  ["~wangjun"] = "问鼎金瓯碎，临江铁索寒……",
}

--SP12：赵统赵广 刘晔 李丰 诸葛果 胡金定 王元姬 羊徽瑜 杨彪 司马昭
General:new(extension, "zhaotongzhaoguang", "shu", 4):addSkills { "yizan", "longyuan" }
Fk:loadTranslationTable{
  ["zhaotongzhaoguang"] = "赵统赵广",
  ["#zhaotongzhaoguang"] = "翊赞季兴",
  ["designer:zhaotongzhaoguang"] = "Loun老萌",
  ["illustrator:zhaotongzhaoguang"] = "蛋费鸡丁",

  ["~zhaotongzhaoguang"] = "守业死战，不愧初心。",
  ["!zhaotongzhaoguang"] = "身继龙魂，效捷致果！",
}

General:new(extension, "mobile__liuye", "wei", 3):addSkills { "polu", "choulue" }
Fk:loadTranslationTable{
  ["mobile__liuye"] = "刘晔",
  ["#mobile__liuye"] = "佐世之才",
  ["designer:mobile__liuye"] = "荼蘼",
  ["illustrator:mobile__liuye"] = "Thinking",

  ["~mobile__liuye"] = "唉，于上不能佐君主，于下不能亲同僚，吾愧为佐世人臣。",
}

General:new(extension, "lifeng", "shu", 3):addSkills { "tunchu", "shuliang" }
Fk:loadTranslationTable{
  ["lifeng"] = "李丰",
  ["#lifeng"] = "朱提太守",
  ["cv:lifeng"] = "秦且歌",
  ["illustrator:lifeng"] = "NOVART",

  ["~lifeng"] = "吾，有负丞相重托。",
}

General:new(extension, "zhugeguo", "shu", 3, 3, General.Female):addSkills { "qirang", "yuhua" }
Fk:loadTranslationTable{
  ["zhugeguo"] = "诸葛果",
  ["#zhugeguo"] = "凤阁乘烟",
  ["illustrator:zhugeguo"] = "NOVART",

  ["~zhugeguo"] = "方生方死，方死方生……",
  ["!zhugeguo"] = "我自快意，化入天穹飞逍遥！",
}

General:new(extension, "hujinding", "shu", 2, 6, General.Female):addSkills { "renshi", "wuyuan", "huaizi" }
Fk:loadTranslationTable{
  ["hujinding"] = "胡金定",
  ["#hujinding"] = "怀子求怜",
  ["illustrator:hujinding"] = "Thinking",

  ["~hujinding"] = "云长，重逢不久，又要相别么……",
}

General:new(extension, "mobile__wangyuanji", "wei", 3, 3, General.Female):addSkills { "qianchong", "shangjian" }
Fk:loadTranslationTable{
  ["mobile__wangyuanji"] = "王元姬",
  ["#mobile__wangyuanji"] = "清雅抑华",
  ["illustrator:mobile__wangyuanji"] = "凝聚永恒",

  ["$weimu_mobile__wangyuanji"] = "宫闱之内，何必擅涉外事！",
  ["$mingzhe_mobile__wangyuanji"] = "谦瑾行事，方能多吉少恙。",

  ["~mobile__wangyuanji"] = "世事沉浮，非是一人可逆啊……",
  ["!mobile__wangyuanji"] = "苍生黎庶，都会有一个美好的未来了。",
}

General:new(extension, "mobile__yanghuiyu", "wei", 3, 3, General.Female):addSkills { "hongyi", "quanfeng" }
Fk:loadTranslationTable{
  ["mobile__yanghuiyu"] = "羊徽瑜",
  ["#mobile__yanghuiyu"] = "温慧母仪",
  ["designer:mobile__yanghuiyu"] = "Loun老萌",
  ["illustrator:mobile__yanghuiyu"] = "石蝉",

  ["~mobile__yanghuiyu"] = "桃符，一定要平安啊……",
}

General:new(extension, "yangbiao", "qun", 3):addSkills { "zhaohan", "rangjie", "mobile__yizheng" }
Fk:loadTranslationTable{
  ["yangbiao"] = "杨彪",
  ["#yangbiao"] = "德彰海内",
  ["cv:yangbiao"] = "袁国庆",
  ["designer:yangbiao"] = "Loun老萌",
  ["illustrator:yangbiao"] = "木美人",

  ["~yangbiao"] = "未能效死佑汉，只因宗族之重……",
}

General:new(extension, "m_sp__simazhao", "wei", 3):addSkills { "zhaoxin", "daigong" }
Fk:loadTranslationTable{
  ["m_sp__simazhao"] = "司马昭", -- 手杀称为SP司马昭
  ["#m_sp__simazhao"] = "四海威服",
  ["illustrator:m_sp__simazhao"] = "Thinking",

  ["~m_sp__simazhao"] = "安世，接下来，就看你的了……",
  ["!m_sp__simazhao"] = "天下归一之功，已近在咫尺。",
}

--SP13：曹嵩 裴秀 杨阜 彭羕 牵招 郭女王 韩遂 阎象 李遗
General:new(extension, "mobile__caosong", "wei", 3):addSkills { "yijin", "guanzong" }
Fk:loadTranslationTable{
  ["mobile__caosong"] = "曹嵩",
  ["#mobile__caosong"] = "舆金贾权",
  ["illustrator:mobile__caosong"] = "黯荧岛工作室",

  ["~mobile__caosong"] = "长恨人心不如水，等闲平地起波澜……",
}

local peixiu = General:new(extension, "peixiu", "qun", 3)
peixiu.subkingdom = "jin"
peixiu:addSkills { "xingtu", "juezhi"}
Fk:loadTranslationTable{
  ["peixiu"] = "裴秀",
  ["#peixiu"] = "晋图开秘",
  ["designer:peixiu"] = "Loun老萌",
  ["illustrator:peixiu"] = "鬼画府",

  ["~peixiu"] = "既食寒石散，便不可饮冷酒啊……",
}

General:new(extension, "yangfu", "wei", 3):addSkills { "jiebing", "hannan" }
Fk:loadTranslationTable{
  ["yangfu"] = "杨阜",
  ["#yangfu"] = "勇撼雄狮",
  ["illustrator:yangfu"] = "铁杵文化",

  ["~yangfu"] = "汝背父叛君，吾誓，杀……",
}

General:new(extension, "pengyang", "shu", 3):addSkills { "daming", "xiaoni" }
Fk:loadTranslationTable{
  ["pengyang"] = "彭羕",
  ["#pengyang"] = "难别菽麦",
  ["illustrator:pengyang"] = "铁杵文化",

  ["~pengyang"] = "招祸自咎，无不自己……",
}

General:new(extension, "qianzhao", "wei", 4):addSkills { "shihe", "zhenfu" }
Fk:loadTranslationTable{
  ["qianzhao"] = "牵招",
  ["#qianzhao"] = "威风远振",
  ["illustrator:qianzhao"] = "错落宇宙",

  ["~qianzhao"] = "治边数载，虽不敢称功，亦可谓无过……",
}

General:new(extension, "mobile__guozhao", "wei", 3, 3, General.Female):addSkills {
  "yichong",
  "wufei",
}
Fk:loadTranslationTable{
  ["mobile__guozhao"] = "郭女王",
  ["#mobile__guozhao"] = "文德皇后",
  ["illustrator:mobile__guozhao"] = "凡果",

  ["~mobile__guozhao"] = "不觉泪下……沾衣裳……",
}

local mobileHansui = General:new(extension, "mobile__hansui", "qun", 4)
mobileHansui.shield = 1
mobileHansui:addSkills { "mobile__niluan", "mobile__xiaoxi" }
Fk:loadTranslationTable{
  ["mobile__hansui"] = "韩遂",
  ["#mobile__hansui"] = "雄踞北疆",
  ["illustrator:mobile__hansui"] = "盲特",

  ["~mobile__hansui"] = "称雄三十载，一败化为尘……",
}

General:new(extension, "mobile__yanxiang", "qun", 3):addSkills { "kujian", "ruilian" }
Fk:loadTranslationTable{
  ["mobile__yanxiang"] = "阎象",
  ["#mobile__yanxiang"] = "明尚夙达",
  ["illustrator:mobile__yanxiang"] = "君桓文化",

  ["~mobile__yanxiang"] = "若遇明主，或可青史留名……",
}

General:new(extension, "mobile__liwei", "shu", 4):addSkills { "mobile__jiaohua" }
Fk:loadTranslationTable{
  ["mobile__liwei"] = "李遗",
  ["#mobile__liwei"] = "伏被俞元",
  ["illustrator:mobile__liwei"] = "君桓文化",

  ["~mobile__liwei"] = "安南重任，万不可轻之……",
}

--SP14：吴班 鲍信 胡班 陈珪 霍峻 木鹿大王 蒋干 杨奉 甘夫人 来敏
General:new(extension, "mobile__wuban", "shu", 4):addSkills { "mobile__jintao" }
Fk:loadTranslationTable{
  ["mobile__wuban"] = "吴班",
  ["#mobile__wuban"] = "碧血的英豪",
  ["illustrator:mobile__wuban"] = "鬼画府",

  ["~mobile__wuban"] = "汉室倾颓，匡复无望……",
}

General:new(extension, "mobile__baoxin", "qun", 4):addSkills { "mobile__mutao", "mobile__yimou" }
Fk:loadTranslationTable{
  ["mobile__baoxin"] = "鲍信",
  ["#mobile__baoxin"] = "坚朴的忠相",
  ["illustrator:mobile__baoxin"] = "梦想君",
  ["designer:mobile__baoxin"] = "jcj熊",

  ["~mobile__baoxin"] = "良谋有壮骨，奈何不逢时啊！",
}

General:new(extension, "mobile__huban", "wei", 4):addSkills { "mobile__yilie" }
Fk:loadTranslationTable{
  ["mobile__huban"] = "胡班",
  ["#mobile__huban"] = "昭义烈勇",
  ["illustrator:mobile__huban"] = "铁杵文化",

  ["~mobile__huban"] = "生虽微而志不可改，位虽卑而节不可夺……",
}

General:new(extension, "mobile__chengui", "qun", 3):addSkills { "guimou", "zhouxian" }
Fk:loadTranslationTable{
  ["mobile__chengui"] = "陈珪",
  ["#mobile__chengui"] = "弄辞巧掇",
  ["illustrator:mobile__chengui"] = "凝聚永恒",

  ["~mobile__chengui"] = "布非忠良之士，将军宜早图之……",
}

General:new(extension, "mobile__huojun", "shu", 4):addSkills { "mobile__sidai", "mobile__jieyu" }
Fk:loadTranslationTable{
  ["mobile__huojun"] = "霍峻",
  ["#mobile__huojun"] = "葭萌铁狮",
  ["illustrator:mobile__huojun"] = "君桓文化",
  ["designer:mobile__huojun"] = "步穗",

  ["~mobile__huojun"] = "使君，葭萌城……守住了……",
}

local muludawang = General:new(extension, "muludawang", "qun", 3)
muludawang:addSkills { "shoufa", "zhoulin", "yuxiang" }
muludawang.shield = 1
Fk:loadTranslationTable{
  ["muludawang"] = "木鹿大王",
  ["#muludawang"] = "八纳洞主",
  ["illustrator:muludawang"] = "三道纹",

  ["~muludawang"] = "啊啊，诸葛亮神人降世，吾等难挡天威。",
}

General:new(extension, "mobile__jianggan", "wei", 3):addSkills { "mobile__daoshu", "daizui" }
Fk:loadTranslationTable{
  ["mobile__jianggan"] = "蒋干",
  ["#mobile__jianggan"] = "虚义伪诚",
  ["illustrator:mobile__jianggan"] = "鬼画府",

  ["~mobile__jianggan"] = "唉，假信害我不浅啊……",
}

General:new(extension, "yangfeng", "qun", 4):addSkills { "xuetu", "weiming" }
Fk:loadTranslationTable{
  ["yangfeng"] = "杨奉",
  ["#yangfeng"] = "忠勇半途",
  ["illustrator:yangfeng"] = "铁杵文化",

  ["~yangfeng"] = "刘备！本共图吕布，何设鸿门相欺！",
}

General:new(extension, "mobile__ganfuren", "shu", 3, 3, General.Female):addSkills { "zhijie", "mobile__shushen" }
Fk:loadTranslationTable{
  ["mobile__ganfuren"] = "甘夫人",
  ["#mobile__ganfuren"] = "昭烈皇后",
  ["illustrator:mobile__ganfuren"] = "错落宇宙",

  ["~mobile__ganfuren"] = "只愿夫君，大事可成，兴汉有期……",
}

General:new(extension, "laimin", "shu", 3):addSkills { "laishou", "luanqun" }
Fk:loadTranslationTable{
  ["laimin"] = "来敏",
  ["#laimin"] = "悖骴乱群",
  ["illustrator:laimin"] = "错落宇宙",

  ["~laimin"] = "狂嚣之言，一言十过啊……",
}

--SP15：SP甄姬 王经 清河公主 张布 吴珂 笮融 乐就 SP曹操 孟达 蒋济
General:new(extension, "m_sp__zhenji", "qun", 3, 3, General.Female):addSkills { "bojian", "jiwei" }
Fk:loadTranslationTable{
  ["m_sp__zhenji"] = "甄姬",
  ["#m_sp__zhenji"] = "明珠锦玉",
  ["illustrator:m_sp__zhenji"] = "铁杵",

  ["~m_sp__zhenji"] = "悔入帝王家，万愿皆成空……",
  ["!m_sp__zhenji"] = "昔见百姓十室九空，更惜今日安居乐业。",
}

General:new(extension, "wangjing", "wei", 3):addSkills { "zujin", "jiejianw" }
Fk:loadTranslationTable{
  ["wangjing"] = "王经",
  ["#wangjing"] = "青云孤竹",
  ["illustrator:wangjing"] = "凝聚永恒",

  ["~wangjing"] = "有母此言，经死之无悔。",
}

General:new(extension, "mobile__qinghegongzhu", "wei", 3, 3, General.Female):addSkills { "mobile__zengou", "feili" }
Fk:loadTranslationTable{
  ["mobile__qinghegongzhu"] = "清河公主",
  ["#mobile__qinghegongzhu"] = "蛊虿之谗",
  ["illustrator:mobile__qinghegongzhu"] = "凝聚永恒",

  ["~mobile__qinghegongzhu"] = "夏侯楙徒有形表，实非良人……",
  ["!mobile__qinghegongzhu"] = "夫君自走死路，何可怨得妾身。",
}

General:new(extension, "zhangbu", "wu", 4):addSkills { "chengxiong", "wangzhuan" }
Fk:loadTranslationTable{
  ["zhangbu"] = "张布",
  ["#zhangbu"] = "主胜辅义",
  ["illustrator:zhangbu"] = "错落宇宙",

  ["~zhangbu"] = "悔不遵先帝遗命啊。",
}

General:new(extension, "wuke", "wu", 3, 3, General.Female):addSkills { "anda", "zhuguo" }
Fk:loadTranslationTable{
  ["wuke"] = "吴珂",
  ["#wuke"] = "智略权谲",
  ["illustrator:wuke"] = "铁杵",

  ["~wuke"] = "诸君竭辅仲谋，万事务以江东为虑。",
}

General:new(extension, "mobile__zerong", "qun", 4):addSkills { "futu", "jingtu", "jiebian" }
Fk:loadTranslationTable{
  ["mobile__zerong"] = "笮融",
  ["#mobile__zerong"] = "持宗事魔",
  ["illustrator:mobile__zerong"] = "凝聚永恒",

  ["~mobile__zerong"] = "众生不悟，迷之者多。",
  ["!mobile__zerong"] = "无有三途苦难之名，但有自然快乐之声。",
}

General:new(extension, "mobile__yuejiu", "qun", 4):addSkill("cuijin")
Fk:loadTranslationTable{
  ["mobile__yuejiu"] = "乐就",
  ["#mobile__yuejiu"] = "仲家军督",
  ["illustrator:mobile__yuejiu"] = "掏蛋飞贼",

  ["~mobile__yuejiu"] = "哼，动手吧！",
}

General:new(extension, "m_sp__caocao", "qun", 4):addSkill("lingfa")
Fk:loadTranslationTable{
  ["m_sp__caocao"] = "曹操",
  ["#m_sp__caocao"] = "峥嵘而立",
  ["illustrator:m_sp__caocao"] = "绘聚艺堂",

  ["$os__zhian_m_sp__caocao1"] = "尔等权贵贪赃枉法，岂可轻饶！",
  ["$os__zhian_m_sp__caocao2"] = "目无禁法，勿问贵贱一律棒杀！",
  ["$jianxiong_m_sp__caocao1"] = "征乌桓，平诸逆。孤，可为汉家将军第一人！",
  ["$jianxiong_m_sp__caocao2"] = "是非功过，皆由后人评去。",

  ["~m_sp__caocao"] = "孤的大业，还未开始……",
}

General:new(extension, "mobile__mengda", "qun", 4):addSkills { "jilim", "shishu" }
Fk:loadTranslationTable{
  ["mobile__mengda"] = "孟达",
  ["#mobile__mengda"] = "求栖梧桐",
  ["illustrator:mobile__mengda"] = "特特肉",

  ["~mobile__mengda"] = "啊？司马公何以如此神速！",
}

General:new(extension, "mobile__jiangji", "wei", 3):addSkills { "jichou", "jilun" }
Fk:loadTranslationTable{
  ["mobile__jiangji"] = "蒋济",
  ["#mobile__jiangji"] = "盛魏昌杰",
  ["illustrator:mobile__jiangji"] = "错落宇宙",

  ["~mobile__jiangji"] = "洛水之誓，言犹在耳……咳咳咳……",
}

General:new(extension, "m_sp__yujin", "qun", 4):addSkills { "zhenjun" }
Fk:loadTranslationTable{
  ["m_sp__yujin"] = "于禁",
  ["#m_sp__yujin"] = "逐暴定乱",
  ["designer:m_sp__yujin"] = "Loun老萌",

  ["~m_sp__yujin"] = "命归九泉，何颜面对……",
}

General:new(extension, "mobile__zhangjih", "wei", 3):addSkills { "dingzhen", "youye" }
Fk:loadTranslationTable{
  ["mobile__zhangjih"] = "张既",
  ["#mobile__zhangjih"] = "边安人宁",
  ["illustrator:mobile__zhangjih"] = "凝聚永恒",

  ["~mobile__zhangjih"] = "恨不见四海肃眘，羌胡徕服。",
}

General:new(extension, "mobile__yangqiu", "qun", 4):addSkills { "mobile__saojian" }
Fk:loadTranslationTable{
  ["mobile__yangqiu"] = "阳球",
  ["#mobile__yangqiu"] = "身蹈水火",
  --["illustrator:mobile__yangqiu"] = "",

  ["~mobile__yangqiu"] = "臣何敢违君言？但恐生祸患啊！",
}

General:new(extension, "mobile__cuiyanmaojie", "wei", 3):addSkills { "mobile__fengying", "mobile__zhengbi" }
Fk:loadTranslationTable{
  ["mobile__cuiyanmaojie"] = "崔琰毛玠",
  ["#mobile__cuiyanmaojie"] = "日出月盛",
  --["illustrator:mobile__cuiyanmaojie"] = "",

  ["~mobile__cuiyanmaojie"] = "尽忠言非博美名，问心无愧而已。",
}

--test
General:new(extension, "mobile__xingdaorong", "qun", 4):addSkills { "kuangwu" }
Fk:loadTranslationTable{
  ["mobile__xingdaorong"] = "邢道荣",
  ["#mobile__xingdaorong"] = "零陵上将",

  ["~mobile__xingdaorong"] = "这赵云，好生厉害啊……",
}

return extension
