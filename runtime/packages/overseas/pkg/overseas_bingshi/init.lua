local extension = Package:new("overseas_bingshi")
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_bingshi/skills")

Fk:loadTranslationTable{
  ["overseas_bingshi"] = "国际服-兵势篇",
  ["os_shi"] = "国际势",
}

General:new(extension, "os_shi__yuji", "qun", 3):addSkills { "os__fujiy", "daozhuan" }
Fk:loadTranslationTable{
  ["os_shi__yuji"] = "势于吉",
  ["#os_shi__yuji"] = "夙仙望道",
  ["illustrator:os_shi__yuji"] = "",

  ["~os_shi__yuji"] = "",
  ["!os_shi__yuji"] = "",
}

General:new(extension, "os_shi__taishici", "wu", 4):addSkills { "os__hanzhan", "os__zhanlie", "os__zhenfeng" }
Fk:loadTranslationTable{
  ["os_shi__taishici"] = "势太史慈",
  ["#os_shi__taishici"] = "志踏天阶",
  ["illustrator:os_shi__taishici"] = "铁杵",

  ["~os_shi__taishici"] = "",
  ["!os_shi__taishici"] = "",
}

General:new(extension, "os_shi__chendao", "shu", 4):addSkills { "mobile__wangliec", "os__hongyic" }
Fk:loadTranslationTable{
  ["os_shi__chendao"] = "势陈到",
  ["#os_shi__chendao"] = "白毦督",
  ["illustrator:os_shi__chendao"] = "",

  ["~os_shi__chendao"] = "",
}

local huanjie = General:new(extension, "os_shi__huanjie", "wei", 4)
huanjie:addSkills { "os_shi__gongmou", "zhengshuo" }
huanjie.shield = 1
Fk:loadTranslationTable{
  ["os_shi__huanjie"] = "势桓阶",
  ["#os_shi__huanjie"] = "才周托命",
  ["illustrator:os_shi__huanjie"] = "三眼皮猴的万宝路", -- 定计谋国

  ["$zhengshuo_os_shi__huanjie1"] = "今新建皇统，宜稽古典先代，以从天命。",
  ["$zhengshuo_os_shi__huanjie2"] = "今告朔牺牲，一皆不改，非所以明革命之义。",
  ["$qice_os_shi__huanjie1"] = "而今进退两难，唯以险计求胜。",
  ["$qice_os_shi__huanjie2"] = "公虽兵寡势弱，亦可奇策制敌。",
  ["!os_shi__huanjie"] = "观乎天文以察时变，观乎人文以化成天下。",
  ["~os_shi__huanjie"] = "家以俭成，国以奢败，尔等勉之，勉之。",
}

General:new(extension, "os_shi__luyusheng", "wu", 3, 3, General.Female):addSkills { "mobile__runwei", "os__shuanghuai" }
Fk:loadTranslationTable{
  ["os_shi__luyusheng"] = "势陆郁生",
  ["#os_shi__luyusheng"] = "义姑",
  ["illustrator:os_shi__luyusheng"] = "荧光笔",

  ["$mobile__runwei_os_shi__luyusheng1"] = "虽不及天雨之宽，亦可润所过之物。",
  ["$mobile__runwei_os_shi__luyusheng2"] = "微如春风拂面，然可送暖人间。",
  ["$mobile__runwei_os_shi__luyusheng3"] = "君等何急？妾身再助一臂之力。",
  ["$mobile__runwei_os_shi__luyusheng4"] = "妾身纵有小损又何妨。",

  ["!os_shi__luyusheng"] = "夫君安心且去，妾身必抚养叔妹长大成人。",
  ["~os_shi__luyusheng"] = "妾身所念甚多，叔妹最是难舍。",
}

return extension
