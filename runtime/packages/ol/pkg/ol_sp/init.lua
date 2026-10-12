local extension = Package:new("ol_sp_pack")
extension.extensionName = "ol"

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_sp/skills")

Fk:loadTranslationTable{
  ["ol_sp_pack"] = "OL-SP",
  ["ol_sp"] = "OLSP",
}

General:new(extension, "ol_sp__guanyu", "wei", 4):addSkills { "ex__wusheng", "danji" }
Fk:loadTranslationTable{
  ["ol_sp__guanyu"] = "关羽",
  ["#ol_sp__guanyu"] = "汉寿亭侯",
  ["illustrator:ol_sp__guanyu"] = "折原",

  ["$ex__wusheng_ol_sp__guanyu1"] = "以义传魂，以武入圣！",
  ["$ex__wusheng_ol_sp__guanyu2"] = "义击逆流，武安黎庶！",
  ["~ol_sp__guanyu"] = "樊城一去，死亦无惧！",
}

General:new(extension, "ol_sp__machao", "qun", 4):addSkills { "ol__zhuiji", "ol__shichou" }
Fk:loadTranslationTable{
  ["ol_sp__machao"] = "马超",
  ["#ol_sp__machao"] = "西凉的猛狮",
  ["illustrator:ol_sp__machao"] = "凝聚永恒",

  ["~ol_sp__machao"] = "父亲！父亲！！",
}

General:new(extension, "ol_sp__jiaxu", "wei", 3):addSkills { "zhenlue", "ol__jianshu", "ol__yongdi" }
Fk:loadTranslationTable{
  ["ol_sp__jiaxu"] = "贾诩",
  ["#ol_sp__jiaxu"] = "算无遗策",
  ["illustrator:ol_sp__jiaxu"] = "魔奇士",
}

General:new(extension, "ol_sp__caoren", "wei", 4):addSkills { "weikui", "lizhan" }
Fk:loadTranslationTable{
  ["ol_sp__caoren"] = "曹仁",
  ["#ol_sp__caoren"] = "鬼神之勇",
  ["illustrator:ol_sp__caoren"] = "张华",

  ["~ol_sp__caoren"] = "城在人在，城破人亡。",
}

General:new(extension, "ol__wanglang", "wei", 3):addSkills { "gushe", "ol__jici" }
Fk:loadTranslationTable{
  ["ol__wanglang"] = "王朗",
  ["#ol__wanglang"] = "凤鹛",
  ["illustrator:ol__wanglang"] = "凡果",

  ["$gushe_ol__wanglang1"] = "万姓倾心，四方仰德。",
  ["$gushe_ol__wanglang2"] = "饶舌之蛊心，敌自败也！",
  ["~ol__wanglang"] = "荒谬之言！荒谬之言！",
}

General:new(extension, "ol_sp__zhanghe", "qun", 4):addSkills { "zhouxuanz" }
Fk:loadTranslationTable{
  ["ol_sp__zhanghe"] = "张郃",
  ["#ol_sp__zhanghe"] = "倾柱覆州",
  ["designer:ol_sp__zhanghe"] = "七哀",
  ["illustrator:ol_sp__zhanghe"] = "君桓文化",

  ["~ol_sp__zhanghe"] = "我终究是看不透这人心。",
}

General:new(extension, "ol_sp__huangyueying", "qun", 3, 3, General.Female):addSkills { "ol__jiqiao", "ol__linglong" }
Fk:loadTranslationTable{
  ["ol_sp__huangyueying"] = "黄月英",
  ["#ol_sp__huangyueying"] = "闺中璞玉",
  ["illustrator:ol_sp__huangyueying"] = "杨杨和夏季",

  ["~ol_sp__huangyueying"] = "世人难容有才之女……",
}

General:new(extension, "ol_sp__zhangliao", "qun", 4):addSkills { "mubing", "ziqu", "diaoling" }
Fk:loadTranslationTable{
  ["ol_sp__zhangliao"] = "张辽",
  ["#ol_sp__zhangliao"] = "功果显名",
  ["illustrator:ol_sp__zhangliao"] = "君桓文化",

  ["~ol_sp__zhangliao"] = "孤军难鸣，进退维谷。",
}

General:new(extension, "ol_sp__menghuo", "qun", 4):addSkills { "manwang" }
Fk:loadTranslationTable{
  ["ol_sp__menghuo"] = "孟获",
  ["#ol_sp__menghuo"] = "夷汉并服",
  ["designer:ol_sp__menghuo"] = "玄蝶既白",
  ["illustrator:ol_sp__menghuo"] = "君桓文化",

  ["~ol_sp__menghuo"] = "有材而得生，无材而得纵……",
}

General:new(extension, "ol__puyuan", "shu", 4):addSkills { "shengong", "qisi" }
Fk:loadTranslationTable{
  ["ol__puyuan"] = "蒲元",
  ["#ol__puyuan"] = "鬼斧神工",
  ["illustrator:ol__puyuan"] = "君桓文化",

  ["~ol__puyuan"] = "锻兵万千，不及造屋二三……",
}

General:new(extension, "ol__zhouqun", "shu", 4):addSkills { "chenshuo", "tianhou" }
Fk:loadTranslationTable{
  ["ol__zhouqun"] = "周群",
  ["#ol__zhouqun"] = "后圣",
  ["illustrator:ol__zhouqun"] = "鬼画府",

  ["~ol__zhouqun"] = "知万物而不知己命，大谬也……",
}

General:new(extension, "ol__peixiu", "wei", 4):addSkills { "maozhu", "jinlan", "caifeng" }
extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_sp/peixiu_skills")
Fk:loadTranslationTable{
  ["ol__peixiu"] = "裴秀",
  ["#ol__peixiu"] = "雅量弘博",
  ["illustrator:ol__peixiu"] = "塔普",

  ["~ol__peixiu"] = "此酒微寒，不妨入腹。",
}

General:new(extension, "ol_sp__sunce", "qun", 4):addSkills { "liantao" }
Fk:loadTranslationTable{
  ["ol_sp__sunce"] = "孙策",
  ["#ol_sp__sunce"] = "壮武命世",
  ["illustrator:ol_sp__sunce"] = "君桓文化",
  ["designer:ol_sp__sunce"] = "韩旭",

  ["~ol_sp__sunce"] = "身受百创，力难从心……",
}

General:new(extension, "ol_sp__caocao", "qun", 4):addSkills { "xixiang", "aige" }
Fk:loadTranslationTable{
  ["ol_sp__caocao"] = "曹操",
  ["#ol_sp__caocao"] = "踌躇的孤雁",
  ["illustrator:ol_sp__caocao"] = "错落宇宙",

  ["~ol_sp__caocao"] = "尔等，算什么大汉忠臣！",
}

General:new(extension, "ol_sp__liubei", "qun", 4):addSkills { "xudai", "zhujiu", "jinglei" }
Fk:loadTranslationTable{
  ["ol_sp__liubei"] = "刘备",
  ["#ol_sp__liubei"] = "潜龙勿用",
  ["illustrator:ol_sp__liubei"] = "凯",

  ["~ol_sp__liubei"] = "一介凡夫俗子，不识龙为何物。",
}

General:new(extension, "ol__nanhualaoxian", "qun", 3):addSkills { "qingshu", "ol__shoushu", "hedao" }
Fk:loadTranslationTable{
  ["ol__nanhualaoxian"] = "南华老仙",
  ["#ol__nanhualaoxian"] = "逍遥仙游",
  ["illustrator:ol__nanhualaoxian"] = "黯荧岛",

  ["~ol__nanhualaoxian"] = "尔生异心，必获恶报！",
}

local tianshu_skels = require("packages.ol.pkg.ol_sp.skills.tianshu.tianshu")
for _, skel in ipairs(tianshu_skels) do
  table.insert(extension.skill_skels, skel)
end

General:new(extension, "ol__miheng", "qun", 3):addSkills { "kuangjuan", "feibian" }
Fk:loadTranslationTable{
  ["ol__miheng"] = "祢衡",
  ["#ol__miheng"] = "狂才傲世",

  ["~ol__miheng"] = "天地虽大，难容我狂……",
}

return extension
