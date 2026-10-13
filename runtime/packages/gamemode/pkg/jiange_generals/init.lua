local extension = Package:new("jiange_generals")
extension.extensionName = "gamemode"
extension.game_modes_whitelist = {
  "jiange_mode",
}

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/jiange_generals/skills")

Fk:loadTranslationTable{
  ["jiange_generals"] = "守卫剑阁",
  ["jiange"] = "剑阁",
}

local liubei = General:new(extension, "jiange__liubei", "shu", 6)
liubei.jiange_hero = true
liubei:addSkills { "jiange__jizhen", "jiange__lingfeng", "jiange__qinzhen" }
Fk:loadTranslationTable{
  ["jiange__liubei"] = "烈帝玄德",
  ["#jiange__liubei"] = "烈帝玄德",
  ["illustrator:jiange__liubei"] = "小北风巧绘",
}

local zhugeliang = General:new(extension, "jiange__zhugeliang", "shu", 5)
zhugeliang.jiange_hero = true
zhugeliang:addSkills { "jiange__biantian", "bazhen" }
Fk:loadTranslationTable{
  ["jiange__zhugeliang"] = "天侯孔明",
  ["#jiange__zhugeliang"] = "天侯孔明",
  ["illustrator:jiange__zhugeliang"] = "小北风巧绘",
}

local huangyueying = General:new(extension, "jiange__huangyueying", "shu", 5, 5, General.Female)
huangyueying.jiange_hero = true
huangyueying:addSkills { "jiange__gongshen", "jiange__zhinang", "jiange__jingmiao" }
Fk:loadTranslationTable{
  ["jiange__huangyueying"] = "工神月英",
  ["#jiange__huangyueying"] = "工神月英",
  ["illustrator:jiange__huangyueying"] = "小北风巧绘",
}

local pangtong = General:new(extension, "jiange__pangtong", "shu", 5)
pangtong.jiange_hero = true
pangtong:addSkills { "jiange__yuhuo", "jiange__qiwu", "jiange__tianyu" }
Fk:loadTranslationTable{
  ["jiange__pangtong"] = "浴火士元",
  ["#jiange__pangtong"] = "浴火士元",
  ["illustrator:jiange__pangtong"] = "銘zmy",
}

local guanyu = General:new(extension, "jiange__guanyu", "shu", 6)
guanyu.jiange_hero = true
guanyu:addSkills { "jiange__xiaorui", "jiange__huchen", "jiange__tianjiang" }
Fk:loadTranslationTable{
  ["jiange__guanyu"] = "翊汉云长",
  ["#jiange__guanyu"] = "翊汉云长",
  ["illustrator:jiange__guanyu"] = "",
}

local zhaoyun = General:new(extension, "jiange__zhaoyun", "shu", 6)
zhaoyun.jiange_hero = true
zhaoyun:addSkills { "jiange__fengjian", "jiange__keding", "jiange__longwei" }
Fk:loadTranslationTable{
  ["jiange__zhaoyun"] = "扶危子龙",
  ["#jiange__zhaoyun"] = "扶危子龙",
  ["illustrator:jiange__zhaoyun"] = "",
}

local zhangfei = General:new(extension, "jiange__zhangfei", "shu", 5)
zhangfei.jiange_hero = true
zhangfei:addSkills { "jiange__mengwu", "jiange__hupo", "jiange__shuhun" }
Fk:loadTranslationTable{
  ["jiange__zhangfei"] = "威武翼德",
  ["#jiange__zhangfei"] = "威武翼德",
  ["illustrator:jiange__zhangfei"] = "鬼画府",
}

local huangzhong = General:new(extension, "jiange__huangzhong", "shu", 5)
huangzhong.jiange_hero = true
huangzhong:addSkills { "jiange__qixian", "jiange__jinggong", "jiange__beishi" }
Fk:loadTranslationTable{
  ["jiange__huangzhong"] = "神箭汉升",
  ["#jiange__huangzhong"] = "神箭汉升",
  ["illustrator:jiange__huangzhong"] = "一串糖葫芦",
}

local caozhen = General:new(extension, "jiange__caozhen", "wei", 5)
caozhen.jiange_hero = true
caozhen:addSkills { "jiange__chiying", "jiange__jingfan", "jiange__zhenxi" }
Fk:loadTranslationTable{
  ["jiange__caozhen"] = "佳人子丹",
  ["#jiange__caozhen"] = "佳人子丹",
  ["illustrator:jiange__caozhen"] = "小北风巧绘",
}

local simayi = General:new(extension, "jiange__simayi", "wei", 5)
simayi.jiange_hero = true
simayi:addSkills { "jiange__konghun", "jiange__fanshi", "jiange__xuanlei" }
Fk:loadTranslationTable{
  ["jiange__simayi"] = "断狱仲达",
  ["#jiange__simayi"] = "断狱仲达",
  ["illustrator:jiange__simayi"] = "小北风巧绘",
}

local xiahouyuan = General:new(extension, "jiange__xiahouyuan", "wei", 5)
xiahouyuan.jiange_hero = true
xiahouyuan:addSkills { "jiange__chuanyun", "jiange__leili", "jiange__fengxing" }
Fk:loadTranslationTable{
  ["jiange__xiahouyuan"] = "绝尘妙才",
  ["#jiange__xiahouyuan"] = "绝尘妙才",
  ["illustrator:jiange__xiahouyuan"] = "小北风巧绘",
}

local zhanghe = General:new(extension, "jiange__zhanghe", "wei", 5)
zhanghe.jiange_hero = true
zhanghe:addSkills { "jiange__huodi", "jiange__jueji" }
Fk:loadTranslationTable{
  ["jiange__zhanghe"] = "巧魁儁乂",
  ["#jiange__zhanghe"] = "巧魁儁乂",
  ["illustrator:jiange__zhanghe"] = "小北风巧绘",
}

local zhangliao = General:new(extension, "jiange__zhangliao", "wei", 5)
zhangliao.jiange_hero = true
zhangliao:addSkills { "jiange__jiaoxie", "jiange__shuailing" }
Fk:loadTranslationTable{
  ["jiange__zhangliao"] = "百计文远",
  ["#jiange__zhangliao"] = "百计文远",
  ["illustrator:jiange__zhangliao"] = "",
}

local xiahoudun = General:new(extension, "jiange__xiahoudun", "wei", 5)
xiahoudun.jiange_hero = true
xiahoudun:addSkills { "jiange__bashi", "jiange__danjing", "jiange__tongjun" }
Fk:loadTranslationTable{
  ["jiange__xiahoudun"] = "枯目元让",
  ["#jiange__xiahoudun"] = "枯目元让",
  ["illustrator:jiange__xiahoudun"] = "",
}

local dianwei = General:new(extension, "jiange__dianwei", "wei", 5)
dianwei.jiange_hero = true
dianwei:addSkills { "jiange__yingji", "jiange__zhene", "jiange__weizhu" }
Fk:loadTranslationTable{
  ["jiange__dianwei"] = "古之恶来",
  ["#jiange__dianwei"] = "古之恶来",
  ["illustrator:jiange__dianwei"] = "鬼画府",
}

local yujin = General:new(extension, "jiange__yujin", "wei", 5)
yujin.jiange_hero = true
yujin:addSkills { "jiange__hanjun", "jiange__pigua", "jiange__zhengji" }
Fk:loadTranslationTable{
  ["jiange__yujin"] = "毅勇文则",
  ["#jiange__yujin"] = "毅勇文则",
  ["illustrator:jiange__yujin"] = "XXX",
}

local qinglong = General:new(extension, "jiange__qinglong", "shu", 5)
qinglong.jiange_machine = true
qinglong:addSkills { "jiange__mojian", "jiange__jiguan" }
Fk:loadTranslationTable{
  ["jiange__qinglong"] = "云屏青龙",
  ["#jiange__qinglong"] = "云屏青龙",
}

local baihu = General:new(extension, "jiange__baihu", "shu", 5)
baihu.jiange_machine = true
baihu:addSkills { "jiange__zhenwei", "jiange__benlei", "jiange__jiguan" }
Fk:loadTranslationTable{
  ["jiange__baihu"] = "机雷白虎",
  ["#jiange__baihu"] = "机雷白虎",
}

local zhuque = General:new(extension, "jiange__zhuque", "shu", 5, 5, General.Female)
zhuque.jiange_machine = true
zhuque:addSkills { "jiange__tianyun", "jiange__yuhuo", "jiange__jiguan" }
Fk:loadTranslationTable{
  ["jiange__zhuque"] = "炽羽朱雀",
  ["#jiange__zhuque"] = "炽羽朱雀",
}

local xuanwu = General:new(extension, "jiange__xuanwu", "shu", 5)
xuanwu.jiange_machine = true
xuanwu:addSkills { "yizhong", "jiange__jiguan", "jiange__lingyu" }
Fk:loadTranslationTable{
  ["jiange__xuanwu"] = "灵甲玄武",
  ["#jiange__xuanwu"] = "灵甲玄武",
}

local bihan = General:new(extension, "jiange__bihan", "wei", 5)
bihan.jiange_machine = true
bihan:addSkills { "jiange__didong", "jiange__jiguan" }
Fk:loadTranslationTable{
  ["jiange__bihan"] = "缚地狴犴",
  ["#jiange__bihan"] = "缚地狴犴",
}

local suanni = General:new(extension, "jiange__suanni", "wei", 4)
suanni.jiange_machine = true
suanni:addSkills { "jiange__jiguan", "jiange__lianyu" }
Fk:loadTranslationTable{
  ["jiange__suanni"] = "食火狻猊",
  ["#jiange__suanni"] = "食火狻猊",
}

local chiwen = General:new(extension, "jiange__chiwen", "wei", 6)
chiwen.jiange_machine = true
chiwen:addSkills { "jiange__jiguan", "jiange__tanshi", "jiange__tunshi" }
Fk:loadTranslationTable{
  ["jiange__chiwen"] = "吞天螭吻",
  ["#jiange__chiwen"] = "吞天螭吻",
}

local yazi = General:new(extension, "jiange__yazi", "wei", 6)
yazi.jiange_machine = true
yazi:addSkills { "jiange__jiguan", "jiange__nailuo" }
Fk:loadTranslationTable{
  ["jiange__yazi"] = "裂石睚眦",
  ["#jiange__yazi"] = "裂石睚眦",
}

return extension
