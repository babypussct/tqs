local extension = Package:new("ol_mou")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_mou/skills")

Fk:loadTranslationTable{
  ["ol_mou"] = "OL-谋",
  ["olmou"] = "OL谋",
}

--谋定天下：
General:new(extension, "olmou__jiangwei", "shu", 4):addSkills { "zhuri", "ranji" }
Fk:loadTranslationTable{
  ["olmou__jiangwei"] = "谋姜维",
  ["#olmou__jiangwei"] = "炎志灼心",
  ["designer:olmou__jiangwei"] = "王秀丽",
  ["illustrator:olmou__jiangwei"] = "西国红云",

  ["$kunfenEx_olmou__jiangwei"] = "虽千万人，吾往矣！",
  ["$ol_ex__zhaxiang_olmou__jiangwei"] = "亡国之将姜维，请明公驱驰！",
  ["~olmou__jiangwei"] = "姜维姜维……又将何为？",
}

General:new(extension, "olmou__pangtong", "shu", 3):addSkills { "hongtu", "qiwu" }
Fk:loadTranslationTable{
  ["olmou__pangtong"] = "谋庞统",
  ["#olmou__pangtong"] = "定鼎巴蜀",
  ["illustrator:olmou__pangtong"] = "黯荧岛工作室",

  ["~olmou__pangtong"] = "未与孔明把酒锦官城，恨也，恨也……",
}

General:new(extension, "olmou__jiaxu", "qun", 3):addSkills { "luanchao", "wance", "chenzhij" }
Fk:loadTranslationTable{
  ["olmou__jiaxu"] = "谋贾诩",
  ["#olmou__jiaxu"] = "良平之奇",
  ["illustrator:olmou__jiaxu"] = "星七",

  ["~olmou__jiaxu"] = "愿赌……服输……",
}

General:new(extension, "olmou__zhugeliang", "shu", 3):addSkills { "zhitian", "wujingz", "zhijue" }
Fk:loadTranslationTable{
  ["olmou__zhugeliang"] = "谋诸葛亮",
  ["#olmou__zhugeliang"] = "武侯",
  ["illustrator:olmou__zhugeliang"] = "凯",

  ["~olmou__zhugeliang"] = "今败乃计拙，非天不惜汉……",
}

General:new(extension, "olmou__lusu", "wu", 3):addSkills { "duduan", "yinglue", "mengshi" }
Fk:loadTranslationTable{
  ["olmou__lusu"] = "谋鲁肃",
  ["#olmou__lusu"] = "渊谟肇石城",
  ["illustrator:olmou__lusu"] = "黯荧岛",

  ["~olmou__lusu"] = "利来利往，黄泉路上熙攘……",
}

--武动乾坤：
General:new(extension, "olmou__guanyu", "shu", 4):addSkills { "ol__weilin", "duoshou" }
Fk:loadTranslationTable{
  ["olmou__guanyu"] = "谋关羽",
  ["#olmou__guanyu"] = "威震华夏",
  ["illustrator:olmou__guanyu"] = "匠人绘",

  ["~olmou__guanyu"] = "玉碎不改白，竹焚不毁节……",
}

General:new(extension, "olmou__dongzhuo", "qun", 4):addSkills { "guanbian", "xiongni", "fengshang", "zhibing" }
Fk:loadTranslationTable{
  ["olmou__dongzhuo"] = "谋董卓",
  ["#olmou__dongzhuo"] = "翦覆四海",
  ["illustrator:olmou__dongzhuo"] = "黯荧岛",

  ["$ty_ex__fencheng_olmou__dongzhuo"] = "焚城为焰，炙脍犒三军！",
  ["~olmou__dongzhuo"] = "关东鼠辈，怎敢忤逆天命！",
}

--花好月圆：
General:new(extension, "olmou__huangyueying", "shu", 3, 3, General.Female):addSkills { "lixian", "bingcai" }
Fk:loadTranslationTable{
  ["olmou__huangyueying"] = "谋黄月英",
  ["#olmou__huangyueying"] = "才惠双绝",
  ["illustrator:olmou__huangyueying"] = "花狐貂",

  ["~olmou__huangyueying"] = "五丈原上寒风起，从此不见夜归人……",
}

General:new(extension, "olmou__xiaoqiao", "wu", 3, 3, General.Female):addSkills { "miluo", "jueyanq" }
Fk:loadTranslationTable{
  ["olmou__xiaoqiao"] = "谋小乔",
  ["#olmou__xiaoqiao"] = "醉月迷花",
  ["illustrator:olmou__xiaoqiao"] = "黯荧岛",

  ["~olmou__xiaoqiao"] = "日暮风调弦，似是故人来……",
}

General:new(extension, "olmou__zhurong", "shu", 4, 4, General.Female):addSkills { "renche", "yalian" }
Fk:loadTranslationTable{
  ["olmou__zhurong"] = "谋祝融",
  ["#olmou__zhurong"] = "见放崇山",
  --["illustrator:olmou__zhurong"] = "",

  ["~olmou__zhurong"] = "圣火……熄灭了……",
}

--计出万全：
General:new(extension, "olmou__xizhicai", "wei", 3):addSkills { "xinchuan", "jinjinx" }
Fk:loadTranslationTable{
  ["olmou__xizhicai"] = "谋戏志才",
  ["#olmou__xizhicai"] = "烬途明灯",
  ["illustrator:olmou__xizhicai"] = "川酱",
  ["designer:olmou__xizhicai"] = "玄蝶既白",

  ["~olmou__xizhicai"] = "望主公寻得那继我薪火之人……",
}


--施仁布德：
General:new(extension, "olmou__kongrong", "qun", 4):addSkills { "liwen", "ol__zhengyi" }
Fk:loadTranslationTable{
  ["olmou__kongrong"] = "谋孔融",
  ["#olmou__kongrong"] = "豪气贯长虹",
  ["illustrator:olmou__kongrong"] = "alien",

  ["~olmou__kongrong"] = "为父将去，子何以不辞？",
}

General:new(extension, "olmou__luzhi", "qun", 3, 4):addSkills { "sibing", "liance" }
Fk:loadTranslationTable{
  ["olmou__luzhi"] = "谋卢植",
  ["#olmou__luzhi"] = "弘毅抗矫",
  ["illustrator:olmou__luzhi"] = "六道目",

  ["~olmou__luzhi"] = "昔卫霍灭匈奴尚不筑京观，况乎汉家子民？",
}

--奋勇扬威：
General:new(extension, "olmou__dengai", "wei", 4, 5):addSkills { "jigud", "jiewan" }
Fk:loadTranslationTable{
  ["olmou__dengai"] = "谋邓艾",
  ["#olmou__dengai"] = "曜威奋武",
  ["illustrator:olmou__dengai"] = "阿良",

  ["~olmou__dengai"] = "钟会小儿得志，必遭天谴……",
}

General:new(extension, "olmou__taishici", "wu", 4):addSkills { "ol__dulie", "douchan" }
Fk:loadTranslationTable{
  ["olmou__taishici"] = "谋太史慈",
  ["#olmou__taishici"] = "矢志全忠孝",
  ["illustrator:olmou__taishici"] = "君桓文化",

  ["~olmou__taishici"] = "人生得遇知己，死又何憾……",
}

General:new(extension, "olmou__sunjian", "wu", 4, 5):addSkills { "hulie", "yipo" }
Fk:loadTranslationTable{
  ["olmou__sunjian"] = "谋孙坚",
  ["#olmou__sunjian"] = "乌程侯",
  ["illustrator:olmou__sunjian"] = "黯荧岛",

  ["~olmou__sunjian"] = "江东子弟们，我先走一步了……",
}

General:new(extension, "olmou__yuanshao", "qun", 4):addSkills { "yufeng", "hetao", "shenliy", "shishouy" }
Fk:loadTranslationTable{
  ["olmou__yuanshao"] = "谋袁绍",
  ["#olmou__yuanshao"] = "席卷八荒",
  ["illustrator:olmou__yuanshao"] = "西国红云",

  ["~olmou__yuanshao"] = "众人合而无力，徒负大义也……",
  --["~olmou__yuanshao2"] = "袁氏凋零，皆我一人之罪……",
}

General:new(extension, "olmou__huaxiong", "qun", 6):addSkills { "bojue", "yangwei" }
Fk:loadTranslationTable{
  ["olmou__huaxiong"] = "谋华雄",
  ["#olmou__huaxiong"] = "汜水关死神",
  ["illustrator:olmou__huaxiong"] = "黯荧岛",

  ["~olmou__huaxiong"] = "我已连战三场，匹夫胜之不武！",
}

General:new(extension, "olmou__gongsunzan", "qun", 4):addSkills { "jiaodi", "baojing" }
Fk:loadTranslationTable{
  ["olmou__gongsunzan"] = "谋公孙瓒",
  ["#olmou__gongsunzan"] = "辽海龙吟",
  ["illustrator:olmou__gongsunzan"] = "西国红云",

  ["~olmou__gongsunzan"] = "将军离魂灭，白马啸西风……",
}

General:new(extension, "olmou__wenchou", "qun", 4):addSkills { "lunzhan", "juejuew" }
Fk:loadTranslationTable{
  ["olmou__wenchou"] = "谋文丑",
  ["#olmou__wenchou"] = "万夫之勇",
  ["illustrator:olmou__wenchou"] = "错落宇宙",

  ["~olmou__wenchou"] = "何人……杀吾兄弟……",
}

General:new(extension, "olmou__zhangxiu", "qun", 4):addSkills { "zhuijiao", "choulie" }
Fk:loadTranslationTable{
  ["olmou__zhangxiu"] = "谋张绣",
  ["#olmou__zhangxiu"] = "枪啸风吟",
  ["illustrator:olmou__zhangxiu"] = "凯",

  ["~olmou__zhangxiu"] = "文和，可有良计……救我……",
}

--达权通变：
General:new(extension, "olmou__yuanshu", "qun", 4):addSkills { "jinming", "xiaoshi", "yanliangy" }
Fk:loadTranslationTable{
  ["olmou__yuanshu"] = "谋袁术",
  ["#olmou__yuanshu"] = "画脂镂冰",
  ["illustrator:olmou__yuanshu"] = "七七",

  ["~olmou__yuanshu"] = "谋事在人，奈何成事不在人……",
}

General:new(extension, "olmou__zhangrang", "qun", 3):addSkills { "lucun", "tuisheng" }
Fk:loadTranslationTable{
  ["olmou__zhangrang"] = "谋张让",
  ["#olmou__zhangrang"] = "侵威乱天常",
  ["illustrator:olmou__zhangrang"] = "奶老板",

  ["~olmou__zhangrang"] = "尔以此始，必以此终！",
  --["~olmou__zhangrang"] = "天下愦愦，非独我罪！",
  --["~olmou__zhangrang"] = "我等虽死，却也享尽这富贵荣华！",
}

General:new(extension, "olmou__xuyou", "qun", 3):addSkills { "qianfux", "yushi", "fenchao" }
Fk:loadTranslationTable{
  ["olmou__xuyou"] = "谋许攸",
  ["#olmou__xuyou"] = "帷幄擎炬",
  ["illustrator:olmou__xuyou"] = "七七",

  ["~olmou__xuyou"] = "孟德小儿，你……你过河拆桥！",
}

General:new(extension, "olmou__dongzhao", "wei", 3):addSkills { "shunji", "yishid" }
Fk:loadTranslationTable{
  ["olmou__dongzhao"] = "谋董昭",
  ["#olmou__dongzhao"] = "天阶登志",
  --["illustrator:olmou__dongzhao"] = "",

  ["~olmou__dongzhao"] = "昔小吏得凭天阶而登志，足矣。",
}

--测试服

General:new(extension, "olmou__jvshou", "qun", 3):addSkills { "guliang", "xutu" }
Fk:loadTranslationTable{
  ["olmou__jvshou"] = "谋沮授",
  ["#olmou__jvshou"] = "三军监统",
  --["illustrator:olmou__jvshou"] = "",

  --["~olmou__jvshou"] = "",
}

General:new(extension, "olmou__zhangfei", "shu", 4):addSkills { "jingxian", "xiayong" }
Fk:loadTranslationTable{
  ["olmou__zhangfei"] = "谋张飞",
  ["#olmou__zhangfei"] = "虎烈匡国",
  --["illustrator:olmou__zhangfei"] = "",

  --["~olmou__zhangfei"] = "",
}

General:new(extension, "olmou__zhaoyun", "shu", 4):addSkills { "nilan", "jueya" }
Fk:loadTranslationTable{
  ["olmou__zhaoyun"] = "谋赵云",
  ["#olmou__zhaoyun"] = "白首之心",
  --["illustrator:olmou__zhaoyun"] = "",

  --["~olmou__zhaoyun"] = "",
}

General:new(extension, "olmou__guojia", "wei", 3):addSkills { "dinglun", "jielig" }
Fk:loadTranslationTable{
  ["olmou__guojia"] = "谋郭嘉",
  ["#olmou__guojia"] = "纵才扬军",
  --["illustrator:olmou__guojia"] = "",

  --["~olmou__guojia"] = "",
}

General:new(extension, "olmou__chengyu", "wei", 3):addSkills { "liduan", "danchi" }
Fk:loadTranslationTable{
  ["olmou__chengyu"] = "谋程昱",
  ["#olmou__chengyu"] = "岁聿责谋",
  --["illustrator:olmou__chengyu"] = "",

  ["~olmou__chengyu"] = "军粮……味儿还是不对……",
}

General:new(extension, "olmou__tianfeng", "qun", 3):addSkills { "zhijiant", "xiaojie" }
Fk:loadTranslationTable{
  ["olmou__tianfeng"] = "谋田丰",
  --["#olmou__tianfeng"] = "",
  --["illustrator:olmou__tianfeng"] = "",

  --["~olmou__tianfeng"] = "",
}

General:new(extension, "olmou__zhouyu", "wu", 4):addSkills { "guqu", "zuifeng" }
Fk:loadTranslationTable{
  ["olmou__zhouyu"] = "谋周瑜",
  --["#olmou__zhouyu"] = "",
  --["illustrator:olmou__zhouyu"] = "",

  --["~olmou__zhouyu"] = "",
}

return extension
