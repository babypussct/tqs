local extension = Package:new("overseas_strategizing")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_strategizing/skills")

Fk:loadTranslationTable{
  ["overseas_strategizing"] = "国际服-运筹帷幄",
}

--智
General:new(extension, "os__dongzhao", "wei", 3):addSkills { "os__miaolue", "os__yingjia" }
Fk:loadTranslationTable{
  ["os__dongzhao"] = "董昭",
  ["#os__dongzhao"] = "陈筹定世",
  ["illustrator:os__dongzhao"] = "腥鱼仔",

  ["~os__dongzhao"] = "为曹公助书方略，实昭之幸也……",
}

General:new(extension, "os__wangcan", "wei", 3):addSkills { "os__dianyi", "os__yingji", "os__shanghe" }
Fk:loadTranslationTable{
  ["os__wangcan"] = "王粲",
  ["#os__wangcan"] = "溢才捷密",
  ["illustrator:os__wangcan"] = "青岛君桓",

  ["~os__wangcan"] = "虽无铅刀用，庶几奋薄身。",
}

General:new(extension, "os__xunchen", "qun", 3):addSkills { "os__weipo", "os__chenshi", "os__moushi" }
Fk:loadTranslationTable{
  ["os__xunchen"] = "荀谌",
  ["#os__xunchen"] = "谋刃略锋",
  ["illustrator:os__xunchen"] = "君桓文化",
  ["designer:os__xunchen"] = "Loun老萌",

  ["~os__xunchen"] = "袁公不济，吾自当以死继之……",
}

General:new(extension, "os__feiyi", "shu", 3):addSkills { "os__shengxi", "os__kuanji" }
Fk:loadTranslationTable{
  ["os__feiyi"] = "费祎",
  ["#os__feiyi"] = "蜀汉名相",
  ["designer:os__feiyi"] = "Loun老萌",
  ["illustrator:os__feiyi"] = "凝聚永恒",

  ["~os__feiyi"] = "臣请告陛下，宦权日盛，必乱社稷也。",
}

General:new(extension, "os__chenzhen", "shu", 3):addSkills { "os__muyue", "os__chayi" }
Fk:loadTranslationTable{
  ["os__chenzhen"] = "陈震",
  ["#os__chenzhen"] = "歃盟使节",
  ["illustrator:os__chenzhen"] = "君桓文化",
  ["designer:os__chenzhen"] = "Loun老萌",

  ["~os__chenzhen"] = "震不负丞相所托……",
}

General:new(extension, "os__bianfuren", "wei", 3, 3, General.Female):addSkills { "os__wanwei", "os__yuejian" }
Fk:loadTranslationTable{
  ["os__bianfuren"] = "卞夫人",
  ["#os__bianfuren"] = "内助贤后",
  ["illustrator:os__bianfuren"] = "HEI-LEI",

  ["~os__bianfuren"] = "夫君，妾身终于要随您而去了。",
}

--信
General:new(extension, "os__wangling", "wei", 4):addSkills { "os__mibei", "os__xingqi" }
Fk:loadTranslationTable{
  ["os__wangling"] = "王凌",
  ["#os__wangling"] = "风节格尚",
  ["illustrator:os__wangling"] = "游漫美绘",

  ["~os__wangling"] = "一生尽忠事魏，不料，今日晚节尽毁啊！",
}

General:new(extension, "os__huojun", "shu", 4):addSkills { "os__sidai", "os__jieyu" }
Fk:loadTranslationTable{
  ["os__huojun"] = "霍峻",
  ["#os__huojun"] = "葭萌铁狮",
  ["illustrator:os__huojun"] = "枭瞳",
  ["designer:os__huojun"] = "步穗",

  ["~os__huojun"] = "恨，不能与使君共成霸业……",
}

General:new(extension, "os__wujing", "wu", 4):addSkills { "os__fenghan", "os__congji" }
Fk:loadTranslationTable{
  ["os__wujing"] = "吴景",
  ["#os__wujing"] = "坚攻勉策",
  ["illustrator:os__wujing"] = "福州暗金",
  ["designer:os__wujing"] = "韩旭",

  ["~os__wujing"] = "合力一击，竟然也胜不了你吗……",
}

General:new(extension, "os__zhouchu", "wu", 4):addSkills { "os__guoyi", "os__chuhai" }
Fk:loadTranslationTable{
  ["os__zhouchu"] = "周处",
  ["#os__zhouchu"] = "英情天逸",
  ["illustrator:os__zhouchu"] = "MUMU",
  ["designer:os__zhouchu"] = "梦魇狂朝",

  ["~os__zhouchu"] = "改励自砥，誓除三害……",
}

General:new(extension, "os__mifuren", "shu", 3, 3, General.Female):addSkills { "mobile__guixiu", "os__qingyu" }
Fk:loadTranslationTable{
  ["os__mifuren"] = "糜夫人",
  ["#os__mifuren"] = "乱世沉香",
  ["illustrator:os__mifuren"] = "xerez",

  ["~os__mifuren"] = "",
}

General:new(extension, "os__godsunce", "god", 1, 6):addSkills { "os__yingba", "os__fuhai", "os__pinghe" }
Fk:loadTranslationTable{
  ["os__godsunce"] = "神孙策",
  ["#os__godsunce"] = "踞江鬼雄",
  ["illustrator:os__godsunce"] = "自挂东南枝", -- 搏浪涉江

  ["~os__godsunce"] = "天不助我孙氏，令我父子皆亡！啊~",
  ["!os__godsunce"] = "江东已平，待吾一扫天下，重整河山！",
}

--仁
General:new(extension, "os__xujing", "shu", 3):addSkills { "os__boming", "os__ejian" }
Fk:loadTranslationTable{
  ["os__xujing"] = "许靖",
  ["#os__xujing"] = "篡贤取良",
  ["illustrator:os__xujing"] = "凝聚永恒",

  ["~os__xujing"] = "恨，不能与使君共成霸业……",
}

General:new(extension, "os__qiaogong", "wu", 3):addSkills { "os__yizhu", "os__luanchou" }
Fk:loadTranslationTable{
  ["os__qiaogong"] = "桥公",
  ["#os__qiaogong"] = "高风硕望",
  ["illustrator:os__qiaogong"] = "三眼皮猴的万宝路", -- 得婿如龙

  ["~os__qiaogong"] = "风雨惊鸣，可怜落花万点红。",
}

General:new(extension, "os__xiangchong", "shu", 4):addSkills { "guying", "os__muzhen" }
Fk:loadTranslationTable{
  ["os__xiangchong"] = "向宠",
  ["#os__xiangchong"] = "镇军之岳",
  ["cv:os__xiangchong"] = "虞晓旭",
  ["illustrator:os__xiangchong"] = "鬼画府",

  ["~os__xiangchong"] = "蛮夷怀异，战乱难平……",
}

General:new(extension, "os__zhangwen", "wu", 3):addSkills { "os__gebo", "os__songshu" }
Fk:loadTranslationTable{
  ["os__zhangwen"] = "张温",
  ["#os__zhangwen"] = "抱德炀和",
  ["illustrator:os__zhangwen"] = "佚名", -- 衔命赴蜀

  ["~os__zhangwen"] = "为君者难，为臣者……何易？",
}

--勇
General:new(extension, "os__chenwudongxi", "wu", 4):addSkills { "os__yilie", "os__fenming" }
Fk:loadTranslationTable{
  ["os__chenwudongxi"] = "陈武董袭",
  ["#os__chenwudongxi"] = "殒身不惧",
  ["illustrator:os__chenwudongxi"] = "彭宇",

  ["~os__chenwudongxi"] = "杀身为主，死而无憾。",
}

General:new(extension, "os__zongyu", "shu", 3):addSkills { "os__zhibian", "os__yuyan" }
Fk:loadTranslationTable{
  ["os__zongyu"] = "宗预",
  ["#os__zongyu"] = "直辩无惧",
  ["illustrator:os__zongyu"] = "凝聚永恒",

  ["~os__zongyu"] = "恨，不能与使君共成霸业……",
}

General:new(extension, "os__sunyi", "wu", 4):addSkills { "os__zaoli" }
Fk:loadTranslationTable{
  ["os__sunyi"] = "孙翊",
  ["#os__sunyi"] = "骁悍激躁",
  ["illustrator:os__sunyi"] = "凡果",

  ["~os__sunyi"] = "叛我贼子，虽死亦不饶之……",
}

--严
General:new(extension, "os__jiangqin", "wu", 4):addSkills { "os__shangyi", "os__xiangyu" }
Fk:loadTranslationTable{
  ["os__jiangqin"] = "蒋钦",
  ["#os__jiangqin"] = "祁奚之器",
  ["illustrator:os__jiangqin"] = "铁杵文化",

  ["~os__jiangqin"] = "奋敌护主，成吾忠名……",
}

General:new(extension, "os__huangfusong", "qun", 4):addSkills { "os__taoluanh", "os__shiji", "os__zhengjun" }
Fk:loadTranslationTable{
  ["os__huangfusong"] = "皇甫嵩",
  ["#os__huangfusong"] = "铁血柔肠",
  ["illustrator:os__huangfusong"] = "张逸桥",

  ["~os__huangfusong"] = "天下扰攘，何日清平。",
}

General:new(extension, "os__godmachao", "god", 4):addSkills { "yuli", "os__tingwei", "os__jimie" }
Fk:loadTranslationTable{
  ["os__godmachao"] = "神马超",
  ["#os__godmachao"] = "势震九天",
  ["illustrator:os__godmachao"] = "",

  ["!os__godmachao"] = "",
  ["~os__godmachao"] = "",
}

return extension
