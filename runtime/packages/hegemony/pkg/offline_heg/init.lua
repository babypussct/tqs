local extension = Package:new("offline_heg")
extension.extensionName = "hegemony"
extension.game_modes_whitelist = { "new_heg_mode" }

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/offline_heg/skills")

Fk:loadTranslationTable{
  ["offline_heg"] = "国战-线下",
  ["ofl_heg"] = "线下国战",
}

local generals = {}  --绕过变量上限的东西

generals.ofl_heg__himiko = General(extension, "ofl_heg__himiko", "qun", 3, 3, General.Female)
generals.ofl_heg__himiko:addSkills{ "guishu", "yuanyuk" }
generals.ofl_heg__himiko.headnote = "十年踪迹十年心"
Fk:loadTranslationTable{
  ["ofl_heg__himiko"] = "卑弥呼",
  ["#ofl_heg__himiko"] = "邪马台的女王",
  ["illustrator:ofl_heg__himiko"] = "聚一_小道恩",
  ["designer:ofl_heg__himiko"] = "淬毒",
  ["~ofl_heg__himiko"] = "我还会从黄泉比良坂回来的……",
}
--宗预 吕玲绮

generals.ofl_heg__xurong = General:new(extension, "ofl_heg__xurong", "qun", 4)
generals.ofl_heg__xurong:addSkill("ofl_heg__xionghuo")
generals.ofl_heg__xurong.headnote = "A015T三国杀徐荣道具尊享版"
Fk:loadTranslationTable{
  ["ofl_heg__xurong"] = "徐荣",
  ["#ofl_heg__xurong"] = "玄菟战魔",
  ["cv:ofl_heg__xurong"] = "曹真",
  ["designer:ofl_heg__xurong"] = "Loun老萌",
  ["illustrator:ofl_heg__xurong"] = "zoo",
  ["~ofl_heg__xurong"] = "死于战场……是个不错的结局……",
}

generals.ofl_heg__caocao = General:new(extension, "ofl_heg__caocao", "wei", 4)
generals.ofl_heg__caocao:addCompanions({ "hs__xuchu", "hs__dianwei" })
generals.ofl_heg__caocao:addSkills { "ofl_heg__jianxiong" }
generals.ofl_heg__caocao.headnote = "E0045群雄割据"
Fk:loadTranslationTable{
  ["ofl_heg__caocao"] = "曹操",
  ["#ofl_heg__caocao"] = "魏武帝",
  ["illustrator:ofl_heg__caocao"] = "F.源",
  ["~ofl_heg__caocao"] = "霸业未成！未成啊！",
}

generals.ofl_heg__guanqiujian = General:new(extension, "ofl_heg__guanqiujian", "wei", 4)
generals.ofl_heg__guanqiujian:addCompanions({ "ld__wenqin" })
generals.ofl_heg__guanqiujian:addSkills { "ofl_heg__zhengrong", "ofl_heg__hongju" }
generals.ofl_heg__guanqiujian.headnote = "E0045群雄割据"
Fk:loadTranslationTable{
  ["ofl_heg__guanqiujian"] = "毌丘俭",
  ["#ofl_heg__guanqiujian"] = "镌功铭征荣",
  ["illustrator:ofl_heg__guanqiujian"] = "凝聚永恒",
  ["~ofl_heg__guanqiujian"] = "峥嵘一生，然被平民所击射！",
}

generals.ofl_heg__guohuai = General:new(extension, "ofl_heg__guohuai", "wei", 4)
generals.ofl_heg__guohuai:addCompanions({ "hs__xiahouyuan", "hs__zhanghe" })
generals.ofl_heg__guohuai.mainMaxHpAdjustedValue = -1
generals.ofl_heg__guohuai:addSkills { "ofl_heg__duanshi", "ofl_heg__jingce" }
generals.ofl_heg__guohuai.headnote = "E0045群雄割据"
Fk:loadTranslationTable{
  ["ofl_heg__guohuai"] = "郭淮",
  ["#ofl_heg__guohuai"] = "垂问秦雍",
  ["illustrator:ofl_heg__guohuai"] = "心中一凛",
  ["~ofl_heg__guohuai"] = "岂料姜维……空手接箭！",
}

--朱儁 许贡 陈宫

generals.ofl_heg__huangquan = General:new(extension, "ofl_heg__huangquan", "wei", 3)
generals.ofl_heg__huangquan.subkingdom = "shu"
generals.ofl_heg__huangquan:addSkills { "ofl_heg__dianhu", "ofl_heg__jianji" }
generals.ofl_heg__huangquan.headnote = "E0045群雄割据"
Fk:loadTranslationTable{
  ["ofl_heg__huangquan"] = "黄权",
  ["#ofl_heg__huangquan"] = "道绝殊途",
  ["illustrator:ofl_heg__huangquan"] = "兴游",
  ["~ofl_heg__huangquan"] = "魏王厚待于我，降魏又有何错？",
}

--十年经典
--典韦 乐进 陆逊 太史慈 丁奉 颜良文丑 曹洪 徐盛 董卓 吕范 左慈 陆抗 钟会 孙綝 公孙渊 宗预
--晋
--毌丘俭 杜预 

generals.ofl_heg__lingcao = General:new(extension, "ofl_heg__lingcao", "wu", 4)
generals.ofl_heg__lingcao:addSkills{ "ofl_heg__dujin" }
generals.ofl_heg__lingcao.headnote = "E0048国战十年经典"
Fk:loadTranslationTable{
  ["ofl_heg__lingcao"]= "凌操",
  ["#ofl_heg__lingcao"] = "激流勇进",
  ["illustrator:ofl_heg__lingcao"] = "樱花闪乱",
  ["~ofl_heg__lingcao"] = "呃啊！（扑通）此箭……何来……",
}

generals.ofl_heg__lifeng = General:new(extension, "ofl_heg__lifeng", "shu", 3)
generals.ofl_heg__lifeng:addSkills{ "ofl_heg__tunchu", "ofl_heg__shuliang" }
generals.ofl_heg__lifeng.headnote = "E0048国战十年经典"
Fk:loadTranslationTable{
  ["ofl_heg__lifeng"] = "李丰",
  ["#ofl_heg__lifeng"] = "继父尽事",
  ["cv:ofl_heg__lifeng"] = "秦且歌",
  ["illustrator:ofl_heg__lifeng"] = "NOVART",
  ["~ofl_heg__lifeng"] = "吾，有负丞相重托。",
}
--王凌 王基 严颜 朱然 高顺

generals.ofl_heg__zhugedan = General(extension, "ofl_heg__zhugedan", "wild", 4)
generals.ofl_heg__zhugedan:addSkills { "ofl_heg__gongao" }
generals.ofl_heg__zhugedan.headnote = "E7010T国战：全武将无双"
Fk:loadTranslationTable{
  ["ofl_heg__zhugedan"] = "诸葛诞",
  ["#ofl_heg__zhugedan"] = "薤露蒿里",
  ["illustrator:ofl_heg__zhugedan"] = "雪君S",
  ["~ofl_heg__zhugedan"] = "诸葛一氏定会为我复仇！",
}

generals.ofl_heg__weiyan = General(extension, "ofl_heg__weiyan", "wild", 4)
generals.ofl_heg__weiyan:addSkills { "ofl_heg__kuanggu" }
generals.ofl_heg__weiyan.headnote = "E7010T国战：全武将无双"
Fk:loadTranslationTable{
  ["ofl_heg__weiyan"] = "魏延",
  ["#ofl_heg__weiyan"] = "嗜血的独狼",
  ["illustrator:ofl_heg__weiyan"] = "瞌瞌一休",
  ["~ofl_heg__weiyan"] = "奸贼……害我……",
}
--吕布 袁术 
generals.ofl_heg__liuyan = General(extension, "ofl_heg__liuyan", "wild", 3)
generals.ofl_heg__liuyan:addSkills { "ofl_heg__tushe", "ofl_heg__limu" }
generals.ofl_heg__liuyan.headnote = "E7010T国战：全武将无双"
Fk:loadTranslationTable{
  ["ofl_heg__liuyan"] = "刘焉",
  ["#ofl_heg__liuyan"] = "裂土之宗",
  ["illustrator:ofl_heg__liuyan"] = "心中一凛",
  ["~ofl_heg__liuyan"] = "背疮难治，世子难继。",
}

generals.ofl_heg__caoang = General(extension, "ofl_heg__caoang", "wei", 4)
generals.ofl_heg__caoang:addCompanions { "hs__caocao" }
generals.ofl_heg__caoang:addSkills { "ofl_heg__kangkai" }
generals.ofl_heg__caoang.headnote = "E7010T国战：全武将无双"
Fk:loadTranslationTable{
  ["ofl_heg__caoang"] = "曹昂",
  ["#ofl_heg__caoang"] = "取义成仁",
  ["designer:ofl_heg__caoang"] = "韩旭",
  ["illustrator:ofl_heg__caoang"] = "Zero",
  ["~ofl_heg__caoang"] = "典将军，还是你赢了……",
}

generals.ofl_heg__caochun = General(extension, "ofl_heg__caochun", "wei", 4)
generals.ofl_heg__caochun:addSkills { "ofl_heg__shanjia" }
generals.ofl_heg__caochun.headnote = "E7010T国战：全武将无双"
Fk:loadTranslationTable{
  ["ofl_heg__caochun"] = "曹纯",
  ["#ofl_heg__caochun"] = "虎豹骑首",
  ["illustrator:ofl_heg__caochun"] = "depp",
  ["~ofl_heg__caochun"] = "银甲在身，竟败于你手！",
}

generals.ofl_heg__xinxianying = General(extension, "ofl_heg__xinxianying", "wei", 3, 3, General.Female)
generals.ofl_heg__xinxianying:addSkills { "ofl_heg__caishi" }
generals.ofl_heg__xinxianying.headnote = "E7010T国战：全武将无双"
Fk:loadTranslationTable{
  ["ofl_heg__xinxianying"] = "辛宪英",
  ["#ofl_heg__xinxianying"] = "名门智女",
  ["cv:ofl_heg__xinxianying"] = "小N",
  ["illustrator:ofl_heg__xinxianying"] = "玫芍之言",
  ["~ofl_heg__xinxianying"] = "吾一生明鉴，竟错看于你。",
}
--[[
generals.ofl_heg__wenyang = General(extension, "ofl_heg__wenyang", "wei", 4)
generals.ofl_heg__wenyang.subkingdom = "wu"
generals.ofl_heg__wenyang:addSkills { "ofl_heg__quedi", "ofl_heg__chuifeng", "ofl_heg__chongjian" }
generals.ofl_heg__wenyang.headnote = "E7010T国战：全武将无双"]]
Fk:loadTranslationTable{
  ["ofl_heg__wenyang"] = "文鸯",
  ["#ofl_heg__wenyang"] = "独骑破军",
  ["illustrator:ofl_heg__wenyang"] = "鬼画府",
  ["~ofl_heg__wenyang"] = "半生功业，而见疑于一家之言，岂能无怨！",
}

generals.ofl_heg__guanyinping = General(extension, "ofl_heg__guanyinping", "shu", 3, 3, General.Female)
generals.ofl_heg__guanyinping:addCompanions { "hs__guanyu" }
generals.ofl_heg__guanyinping:addSkills { "ol__xuehen", "ofl_heg__huxiao" }
generals.ofl_heg__guanyinping.headnote = "E7010T国战：全武将无双"
Fk:loadTranslationTable{
  ["ofl_heg__guanyinping"] = "关银屏",
  ["#ofl_heg__guanyinping"] = "武姬",
  ["illustrator:ofl_heg__guanyinping"] = "木美人",
  ["~ofl_heg__guanyinping"] = "父亲，你来救我了吗……",
}

generals.ofl_heg__xingcai = General(extension, "ofl_heg__xingcai", "shu", 3, 3, General.Female)
generals.ofl_heg__xingcai:addSkills { "ol__shenxian", "ofl_heg__qiangwu" }
generals.ofl_heg__xingcai.headnote = "E7010T国战：全武将无双"
Fk:loadTranslationTable{
  ["ofl_heg__xingcai"] = "张星彩",
  ["#ofl_heg__xingcai"] = "敬哀皇后",
  ["illustrator:ofl_heg__xingcai"] = "depp",
  ["cv:ofl_heg__xingcai"] = "shourei小N",
  ["~ofl_heg__xingcai"] = "复兴汉室之路，臣妾再也不能陪伴左右了……",
}

generals.ofl_heg__guansuo = General:new(extension, "ofl_heg__guansuo", "shu", 4)
generals.ofl_heg__guansuo:addSkills { "ofl_heg__zhengnan" }
generals.ofl_heg__guansuo.headnote = "E7010T国战：全武将无双"
Fk:loadTranslationTable{
  ["ofl_heg__guansuo"] = "关索",
  ["#ofl_heg__guansuo"] = "倜傥孑侠",
  ["illustrator:ofl_heg__guansuo"] = "depp",

  ["$hs__wusheng_ofl_heg__guansuo"] = "逆贼，可识得关氏之勇？",
  ["$m_heg__dangxian_ofl_heg__guansuo"] = "各位将军，且让小辈先行出战！",
  ["$ld__zhiman_ofl_heg__guansuo"] = "蛮夷可抚，不可剿！",
  ["~ofl_heg__guansuo"] = "只恨天下未平，空留遗志。",
}

generals.ofl_heg__mizhu = General:new(extension, "ofl_heg__mizhu", "shu", 3)
generals.ofl_heg__mizhu:addSkills { "ofl_heg__ziyuan", "ofl_heg__jugu" }
generals.ofl_heg__mizhu.headnote = "E7010T国战：全武将无双"
Fk:loadTranslationTable{
  ["ofl_heg__mizhu"] = "糜竺",
  ["#ofl_heg__mizhu"] = "挥金追义",
  ["illustrator:ofl_heg__mizhu"] = "瞎子Ghe",
  ["~ofl_heg__mizhu"] = "劣弟背主，我之罪也。",
}

generals.ofl_heg__quyi = General:new(extension, "ofl_heg__quyi", "qun", 4)
generals.ofl_heg__quyi:addSkills { "fuji", "jiaozi" }
generals.ofl_heg__quyi.headnote = "E7010T国战：全武将无双"
Fk:loadTranslationTable{
  ["ofl_heg__quyi"] = "麴义",
  ["#ofl_heg__quyi"] = "名门的骁将",
  ["illustrator:ofl_heg__quyi"] = "秋呆呆",
  ["~ofl_heg__quyi"] = "我为主公戎马一生，主公为何如此对我……",
}

--鲁芝 曹婴 文鸯 关银屏 张星彩 关索 糜竺 张嫙 张媱 麹义 高览 星张郃 十常侍
--神关羽 吕蒙 诸葛亮 周瑜 曹操 吕布 赵云 司马懿 刘备 陆逊 张辽 甘宁

return extension
