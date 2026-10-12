local extension = Package("overseas_sp")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_sp/skills")

Fk:loadTranslationTable{
  ["overseas_sp"] = "国际服-SP",
  ["os"] = "国际",
  ["os_sp"] = "国际SP",
  ["os_js"] = "国际江山",
  ["os_thoroughbred"] = "国际骥",
  ["os_friend"] = "国际友",

  ["os__shifa_href"] = "#\"<b>施法</b>\"：一名角色的回合结束前，施法标记-1，减至0时执行施法效果。施法期间不能重复施法同一技能。",
  ["os__qiangling_href"] = "#\"<b>强令</b>\"：向一名角色颁布一项任务，在任务结束时执行奖惩。",
  ["os__wrestle"] = "#\"<b>搏击</b>\"：你与其在彼此的攻击范围内。",
  ["os__guerrilla"] = "#\"<b>游击</b>\"：其在你攻击范围内，你不在其攻击范围内。",
  ["os__presumption"] = "#\"<b>妄行</b>\"：选择X的值（1至4）执行相应效果，然后结束阶段，你需弃置X张牌，否则减1点体力上限。",
  ["#SpiritedSkillDesc"] = "#\"<b>昂扬技</b>\"：昂扬技发动后，技能失效直到满足<b>激昂</b>条件。",
  ["os__veteran"] = "#\"<b>历战</b>\"：发动过本技能的回合结束后，对本技能进行升级或修改，可叠加。",
  ["os__coop"] = "#\"<b>同心</b>\"：回合开始时，你可选择一名其他角色为你的<b>同心角色</b>，直到你的下个回合开始；" ..
  "执行<b>同心效果</b>时，你先执行，然后若你有<b>同心角色</b>，其执行。",
  ["os__baonue_href"] = "#\"<b>暴虐</b>\"：当你造成或受到伤害后，你获得1点暴虐值。暴虐值上限为5。",
  ["os__override"] = "#\"<b>凌越</b>\"：发动拥有凌越效果的技能时，若技能发动者的凌越类型数值大于所有目标角色，则额外执行凌越效果。",
  ["os__assault"] = "#\"<b>摧坚</b>\"：每回合限一次，当你使用伤害类牌指定目标后，你可以选择其中一名目标角色发动本技能效果，"..
  "X为目标角色的技能数，至多为4。",
}

General:new(extension, "os__fuwan", "qun", 4):addSkill("os__moukui")
Fk:loadTranslationTable{
  ["os__fuwan"] = "伏完",
  ["#os__fuwan"] = "沉毅的国丈",
  ["illustrator:os__fuwan"] = "王强",

  ["~os__fuwan"] = "后会有期……",
}

General:new(extension, "os__liuxie", "qun", 3):addSkills { "tianming", "mizhao", "os__zhuiting" }
Fk:loadTranslationTable{
  ["os__liuxie"] = "刘协",
  ["#os__liuxie"] = "受困天子",
  ["illustrator:os__liuxie"] = "Liuheng", -- 身不由己

  ["$tianming_os__liuxie1"] = "天命佑朕，让大汉再次兴起。",
  ["$tianming_os__liuxie2"] = "此乃天不亡我刘氏啊！",
  ["$mizhao_os__liuxie1"] = "若依此诏，可铲权臣。",
  ["$mizhao_os__liuxie2"] = "曹贼，莫想挟天子以令诸侯。",
  ["~os__liuxie"] = "为何要逼朕退位…"
}

local guanyu = General:new(extension, "os_sp__guanyu", "wei", 4)
guanyu:addSkills { "wusheng", "os__danji" }
guanyu:addRelatedSkills { "mashu", "nuzhan" }
Fk:loadTranslationTable{
  ["os_sp__guanyu"] = "关羽",
  ["#os_sp__guanyu"] = "汉寿亭侯",
  ["illustrator:os_sp__guanyu"] = "青岛君桓",

  ["$wusheng_os_sp__guanyu1"] = "武定乱世，圣绝一心！",
  ["$wusheng_os_sp__guanyu2"] = "誓会兄长，不惧血战！",
  ["~os_sp__guanyu"] = "忠节一世，死战不降！",
}

local caohong = General:new(extension, "os__caohong", "wei", 4)
caohong:addSkills { "os__yuanhu", "os__juezhu" }
caohong:addRelatedSkill("feiying")
Fk:loadTranslationTable{
  ["os__caohong"] = "曹洪",
  ["#os__caohong"] = "福将",
  ["illustrator:os__caohong"] = "XXX",

  ["~os__caohong"] = "福兮祸所伏……",
}

local daqiaoxiaoqiao = General:new(extension, "os__daqiaoxiaoqiao", "wu", 3, 3, General.Female)
daqiaoxiaoqiao:addSkills { "os__xingwu", "os__pingting" }
daqiaoxiaoqiao:addRelatedSkills { "tianxiang", "liuli" }
Fk:loadTranslationTable{
  ["os__daqiaoxiaoqiao"] = "大乔小乔",
  ["#os__daqiaoxiaoqiao"] = "江东之花",

  ["~os__daqiaoxiaoqiao"] = "伯符，公瑾，请一定要守护住我们的江东啊！",
}

local zhaoxiang = General(extension, "os__zhaoxiang", "shu", 4, 4, General.Female)
zhaoxiang:addSkills { "os__fanghun", "os__fuhan", "os__queshi" }
zhaoxiang:addRelatedSkill("longdan")
Fk:loadTranslationTable{
  ["os__zhaoxiang"] = "赵襄",
  ["#os__zhaoxiang"] = "拾梅鹊影",
  ["illustrator:os__zhaoxiang"] = "花弟",

  ["~os__zhaoxiang"] = "遁入阴影之中……",
}

General:new(extension, "os__zhanglu", "qun", 3):addSkills { "yishe", "bushi", "midao", "os__shijun" }
Fk:loadTranslationTable{
  ["os__zhanglu"] = "张鲁",
  ["#os__zhanglu"] = "政宽教惠",
  ["illustrator:os__zhanglu"] = "凝聚永恒",
}

General:new(extension, "os__mayunlu", "shu", 4, 4, General.Female):addSkills { "mashu", "os__fengpo" }
Fk:loadTranslationTable{
  ["os__mayunlu"] = "马云騄",
  ["illustrator:os__mayunlu"] = "叶碧芳", -- 蝶舞花飞
  ["#os__mayunlu"] = "剑胆琴心",

  ["~os__mayunlu"] = "子龙哥哥，救我……",
}

General:new(extension, "os__baosanniang", "shu", 3, 3, General.Female):addSkills { "os__shuyong", "os__xushen", "os__zhennan" }
Fk:loadTranslationTable{
  ["os__baosanniang"] = "鲍三娘",
  ["#os__baosanniang"] = "慕花之姝",
  ["illustrator:os__baosanniang"] = "西嘛哒", -- 情定缘起

  ["~os__baosanniang"] = "既为赴国危难，哪顾儿女情长！",
}

General:new(extension, "os__fanchou", "qun", 4):addSkill("os__xingluan")
Fk:loadTranslationTable{
  ["os__fanchou"] = "樊稠",
  ["#os__fanchou"] = "庸生变难",
  ["illustrator:os__fanchou"] = "枭瞳",

  ["~os__fanchou"] = "我无谋反之心！啊……",
}

General:new(extension, "os__liuyao", "qun", 4):addSkills { "kannan", "os__niju" }
Fk:loadTranslationTable{
  ["os__liuyao"] = "刘繇",
  ["#os__liuyao"] = "宗英外镇",
}

General:new(extension, "os__jiakui", "wei", 3):addSkills { "os__zhongzuo", "os__wanlan" }
Fk:loadTranslationTable{
  ["os__jiakui"] = "贾逵",
  ["#os__jiakui"] = "肃齐万里",
  ["designer:os__jiakui"] = "Loun老萌",
  ["illustrator:os__jiakui"] = "Monkey",

  ["~os__jiakui"] = "不斩孙权，九泉之下羞见先帝啊！",
}

General:new(extension, "os_sp__yujin", "qun", 4):addSkill("os__zhenjun")
Fk:loadTranslationTable{
  ["os_sp__yujin"] = "于禁",
  ["#os_sp__yujin"] = "逐暴定乱",
  ["illustrator:os_sp__yujin"] = "凡果",
  ["designer:os_sp__yujin"] = "Loun老萌",

  ["~os_sp__yujin"] = "命归九泉，何颜面对……",
}

General:new(extension, "os__yangyi", "shu", 3):addSkills { "os__duoduan", "os__gongsun" }
Fk:loadTranslationTable{
  ["os__yangyi"] = "杨仪",
  ["#os__yangyi"] = "孤鹬",

  ["~os__yangyi"] = "我功勋卓著，只为昏君奸臣所害，哼！",
}

General:new(extension, "os__dengzhi", "shu", 3):addSkills { "os__jimeng", "os__shuaiyan" }
Fk:loadTranslationTable{
  ["os__dengzhi"] = "邓芝",
  ["#os__dengzhi"] = "绝境的外交家",
  ["illustrator:os__dengzhi"] = "Monkey",

  ["~os__dengzhi"] = "使命既成，但死无妨！",
}

General:new(extension, "os__hucheer", "qun", 4):addSkills { "os__shenxing", "os__daoji" }
Fk:loadTranslationTable{
  ["os__hucheer"] = "胡车儿",
  ["#os__hucheer"] = "夜盗神行",
  ["illustrator:os__hucheer"] = "李敏然",

  ["~os__hucheer"] = "未料一伸手，便被……敌酋捉……",
}

local caocao = General(extension, "os_sp__caocao", "qun", 4)
caocao:addSkill("os__lingfa")
caocao:addRelatedSkill("os__zhian")
Fk:loadTranslationTable{
  ["os_sp__caocao"] = "曹操",
  ["#os_sp__caocao"] = "峥嵘而立",
  ["illustrator:os_sp__caocao"] = "YanBai",
  ["designer:os_sp__caocao"] = "Loun老萌",

  ["~os_sp__caocao"] = "奸宦当道，难以匡正啊……",
}

General:new(extension, "os__simashi", "wei", 4):addSkills { "os__baiyi", "os__jinglue", "os__shanli" }
Fk:loadTranslationTable{
  ["os__simashi"] = "司马师",
  ["#os__simashi"] = "摧坚荡异",
  ["illustrator:os__simashi"] = "M云涯",

  ["~os__simashi"] = "吾家夙愿，得偿与否，尽看子上……",
}

General:new(extension, "os__qiaozhou", "shu", 3):addSkills { "os__zhiming", "os__xingbu" }
Fk:loadTranslationTable{
  ["os__qiaozhou"] = "谯周",
  ["#os__qiaozhou"] = "观星知命",
  ["illustrator:os__qiaozhou"] = "鬼画府",

  ["~os__qiaozhou"] = "老夫死不足惜，但求蜀地百姓无虞！",
}

General:new(extension, "os__furong", "shu", 4):addSkills { "os__xuewei", "os__liechi" }
Fk:loadTranslationTable{
  ["os__furong"] = "傅肜",
  ["#os__furong"] = "危汉义烈",
  ["illustrator:os__furong"] = "三道纹",

  ["~os__furong"] = "吾主既然得返，此番已是功成……",
}

General:new(extension, "weixu", "qun", 4):addSkills { "os__suizheng", "os__tuidao" }
Fk:loadTranslationTable{
  ["weixu"] = "魏续",
  ["#weixu"] = "缚陈降曹",
  ["illustrator:weixu"] = "XXX",

  ["~os__weixu"] = "颜良小儿，竟敢杀我同伴，看我为其……啊！",
}

General:new(extension, "qiaorui", "qun", 5):addSkills { "os__xiawei", "os__qiongji" }
Fk:loadTranslationTable{
  ["qiaorui"] = "桥蕤",
  ["#qiaorui"] = "穷勇技尽",
  ["designer:qiaorui"] = "暗夜决彻",
  ["illustrator:qiaorui"] = "鱼仔",

  ["~qiaorui"] = "曹贼……安敢犯仲国之威……",
}

General:new(extension, "os__haomeng", "qun", 4):addSkill("os__gongge")
Fk:loadTranslationTable{
  ["os__haomeng"] = "郝萌",
  ["#os__haomeng"] = "悖虎之伥",
  ["illustrator:os__haomeng"] = "黑白画谱",

  ["~os__haomeng"] = "反复小儿！汝竟临阵倒戈……",
}

General:new(extension, "simafu", "wei", 3):addSkills { "xunde", "chenjie" }
Fk:loadTranslationTable{
  ["simafu"] = "司马孚",
  ["#simafu"] = "阐忠弘道",
  ["illustrator:simafu"] = "鬼画府",

  ["~simafu"] = "身辅六公，亦难报此恩……",
}

General:new(extension, "os__yanpu", "qun", 3):addSkills { "os__huantu", "os__bihuoy" }
Fk:loadTranslationTable{
  ["os__yanpu"] = "阎圃",
  ["#os__yanpu"] = "盱衡识势",
  ["illustrator:os__yanpu"] = "艾斯", -- 进言张鲁

  ["~os__yanpu"] = "主公……无需怀忧……",
}

General:new(extension, "os__pengyang", "shu", 3):addSkills { "os__daming", "os__xiaoni" }
Fk:loadTranslationTable{
  ["os__pengyang"] = "彭羕",
  ["#os__pengyang"] = "难别菽麦",
  ["illustrator:os__pengyang"] = "鬼画府", -- 逆言惑僚

  ["~os__pengyang"] = "一朝狂悖，自取其……死！",
}

General:new(extension, "os__guozhao", "wei", 3, 3, General.Female):addSkills { "os__yichong", "wufei" }
Fk:loadTranslationTable{
  ["os__guozhao"] = "郭女王",
  ["#os__guozhao"] = "文德皇后",
  ["illustrator:os__guozhao"] = "云涯",

  ["$wufei_os__guozhao1"] = "纵与姐姐情深，亦不可因此瞒于陛下呀！",
  ["$wufei_os__guozhao2"] = "此事颇有蹊跷，陛下还当细察。",
  ["~os__guozhao"] = "臣妾绝无虚言，陛下，陛下……",
  ["!os__guozhao"] = "哼，如此蠢物，哪是本宫的对手。",
}

General:new(extension, "os_sp__zhenji", "qun", 3, 3, General.Female):addSkills { "os__bojian", "os__jiwei" }
Fk:loadTranslationTable{
  ["os_sp__zhenji"] = "甄姬",
  ["#os_sp__zhenji"] = "明珠锦玉",
  ["illustrator:os_sp__zhenji"] = "蛋蛋", -- 红颜映雪

  ["~os_sp__zhenji"] = "袁氏既败，生死皆由将军处置。",
}

General:new(extension, "zhangyun", "qun", 4):addSkills { "os__huiyu", "os__beixing" }
Fk:loadTranslationTable{
  ["zhangyun"] = "张允",
  ["#zhangyun"] = "佞伏榻侧",
  ["~zhangyun"] = "荆襄大业，终毁于党同伐异……",
}

General:new(extension, "os_js__huangfusong", "qun", 4):addSkills { "os_js__guanhuo", "os_js__juxia" }
Fk:loadTranslationTable{
  ["os_js__huangfusong"] = "起皇甫嵩",
  ["#os_js__huangfusong"] = "安危定倾",

  ["~os_js__huangfusong"] = "一生为国纵横沙场，奈何宦海沉浮。",
}

General:new(extension, "os__qinghegongzhu", "wei", 3, 3, General.Female):addSkills { "os__zengou", "os__feili" }
Fk:loadTranslationTable{
  ["os__qinghegongzhu"] = "清河公主",
  ["#os__qinghegongzhu"] = "蛊虿之谗",
  ["illustrator:os__qinghegongzhu"] = "匠人绘", -- 魅影萦心

  ["!os__qinghegongzhu"] = "非我心狠手毒，实是夏侯楙欺人太甚。",
  ["~os__qinghegongzhu"] = "妾身所言非虚，陛下何不将其就地处死。",
}

General:new(extension, "os_thoroughbred__zhangliao", "wei", 4):addSkills { "chonglei", "os__dangshi", "zhangliao__heyu" }
Fk:loadTranslationTable{
  ["os_thoroughbred__zhangliao"] = "骥张辽",
  ["#os_thoroughbred__zhangliao"] = "气夺三军",
  ["illustrator:os_thoroughbred__zhangliao"] = "", -- 三曜同契

  ["$chonglei_os_thoroughbred__zhangliao1"] = "尔辈皆我将士，岂弃汝等不顾！",
  ["$chonglei_os_thoroughbred__zhangliao2"] = "无胆鼠辈，可识吾张辽之名！",

  ["!os_thoroughbred__zhangliao"] = "直破十万众，勇名天下惊。",
  ["~os_thoroughbred__zhangliao"] = "贼子休逃，与我再战……",
}

local cuifu = General:new(extension, "os__cuilingyi", "wei", 3, 3, General.Female)
cuifu:addSkills { "os__caiqiu", "os__xichang" }
cuifu:addRelatedSkills { "os__weizhuang", "mobile_dongjiao__weizhuang", "mobile_xiuge__weizhuang" }
Fk:loadTranslationTable{
  ["os__cuilingyi"] = "崔芙",
  ["#os__cuilingyi"] = "戴冠金尾",
}

General:new(extension, "os__guanqiujian", "wei", 3):addSkills { "os__zhengrong", "os__hongju" }
Fk:loadTranslationTable{
  ["os__guanqiujian"] = "毌丘俭",
  ["#os__guanqiujian"] = "镌功铭征荣",
  ["illustrator:os__guanqiujian"] = "猎枭", -- 平高句丽

  ["~os__guanqiujian"] = "好谋而不达，此事必有隐患。",
}

General:new(extension, "os__zhangxiu", "qun", 4):addSkills { "xiongluan", "congjian", "os__juxiang" }
Fk:loadTranslationTable{
  ["os__zhangxiu"] = "张绣",
  ["#os__zhangxiu"] = "北地枪王",
  ["illustrator:os__zhangxiu"] = "SaBBaT老魔",
}

General:new(extension, "os__luzhi", "qun", 3):addSkills { "os__mingren", "os__zhenliang" }
Fk:loadTranslationTable{
  ["os__luzhi"] = "卢植",
  ["#os__luzhi"] = "国之桢干",

  ["~os__luzhi"] = "泓泓眸子宿渊亭，不见蛾眉只见经。",
}

General:new(extension, "os__godguanyu", "god", 4):addSkills { "os__wushen", "os__wuhun" }
Fk:loadTranslationTable{
  ["os__godguanyu"] = "神关羽",
  ["#os__godguanyu"] = "鬼神再临",
  ["illustrator:os__godguanyu"] = "DH", -- 链狱鬼神

  ["~os__godguanyu"] = "我还会回来的……",
}

General:new(extension, "os__godlvmeng", "god", 3):addSkills { "os__shelie", "os__gongxin" }
Fk:loadTranslationTable{
  ["os__godlvmeng"] = "神吕蒙",
  ["#os__godlvmeng"] = "圣光之国士",
  ["illustrator:os__godlvmeng"] = "小牛",

  ["~os__godlvmeng"] = "吾能已通神，却难逆天命啊……",
}

General:new(extension, "os__liuyu", "qun", 4):addSkills { "zhige", "zongzuo", "os__chongwang" }
Fk:loadTranslationTable{
  ["os__liuyu"] = "刘虞",
  ["#os__liuyu"] = "甘棠永固",
  ["illustrator:os__liuyu"] = "青学",
}

General:new(extension, "os__xuezong", "wu", 3):addSkills { "os__funan", "os__jiexun" }
Fk:loadTranslationTable{
  ["os__xuezong"] = "薛综",
  ["#os__xuezong"] = "彬彬之玊",
  ["illustrator:os__xuezong"] = "影紫C",

  ["~os__xuezong"] = "尔等，竟做如此有辱斯文之事。",
}

General:new(extension, "os_friend__xushu", "qun", 3):addSkills { "os__xiaxing", "os__qihui", "xushu__gongli" }
Fk:loadTranslationTable{
  ["os_friend__xushu"] = "友徐庶",
  ["#os_friend__xushu"] = "潜悟诲人",
  ["illustrator:os_friend__xushu"] = "MUMU", -- 故友重逢

  ["$xushu__gongli_os_friend__xushu1"] = "终有一鸣惊高阙，君何孤愤使面沉。",
  ["$xushu__gongli_os_friend__xushu2"] = "坚苦砺身为大任，河沙淘尽始见金。",

  ["~os_friend__xushu"] = "不可同辅皇叔，实为平生大憾。",
}

General:new(extension, "os__yangfu", "wei", 3):addSkills { "os__jiebing", "os__hannan" }
Fk:loadTranslationTable{
  ["os__yangfu"] = "杨阜",
  ["#os__yangfu"] = "勇撼雄狮",
  ["illustrator:os__yangfu"] = "winnie fan", -- 公直规行

  ["~os__yangfu"] = "马贼既退，吾亦可瞑目矣……",
}

General:new(extension, "os_thoroughbred__lidian", "wei", 3):addSkills { "os__duanjin", "os__gaigong", "lidian__heyu" }
Fk:loadTranslationTable{
  ["os_thoroughbred__lidian"] = "骥李典",
  ["#os_thoroughbred__lidian"] = "义忘私隙",
  ["illustrator:os_thoroughbred__lidian"] = "佚名",

  ["~os_thoroughbred__lidian"] = "青史一笔，足慰平生。",
}

return extension
