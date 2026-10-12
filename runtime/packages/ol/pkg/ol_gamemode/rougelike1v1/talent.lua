local RougeUtil = require "packages.ol.pkg.ol_gamemode.rougelike1v1.util"

-- 增加虎符相关
RougeUtil:addBuffTalent { 3, "rouge_bingquanzaiwo1" }
RougeUtil:addBuffTalent { 4, "rouge_bingquanzaiwo2" }
RougeUtil:addBuffTalent { 2, "rouge_chijiuzhan2" }

Fk:loadTranslationTable {
  ["rouge_chijiuzhan2"] = "持久战Ⅱ",
  [":rouge_chijiuzhan2"] = "虎符数量达到5后，每回合获得的虎符数+1",
  ["rouge_bingquanzaiwo1"] = "兵权在握Ⅰ",
  [":rouge_bingquanzaiwo1"] = "自己的自然回合获得的虎符数+1",
  ["rouge_bingquanzaiwo2"] = "兵权在握Ⅱ",
  [":rouge_bingquanzaiwo2"] = "每个自然回合获得的虎符数+1",
}

-- 商店：领取初始战法后，刷新商店；回合结束时，购买并刷新商店
-- TODO: 再说吧

-- 即时效果
-- 喜从天降

RougeUtil:addTalent { 0, "rouge_xicongtianjiang", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  RougeUtil.changeMoney(player, 1)
end }
RougeUtil:addTalent { 0, "rouge_xicongtianjiang2", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  RougeUtil.changeMoney(player, 2)
end }
Fk:loadTranslationTable {
  ["rouge_xicongtianjiang"] = "喜从天降Ⅰ",
  [":rouge_xicongtianjiang"] = "获得1个虎符",
  ["rouge_xicongtianjiang2"] = "喜从天降Ⅱ",
  [":rouge_xicongtianjiang2"] = "获得2个虎符",
}

-- 增寿

RougeUtil:addTalent { 2, "rouge_zengshou1", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 1)
end }
RougeUtil:addTalent { 4, "rouge_zengshou2", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 2)
end }
Fk:loadTranslationTable {
  ["rouge_zengshou1"] = "增寿Ⅰ",
  [":rouge_zengshou1"] = "体力上限+1",
  ["rouge_zengshou2"] = "增寿Ⅱ",
  [":rouge_zengshou2"] = "体力上限+2",
}

-- 体魄

RougeUtil:addTalent { 3, "rouge_tipo1", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 1)
  if player:isWounded() then
    player.room:recover {
      who = player,
      num = 1,
      skillName = self,
    }
  end
end }
RougeUtil:addTalent { 4, "rouge_tipo2", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 2)
  if player:isWounded() then
    player.room:recover {
      who = player,
      num = 2,
      skillName = self,
    }
  end
end }
RougeUtil:addTalent { 4, "rouge_tipo3", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 3)
  if player:isWounded() then
    player.room:recover {
      who = player,
      num = 3,
      skillName = self,
    }
  end
end }
Fk:loadTranslationTable {
  ["rouge_tipo1"] = "体魄Ⅰ",
  [":rouge_tipo1"] = "增加1点体力上限并回复等量体力",
  ["rouge_tipo2"] = "体魄Ⅱ",
  [":rouge_tipo2"] = "增加2点体力上限并回复等量体力",
  ["rouge_tipo3"] = "体魄Ⅲ",
  [":rouge_tipo3"] = "增加3点体力上限并回复等量体力",
}

-- 天降！

RougeUtil:addTalent { 2, "rouge_tianjiang__trick", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  local room = player.room
  local cards = room:getCardsFromPileByRule('.|.|.|.|.|trick', 3, "allPiles")
  if #cards > 0 then room:obtainCard(player, cards, true, fk.ReasonPrey, player, self) end
end }
RougeUtil:addTalent { 2, "rouge_tianjiang__basic", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  local room = player.room
  local cards = room:getCardsFromPileByRule('.|.|.|.|.|basic', 4, "allPiles")
  if #cards > 0 then room:obtainCard(player, cards, true, fk.ReasonPrey, player, self) end
end }
RougeUtil:addTalent { 2, "rouge_tianjiang__equip", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  local room = player.room
  local cards = room:getCardsFromPileByRule('.|.|.|.|.|equip', 4, "allPiles")
  if #cards > 0 then room:obtainCard(player, cards, true, fk.ReasonPrey, player, self) end
end }
RougeUtil:addTalent { 2, "rouge_tianjiang__any", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  local room = player.room
  local cards = room:getCardsFromPileByRule('.', 3, "allPiles")
  if #cards > 0 then room:obtainCard(player, cards, true, fk.ReasonPrey, player, self) end
end }
Fk:loadTranslationTable {
  ["rouge_tianjiang__trick"] = "天降锦囊",
  [":rouge_tianjiang__trick"] = "获取3张锦囊牌",
  ["rouge_tianjiang__basic"] = "天降横财",
  [":rouge_tianjiang__basic"] = "获取4张基本牌",
  ["rouge_tianjiang__equip"] = "天降装备",
  [":rouge_tianjiang__equip"] = "获取4张装备牌",
  ["rouge_tianjiang__any"] = "天降卡牌",
  [":rouge_tianjiang__any"] = "获取3张牌",
}

-- 铁布衫

RougeUtil:addTalent { 1, "rouge_tiebushan1", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeShield(player, 1)
end }
RougeUtil:addTalent { 2, "rouge_tiebushan2", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeShield(player, 2)
end }
RougeUtil:addTalent { 4, "rouge_tiebushan3", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeShield(player, 4)
end }
Fk:loadTranslationTable {
  ["rouge_tiebushan1"] = "铁布衫Ⅰ",
  [":rouge_tiebushan1"] = "获得1点护甲",
  ["rouge_tiebushan2"] = "铁布衫Ⅱ",
  [":rouge_tiebushan2"] = "获得2点护甲",
  ["rouge_tiebushan3"] = "铁布衫Ⅲ",
  [":rouge_tiebushan3"] = "获得4点护甲",
}

-- 士气剥夺

RougeUtil:addTalent { 3, "rouge_shiqiboduo", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player)) do
    if RougeUtil.isEnemy(player, p, player.room) and p.maxHp > 1 then
      player.room:changeMaxHp(p, -1)
    end
  end
end }
Fk:loadTranslationTable {
  ["rouge_shiqiboduo"] = "士气剥夺",
  [":rouge_shiqiboduo"] = "所有敌方的体力上限-1（最低减至1）",
}

-- 阶段/回合/轮数开始相关：搬运、博闻、...

RougeUtil:addBuffTalent { 1, "rouge_leiming" }




RougeUtil:addBuffTalent { 2, "rouge_banyun" }
RougeUtil:addBuffTalent { 3, "rouge_bowen1" }
RougeUtil:addBuffTalent { 4, "rouge_bowen2" }
RougeUtil:addBuffTalent { 4, "rouge_bowen3" }
RougeUtil:addBuffTalent { 2, "rouge_fuyiqu__slash" }
RougeUtil:addBuffTalent { 2, "rouge_fuyiqu__fire_attack" }
RougeUtil:addBuffTalent { 2, "rouge_fuyiqu__jink" }
RougeUtil:addBuffTalent { 3, "rouge_fuyiqu__peach" }
RougeUtil:addBuffTalent { 3, "rouge_fuyiqu__dismantlement" }
RougeUtil:addBuffTalent { 3, "rouge_fuyiqu__duel" }
RougeUtil:addBuffTalent { 3, "rouge_fuyiqu__iron_chain" }
RougeUtil:addBuffTalent { 4, "rouge_fuyiqu__snatch" }
RougeUtil:addBuffTalent { 1, "rouge_fenjin" }
RougeUtil:addBuffTalent { 1, "rouge_yuanmou1" }
RougeUtil:addBuffTalent { 2, "rouge_yuanmou2" }
RougeUtil:addBuffTalent { 1, "rouge_yuanmou3" }



RougeUtil:addBuffTalent { 3, "rouge_hujia" }
RougeUtil:addBuffTalent { 4, "rouge_hujia2" }

RougeUtil:addBuffTalent { 1, "rouge_xuezhan1", function(self, player)
  local num = math.max(-1, 1 - player.maxHp)
  if num < 0 then
    RougeUtil.sendTalentLog(player, self)
    player.room:changeMaxHp(player, num)
  end
end }
RougeUtil:addBuffTalent { 2, "rouge_xuezhan2", function(self, player)
  local num = math.max(-2, 1 - player.maxHp)
  if num < 0 then
    RougeUtil.sendTalentLog(player, self)
    player.room:changeMaxHp(player, num)
  end
end }
RougeUtil:addBuffTalent { 4, "rouge_xuezhan3", function(self, player)
  local num = math.max(-3, 1 - player.maxHp)
  if num < 0 then
    RougeUtil.sendTalentLog(player, self)
    player.room:changeMaxHp(player, num)
  end
end }




Fk:loadTranslationTable {
  ["rouge_banyun"] = "搬运",
  [":rouge_banyun"] = "你的回合开始时，从随机敌方手牌区获得一张牌",
  ["rouge_bowen1"] = "博闻Ⅰ",
  [":rouge_bowen1"] = "你的回合开始时，从牌堆中获得1张随机锦囊牌",
  ["rouge_bowen2"] = "博闻Ⅱ",
  [":rouge_bowen2"] = "你的回合开始时，从牌堆中获得2张随机锦囊牌",
  ["rouge_bowen3"] = "博闻Ⅲ",
  [":rouge_bowen3"] = "你的回合开始时，从牌堆中获得3张随机锦囊牌",

  ["rouge_fuyiqu__slash"] = "拂衣去杀",
  [":rouge_fuyiqu__slash"] = "你的回合开始时，你获得1张【杀】",
  ["rouge_fuyiqu__fire_attack"] = "拂衣去火",
  [":rouge_fuyiqu__fire_attack"] = "你的回合开始时，你获得1张【火攻】",
  ["rouge_fuyiqu__jink"] = "拂衣去闪",
  [":rouge_fuyiqu__jink"] = "你的回合开始时，你获得1张【闪】",
  ["rouge_fuyiqu__peach"] = "拂衣去桃",
  [":rouge_fuyiqu__peach"] = "你的回合开始时，你获得1张【桃】",
  ["rouge_fuyiqu__dismantlement"] = "拂衣去拆",
  [":rouge_fuyiqu__dismantlement"] = "你的回合开始时，你获得1张【过河拆桥】",
  ["rouge_fuyiqu__duel"] = "拂衣去决",
  [":rouge_fuyiqu__duel"] = "你的回合开始时，你获得1张【决斗】",
  ["rouge_fuyiqu__iron_chain"] = "拂衣去锁",
  [":rouge_fuyiqu__iron_chain"] = "你的回合开始时，你获得1张【铁索连环】",
  ["rouge_fuyiqu__snatch"] = "拂衣去顺",
  [":rouge_fuyiqu__snatch"] = "你的回合开始时，你获得1张【顺手牵羊】",

  ["rouge_fenjin"] = "奋进",
  [":rouge_fenjin"] = "当体力大于2点，回合开始时失去1点体力并摸两张牌",

  ["rouge_yuanmou1"] = "远谋Ⅰ",
  [":rouge_yuanmou1"] = "第3轮你的回合开始时，你回复2点体力",
  ["rouge_yuanmou2"] = "远谋Ⅱ",
  [":rouge_yuanmou2"] = "第3轮你的回合开始时，你回复3点体力",
  ["rouge_yuanmou3"] = "远谋Ⅲ",
  [":rouge_yuanmou3"] = "第2轮你的回合开始时，你回复2点体力",

  ["rouge_hujia"] = "护甲Ⅰ",
  [":rouge_hujia"] = "每轮开始时，你获得1点护甲",
  ["rouge_hujia2"] = "护甲Ⅱ",
  [":rouge_hujia2"] = "每轮开始时，你获得2点护甲",

  ["rouge_xuezhan1"] = "血战Ⅰ",
  [":rouge_xuezhan1"] = "体力上限-1（最低为1），每轮开始时回复1点体力",
  ["rouge_xuezhan2"] = "血战Ⅱ",
  [":rouge_xuezhan2"] = "体力上限-2（最低为1），每轮开始时回复2点体力",
  ["rouge_xuezhan3"] = "血战Ⅲ",
  [":rouge_xuezhan3"] = "体力上限-3（最低为1），每轮开始时回复3点体力",

  ["rouge_leiming"] = "雷鸣",
  [":rouge_leiming"] = "所有角色在判定阶段都要进行一次【闪电】判定",
}

-- 额定摸牌数相关：布阵、...

RougeUtil:addBuffTalent { 2, "rouge_buzhen1" }
RougeUtil:addBuffTalent { 1, "rouge_buzhen2" }
RougeUtil:addBuffTalent { 1, "rouge_buzhen3" }
RougeUtil:addBuffTalent { 3, "rouge_duanliangcao2" }
RougeUtil:addBuffTalent { 2, "rouge_chijiuzhan3" }
RougeUtil:addBuffTalent { 1, "rouge_kuangbao3" }
RougeUtil:addBuffTalent { 2, "rouge_kuangbao4" }
RougeUtil:addBuffTalent { 2, "rouge_mopai1" }
RougeUtil:addBuffTalent { 4, "rouge_mopai2" }
RougeUtil:addBuffTalent { 2, "rouge_houfaxianzhi" }
RougeUtil:addBuffTalent { 3, "rouge_muniuliuma" }
RougeUtil:addBuffTalent { 4, "rouge_wendinghouqin" }

Fk:loadTranslationTable {
  ["rouge_buzhen1"] = "布阵Ⅰ",
  [":rouge_buzhen1"] = "从第3轮开始，你的摸牌数+1",
  ["rouge_buzhen2"] = "布阵Ⅱ",
  [":rouge_buzhen2"] = "从第5轮开始，你的摸牌数+1",
  ["rouge_buzhen3"] = "布阵Ⅲ",
  [":rouge_buzhen3"] = "从第7轮开始，你的摸牌数+1",

  ["rouge_duanliangcao2"] = "断粮草Ⅱ",
  [":rouge_duanliangcao2"] = "敌方摸牌数-1",

  ["rouge_chijiuzhan3"] = "持久战Ⅲ",
  [":rouge_chijiuzhan3"] = "虎符数量达到7后，摸牌数+1",

  ["rouge_kuangbao3"] = "狂暴Ⅲ",
  [":rouge_kuangbao3"] = "当你的体力值不大于3时，你摸牌数+1",
  ["rouge_kuangbao4"] = "狂暴Ⅳ",
  [":rouge_kuangbao4"] = "当你的体力值不大于5时，你摸牌数+1",

  ["rouge_mopai1"] = "摸牌Ⅰ",
  [":rouge_mopai1"] = "摸牌阶段，你的摸牌数+1",
  ["rouge_mopai2"] = "摸牌Ⅱ",
  [":rouge_mopai2"] = "摸牌阶段，你的摸牌数+2",

  ["rouge_houfaxianzhi"] = "后发先至",
  [":rouge_houfaxianzhi"] = "摸牌阶段，你的摸牌数-1；你的回合结束时，你摸3张牌",

  ["rouge_muniuliuma"] = "木牛流马",
  [":rouge_muniuliuma"] = "摸牌阶段，你额外摸两张牌。你的手牌上限-1",

  ["rouge_wendinghouqin"] = "稳定后勤",
  [":rouge_wendinghouqin"] = "摸牌阶段摸牌数固定为5",
}

-- 即时摸牌相关：二生三、...

RougeUtil:addBuffTalent { 1, "rouge_ershengsan" }


RougeUtil:addBuffTalent { 2, "rouge_jinnangji" }


Fk:loadTranslationTable {
  ["rouge_buzhen1"] = "布阵Ⅰ",
  [":rouge_buzhen1"] = "从第3轮开始，你的摸牌数+1",
  ["rouge_buzhen2"] = "布阵Ⅱ",
  [":rouge_buzhen2"] = "从第5轮开始，你的摸牌数+1",
  ["rouge_buzhen3"] = "布阵Ⅲ",
  [":rouge_buzhen3"] = "从第7轮开始，你的摸牌数+1",

  ["rouge_duanliangcao2"] = "断粮草Ⅱ",
  [":rouge_duanliangcao2"] = "敌方摸牌数-1",

  ["rouge_chijiuzhan3"] = "持久战Ⅲ",
  [":rouge_chijiuzhan3"] = "虎符数量达到7后，摸牌数+1",

  ["rouge_kuangbao3"] = "狂暴Ⅲ",
  [":rouge_kuangbao3"] = "当你的体力值不大于3时，你摸牌数+1",
  ["rouge_kuangbao4"] = "狂暴Ⅳ",
  [":rouge_kuangbao4"] = "当你的体力值不大于5时，你摸牌数+1",

  ["rouge_mopai1"] = "摸牌Ⅰ",
  [":rouge_mopai1"] = "摸牌阶段，你的摸牌数+1",
  ["rouge_mopai2"] = "摸牌Ⅱ",
  [":rouge_mopai2"] = "摸牌阶段，你的摸牌数+2",

  ["rouge_houfaxianzhi"] = "后发先至",
  [":rouge_houfaxianzhi"] = "摸牌阶段，你的摸牌数-1；你的回合结束时，你摸3张牌",

  ["rouge_muniuliuma"] = "木牛流马",
  [":rouge_muniuliuma"] = "你的摸牌阶段，你额外摸2张牌,手牌上限-1",

  ["rouge_wendinghouqin"] = "稳定后勤",
  [":rouge_wendinghouqin"] = "摸牌阶段摸牌数固定为5",

  ["rouge_jinnangji"] = "锦囊计",
  [":rouge_jinnangji"] = "手牌上限+X（X为本回合摸牌阶段摸牌数的一半）",

  ["rouge_ershengsan"] = "二生三",
  [":rouge_ershengsan"] = "【无中生有】额外摸1张牌",
}

-- 回合结束相关：援助、...

RougeUtil:addBuffTalent { 2, "rouge_yuanzhu1" }
RougeUtil:addBuffTalent { 3, "rouge_yuanzhu2" }
RougeUtil:addBuffTalent { 4, "rouge_yuanzhu3" }
RougeUtil:addBuffTalent { 2, "rouge_xvshi" }

Fk:loadTranslationTable {
  ["rouge_yuanzhu1"] = "援助Ⅰ",
  [":rouge_yuanzhu1"] = "回合结束时，你摸一张牌",
  ["rouge_yuanzhu2"] = "援助Ⅱ",
  [":rouge_yuanzhu2"] = "回合结束时，你摸两张牌",
  ["rouge_yuanzhu3"] = "援助Ⅲ",
  [":rouge_yuanzhu3"] = "回合结束时，你摸3张牌",

  ["rouge_xvshi"] = "蓄势",
  [":rouge_xvshi"] = "本回合没出【杀】，则下回合【杀】伤害+1（最多+1）",
  ["@@rouge_xvshi"] = "蓄势",

}

-- Tmd: 出杀次数类(TargetModSkill)
----------------------

RougeUtil:addBuffTalent { 2, "rouge_zhandouxuexi1" }
RougeUtil:addBuffTalent { 1, "rouge_zhandouxuexi2" }
RougeUtil:addBuffTalent { 1, "rouge_zhandouxuexi3" }
RougeUtil:addBuffTalent { 2, "rouge_chijiuzhan4" }
RougeUtil:addBuffTalent { 3, "rouge_danliangboduo" }
RougeUtil:addBuffTalent { 2, "rouge_erlianji" }
RougeUtil:addBuffTalent { 4, "rouge_sanlianji" }
RougeUtil:addBuffTalent { 3, "rouge_qianlong" }
RougeUtil:addBuffTalent { 1, "rouge_hugujiu" }
RougeUtil:addBuffTalent { 4, "rouge_hugujiu2" }
RougeUtil:addBuffTalent { 4, "rouge_wendingjingong" }
RougeUtil:addBuffTalent { 1, "rouge_guandaozhiji" }
RougeUtil:addBuffTalent { 2, "rouge_touxi" }
RougeUtil:addBuffTalent { 2, "rouge_miaoshoukongkong" }



Fk:loadTranslationTable {
  ["rouge_zhandouxuexi1"] = "战斗学习Ⅰ",
  [":rouge_zhandouxuexi1"] = "从第3轮开始，你的出杀+1",
  ["rouge_zhandouxuexi2"] = "战斗学习Ⅱ",
  [":rouge_zhandouxuexi2"] = "从第4轮开始，你的出杀+1",
  ["rouge_zhandouxuexi3"] = "战斗学习Ⅲ",
  [":rouge_zhandouxuexi3"] = "从第7轮开始，你的出杀+1",
  ["rouge_chijiuzhan4"] = "持久战Ⅳ",
  [":rouge_chijiuzhan4"] = "虎符数量达到3后，出杀次数+1",
  ["rouge_danliangboduo"] = "胆量剥夺",
  [":rouge_danliangboduo"] = "敌方的出杀次数-1",
  ["rouge_erlianji"] = "二连击",
  [":rouge_erlianji"] = "你的出牌阶段，你的出杀次数+1",
  ["rouge_sanlianji"] = "三连击",
  [":rouge_sanlianji"] = "你的出牌阶段，你的出杀次数+2",
  ["rouge_qianlong"] = "潜龙",
  [":rouge_qianlong"] = "每有一个已解锁的空技能槽，则出杀次数+2",

  ["rouge_hugujiu"] = "虎骨酒Ⅰ",
  [":rouge_hugujiu"] = "每回合，你可以额外使用1次【酒】",
  ["rouge_hugujiu2"] = "虎骨酒Ⅱ",
  [":rouge_hugujiu2"] = "每回合，你可以额外使用2次【酒】",

  ["rouge_wendingjingong"] = "稳定进攻",
  [":rouge_wendingjingong"] = "回合内出杀次数固定为5",
  ["#rouge_wendingjingong"] = "稳定进攻",

  ["rouge_guandaozhiji"] = "关刀之脊",
  [":rouge_guandaozhiji"] = "方片【杀】无距离限制",
  ["rouge_touxi"] = "偷袭",
  [":rouge_touxi"] = "黑桃【杀】无次数限制",
  ["rouge_miaoshoukongkong"] = "妙手空空",
  [":rouge_miaoshoukongkong"] = "你使用的【顺手牵羊】无距离限制",
}

-- 加手牌上限、不计入上限类
-----------------------------

RougeUtil:addBuffTalent { 1, "rouge_cangtaohu" }
RougeUtil:addBuffTalent { 3, "rouge_haoshenfa" }
RougeUtil:addBuffTalent { 1, "rouge_pinang1" }
RougeUtil:addBuffTalent { 2, "rouge_pinang2" }
RougeUtil:addBuffTalent { 3, "rouge_pinang3" }
RougeUtil:addBuffTalent { 4, "rouge_wendingchengzai" }
RougeUtil:addBuffTalent { 2, "rouge_xinshounianlai" }


Fk:loadTranslationTable {
  ["rouge_cangtaohu"] = "藏桃户",
  [":rouge_cangtaohu"] = "【桃】不计入手牌上限",
  ["rouge_haoshenfa"] = "好身法",
  [":rouge_haoshenfa"] = "【闪】不计入手牌上限",
  ["rouge_pinang1"] = "皮囊Ⅰ",
  [":rouge_pinang1"] = "手牌上限+1",
  ["rouge_pinang2"] = "皮囊Ⅱ",
  [":rouge_pinang2"] = "手牌上限+2",
  ["rouge_pinang3"] = "皮囊Ⅲ",
  [":rouge_pinang3"] = "手牌上限+5",
  ["rouge_wendingchengzai"] = "稳定承载",
  [":rouge_wendingchengzai"] = "手牌上限基础值为8",
  ["rouge_xinshounianlai"] = "信手拈来",
  [":rouge_xinshounianlai"] = "你的手牌上限不因体力值改变而改变",
  ["rouge_chijiuzhan1"] = "持久战Ⅰ",
  [":rouge_chijiuzhan1"] = "虎符数量达到3后，手牌上限+1",

}

-- 体力或体力上限变化相关
------------------------

RougeUtil:addBuffTalent { 2, "rouge_jiemeng" }
RougeUtil:addBuffTalent { 4, "rouge_shixue" }
RougeUtil:addBuffTalent { 3, "rouge_yaoli1" }
RougeUtil:addBuffTalent { 4, "rouge_yaoli2" }


RougeUtil:addBuffTalent { 1, "rouge_wendingtizhi", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:changeMaxHp(player, 7 - player.maxHp)
end }


Fk:loadTranslationTable {
  ["rouge_jiemeng"] = "结盟",
  [":rouge_jiemeng"] = "你使用的【桃园结义】友方角色回复双倍体力",
  ["rouge_shixue"] = "噬血Ⅰ",
  [":rouge_shixue"] = "回复体力时，摸一张牌",
  ["rouge_yaoli1"] = "药理Ⅰ",
  [":rouge_yaoli1"] = "回复体力时，额外回复1点",
  ["rouge_yaoli2"] = "药理Ⅱ",
  [":rouge_yaoli2"] = "回复体力时，额外回复2点",
  ["rouge_wendingtizhi"] = "稳定体质",
  [":rouge_wendingtizhi"] = "你的体力上限固定为7，无法通过任何途径改变体力值上限",
}

-- 造成伤害时相关
------------------------

RougeUtil:addBuffTalent { 1, "rouge_zhongjiji" }

RougeUtil:addBuffTalent { 2, "rouge_qiaoquhaoduo" }




RougeUtil:addBuffTalent { 1, "rouge_yuanjiji" }



RougeUtil:addBuffTalent { 3, "rouge_yuzhanyuyong1" }
RougeUtil:addBuffTalent { 2, "rouge_yuzhanyuyong2" }
RougeUtil:addBuffTalent { 1, "rouge_yuzhanyuyong3" }
RougeUtil:addBuffTalent { 4, "rouge_wendingshiqi" }
RougeUtil:addBuffTalent { 3, "rouge_tijiashu" }
RougeUtil:addBuffTalent { 2, "rouge_sanbanfu1" }
RougeUtil:addBuffTalent { 4, "rouge_sanbanfu2" }
RougeUtil:addBuffTalent { 4, "rouge_ruoxi" }
RougeUtil:addBuffTalent { 3, "rouge_miaoji1" }
RougeUtil:addBuffTalent { 4, "rouge_miaoji2" }
RougeUtil:addBuffTalent { 2, "rouge_leihuoshi1" }
RougeUtil:addBuffTalent { 4, "rouge_leihuoshi2" }
RougeUtil:addBuffTalent { 1, "rouge_kuangbao1" }
RougeUtil:addBuffTalent { 3, "rouge_kuangbao2" }
RougeUtil:addBuffTalent { 2, "rouge_jiyi1" }
RougeUtil:addBuffTalent { 4, "rouge_jiyi2" }
RougeUtil:addBuffTalent { 2, "rouge_guangongren" }
RougeUtil:addBuffTalent { 1, "rouge_geshandaniu" }
RougeUtil:addBuffTalent { 3, "rouge_dangtouyibang1" }
RougeUtil:addBuffTalent { 4, "rouge_dangtouyibang2" }
RougeUtil:addBuffTalent { 2, "rouge_jingyumoulv1" }
RougeUtil:addBuffTalent { 3, "rouge_jingyumoulv2" }
RougeUtil:addBuffTalent { 3, "rouge_badaoshu1" }
RougeUtil:addBuffTalent { 4, "rouge_badaoshu2" }

RougeUtil:addBuffTalent { 2, "rouge_cuixue1" }
RougeUtil:addBuffTalent { 3, "rouge_cuixue2" }
RougeUtil:addBuffTalent { 1, "rouge_cedingtianxia1" }
RougeUtil:addBuffTalent { 2, "rouge_cedingtianxia2" }

RougeUtil:addBuffTalent { 2, "rouge_hengfeng1" }
RougeUtil:addBuffTalent { 3, "rouge_hengfeng2" }

Fk:loadTranslationTable {
  ["rouge_zhongjiji"] = "重击技",
  [":rouge_zhongjiji"] = "对敌方造成伤害一次大于等于3点时，摸一张牌",
  ["rouge_yuanjiji"] = "远击技",
  [":rouge_yuanjiji"] = "造成伤害时，若你与其距离大于1，此伤害+1",
  ["rouge_yuzhanyuyong1"] = "愈战愈勇Ⅰ",
  [":rouge_yuzhanyuyong1"] = "从第3轮开始，你的【杀】造成的伤害+1",
  ["rouge_yuzhanyuyong2"] = "愈战愈勇Ⅱ",
  [":rouge_yuzhanyuyong2"] = "从第5轮开始，你的【杀】造成的伤害+1",
  ["rouge_yuzhanyuyong3"] = "愈战愈勇Ⅲ",
  [":rouge_yuzhanyuyong3"] = "从第7轮开始，你的【杀】造成的伤害+1",
  ["rouge_wendingshiqi"] = "稳定士气",
  [":rouge_wendingshiqi"] = "你造成的伤害值固定为2",
  ["rouge_tijiashu"] = "剔甲术",
  [":rouge_tijiashu"] = "对护甲造成双倍伤害",
  ["rouge_sanbanfu1"] = "三板斧Ⅰ",
  [":rouge_sanbanfu1"] = "你的每第3张【杀】伤害+1",
  ["rouge_sanbanfu2"] = "三板斧Ⅱ",
  [":rouge_sanbanfu2"] = "你的每第3张【杀】伤害+2",
  ["rouge_ruoxi"] = "弱袭",
  [":rouge_ruoxi"] = "你的手牌小于体力时，你造成的伤害+1",
  ["rouge_miaoji1"] = "妙技Ⅰ",
  [":rouge_miaoji1"] = "每回合首张锦囊造成的伤害+1",
  ["rouge_miaoji2"] = "妙技Ⅱ",
  [":rouge_miaoji2"] = "每回合前2张锦囊造成的伤害+1",
  ["rouge_leihuoshi1"] = "雷火势Ⅰ",
  [":rouge_leihuoshi1"] = "每回合限1次，你使用的第1张属性【杀】伤害+1",
  ["rouge_leihuoshi2"] = "雷火势Ⅱ",
  [":rouge_leihuoshi2"] = "每回合限1次，你使用的第1张属性【杀】伤害+2",
  ["rouge_kuangbao1"] = "狂暴Ⅰ",
  [":rouge_kuangbao1"] = "当你的体力值不大于2时，你造成的伤害+1",
  ["rouge_kuangbao2"] = "狂暴Ⅱ",
  [":rouge_kuangbao2"] = "当你的体力值不大于3时，你造成的伤害+1",
  ["rouge_jiyi1"] = "技艺Ⅰ",
  [":rouge_jiyi1"] = "当你的技能直接造成伤害时，此伤害+1",
  ["rouge_jiyi2"] = "技艺Ⅱ",
  [":rouge_jiyi2"] = "当你的技能直接造成伤害时，此伤害+2",
  ["rouge_guangongren"] = "关公刃",
  [":rouge_guangongren"] = "红桃【杀】伤害+1",
  ["rouge_geshandaniu"] = "隔山打牛",
  [":rouge_geshandaniu"] = "你对其他人造成伤害时，无视其护甲",
  ["rouge_dangtouyibang1"] = "当头一棒Ⅰ",
  [":rouge_dangtouyibang1"] = "每轮，你的首张【杀】伤害+1",
  ["rouge_dangtouyibang2"] = "当头一棒Ⅱ",
  [":rouge_dangtouyibang2"] = "每轮，你的首张【杀】伤害+2",
  ["rouge_cuixue1"] = "淬血Ⅰ",
  [":rouge_cuixue1"] = "你每轮【杀】首次造成伤害后摸一张牌",
  ["rouge_cuixue2"] = "淬血Ⅱ",
  [":rouge_cuixue2"] = "你每轮【杀】首次造成伤害后摸两张牌",
  ["rouge_qiaoquhaoduo"] = "巧取豪夺",
  [":rouge_qiaoquhaoduo"] = "因你的【借刀杀人】使用的【杀】造成伤害时，伤害+1",
  ["rouge_badaoshu1"] = "拔刀术Ⅰ",
  [":rouge_badaoshu1"] = "若上一轮你未造成过伤害，则你本轮造成的伤害+1",
  ["rouge_badaoshu2"] = "拔刀术Ⅱ",
  [":rouge_badaoshu2"] = "若上一轮造成的伤害小于3，则你本轮造成的伤害+1",
  ["rouge_jingyumoulv1"] = "精于谋略Ⅰ",
  [":rouge_jingyumoulv1"] = "你手牌数量少于4，你的【杀】伤害+1",
  ["rouge_jingyumoulv2"] = "精于谋略Ⅱ",
  [":rouge_jingyumoulv2"] = "你手牌数量少于6，你的【杀】伤害+1",
  ["rouge_cedingtianxia1"] = "策定天下Ⅰ",
  [":rouge_cedingtianxia1"] = "出牌阶段限1次，当锦囊牌造成伤害后，摸1张牌",
  ["rouge_cedingtianxia2"] = "策定天下Ⅱ",
  [":rouge_cedingtianxia2"] = "出牌阶段限1次，当锦囊牌造成伤害后，摸2张牌",

  ["rouge_hengfeng1"] = "衡锋Ⅰ",
  [":rouge_hengfeng1"] = "回合内首次造成的伤害+1，回合外首次受到的伤害+1",
  ["rouge_hengfeng2"] = "衡锋Ⅱ",
  [":rouge_hengfeng2"] = "回合内首次造成的伤害+2，回合外首次受到的伤害+2",

  ["@rouge_sanbanfu"] = "三板斧",
}



-- 卡牌使用/指定目标时相关
---------------------------

RougeUtil:addBuffTalent { 1, "rouge_jueduiwuxie" }


RougeUtil:addBuffTalent { 3, "rouge_zuiquan" }
-- RougeUtil:addBuffTalent { 3, "rouge_hengjiangsuo" }


RougeUtil:addBuffTalent { 4, "rouge_yinyangshufa" }





RougeUtil:addBuffTalent { 3, "rouge_yingjifangan" }
RougeUtil:addBuffTalent { 3, "rouge_yingjizhanshu" }
RougeUtil:addBuffTalent { 4, "rouge_yingjizhanlv" }



RougeUtil:addBuffTalent { 1, "rouge_hanzhan" }





RougeUtil:addBuffTalent { 2, "rouge_zhudao1" }
RougeUtil:addBuffTalent { 3, "rouge_zhudao2" }
RougeUtil:addBuffTalent { 1, "rouge_shoudaoqinlai1" }
RougeUtil:addBuffTalent { 1, "rouge_shoudaoqinlai2" }
RougeUtil:addBuffTalent { 1, "rouge_shoudaoqinlai3" }
RougeUtil:addBuffTalent { 1, "rouge_caochuanjiejian" }



RougeUtil:addBuffTalent { 2, "rouge_fengshounian" }










Fk:loadTranslationTable {
  ["rouge_jueduiwuxie"] = "绝对无懈",
  [":rouge_jueduiwuxie"] = "其他角色无法响应你的【无懈可击】",

  ["rouge_zuiquan"] = "醉拳",
  [":rouge_zuiquan"] = "【酒】【杀】不能被抵消",
  ["rouge_yinyangshufa"] = "阴阳术法",
  ["#rougelike1v1_PreCardEffect_yinyangshufa"] = "阴阳术法",
  [":rouge_yinyangshufa"] = "敌方无法响应你的伤害型锦囊牌",

  ["rouge_zhudao1"] = "铸刀Ⅰ",
  [":rouge_zhudao1"] = "你使用【杀】后可以至多重铸1张牌",
  ["rouge_zhudao2"] = "铸刀Ⅱ",
  [":rouge_zhudao2"] = "你使用【杀】后可以至多重铸2张牌",
  ["#rouge_zhudao"] = "铸刀:你可以至多重铸%arg张牌",
  ["rouge_yingjifangan"] = "应急方案",
  [":rouge_yingjifangan"] = "回合外成为敌方角色基本牌唯一目标，随机弃置来源1张牌",
  ["rouge_yingjizhanshu"] = "应急战术",
  [":rouge_yingjizhanshu"] = "回合外成为敌方角色锦囊牌唯一目标，随机弃置来源1张牌",
  ["rouge_yingjizhanlv"] = "应急战略",
  [":rouge_yingjizhanlv"] = "回合外成为敌方角色使用牌唯一目标，随机弃置来源1张牌",

  ["rouge_shuangren1"] = "双刃Ⅰ",
  [":rouge_shuangren1"] = "每轮，你的首张【杀】至多能额外选择1个目标",
  ["rouge_shuangren2"] = "双刃Ⅱ",
  [":rouge_shuangren2"] = "每轮，你的首张【杀】至多能额外选择2个目标",
  ["#rouge_shuangren-choose"] = "双刃：你可额外选择此【杀】目标",
  ["rouge_shoudaoqinlai1"] = "手到擒来Ⅰ",
  [":rouge_shoudaoqinlai1"] = "每回合你使用第7张牌后,你摸1张牌",
  ["rouge_shoudaoqinlai2"] = "手到擒来Ⅱ",
  [":rouge_shoudaoqinlai2"] = "每回合你使用第5张牌后,你摸1张牌",
  ["rouge_shoudaoqinlai3"] = "手到擒来Ⅲ",
  [":rouge_shoudaoqinlai3"] = "每回合你使用第6张牌后,你摸2张牌",

  ["rouge_chenqibubei1"] = "趁其不备Ⅰ",
  [":rouge_chenqibubei1"] = "你使用【过河拆桥】时，至多弃置目标2张牌",
  ["rouge_chenqibubei2"] = "趁其不备Ⅱ",
  [":rouge_chenqibubei2"] = "你使用【过河拆桥】时，至多弃置目标3张牌",
  ["chenqibubei_dismantlement_skill"] = "趁其不备",
  ["#chenqibubei_dismantlement_skill"] = "选择一名区域内有牌的其他角色，你弃置其区域内的多张牌",

  ["rouge_caochuanjiejian"] = "草船借箭",
  [":rouge_caochuanjiejian"] = "【无懈可击】获得抵消的锦囊牌",
  ["rouge_hanzhan"] = "酣战",
  [":rouge_hanzhan"] = "你使用的【决斗】对方需要2张【杀】",

  ["rouge_fengshounian"] = "丰收年",
  [":rouge_fengshounian"] = "你使用的【五谷丰登】仅友方角色可以获得牌",

  ["rouge_hengjiangsuo"] = "横江锁",
  [":rouge_hengjiangsuo"] = "【铁索连环】能指定任意个目标",
  ["#rouge_hengjiangsuo-choose"] = "连环：你可以为 【铁索连环】 额外指定任意个目标",
}



-- 受到伤害时相关
---------------------------
RougeUtil:addBuffTalent { 2, "rouge_yongzhan1" }
RougeUtil:addBuffTalent { 4, "rouge_yongzhan2" }




RougeUtil:addBuffTalent { 3, "rouge_houshi1" }
RougeUtil:addBuffTalent { 4, "rouge_houshi2" }



RougeUtil:addBuffTalent { 4, "rouge_fanci" }
RougeUtil:addBuffTalent { 4, "rouge_jingjijia" }
RougeUtil:addBuffTalent { 4, "rouge_pianzhuanjia" }
RougeUtil:addBuffTalent { 1, "rouge_pofuchenzhou" }
RougeUtil:addBuffTalent { 1, "rouge_xialuxiangfeng" }
RougeUtil:addBuffTalent { 3, "rouge_woxinchangdan" }



RougeUtil:addBuffTalent { 3, "rouge_ruofankui" }


Fk:loadTranslationTable {
  ["rouge_yongzhan1"] = "勇战Ⅰ",
  [":rouge_yongzhan1"] = "你离开濒死时，对所有敌方造成1点伤害",
  ["rouge_yongzhan2"] = "勇战Ⅱ",
  [":rouge_yongzhan2"] = "你离开濒死时，对所有敌方造成2点伤害",

  ["rouge_fanci"] = "反刺",
  [":rouge_fanci"] = "每回合首次受到伤害后对所有敌方造成1点伤害",
  ["rouge_jingjijia"] = "荆棘甲",
  [":rouge_jingjijia"] = "每次受到伤害后对伤害来源造成1点伤害",
  ["rouge_pianzhuanjia"] = "偏转甲",
  [":rouge_pianzhuanjia"] = "每次受到伤害后对随机敌方造成1点伤害",
  ["rouge_pofuchenzhou"] = "破釜沉舟",
  [":rouge_pofuchenzhou"] = "回合外受到伤害一次大于等于3点时，对伤害来源造成等量同属性伤害",
  ["rouge_xialuxiangfeng"] = "狭路相逢",
  [":rouge_xialuxiangfeng"] = "受到【决斗】伤害后回复1点体力",
  ["rouge_woxinchangdan"] = "卧薪尝胆",
  [":rouge_woxinchangdan"] = "回合外每受到1次伤害，下回合出杀次数+1",
  ["@rouge_woxinchangdan"] = "卧薪尝胆",

  ["rouge_ruofankui"] = "弱反馈",
  [":rouge_ruofankui"] = "受到1点伤害后，摸一张牌",
  ["rouge_houshi1"] = "厚实Ⅰ",
  [":rouge_houshi1"] = "每轮你受到的首次伤害-1",
  ["rouge_houshi2"] = "厚实Ⅱ",
  [":rouge_houshi2"] = "每轮你前2次受到的伤害-1",
}

-- 卡牌移动
---------------------------

RougeUtil:addBuffTalent { 1, "rouge_laoguzhuangbei" }




RougeUtil:addBuffTalent { 2, "rouge_shenlongbaiwei1" }
RougeUtil:addBuffTalent { 4, "rouge_shenlongbaiwei2" }
RougeUtil:addBuffTalent { 1, "rouge_duoduoyishan1" }
RougeUtil:addBuffTalent { 2, "rouge_duoduoyishan2" }
RougeUtil:addBuffTalent { 4, "rouge_duoduoyishan3" }

RougeUtil:addBuffTalent { 1, "rouge_jishiyu" }





Fk:loadTranslationTable {
  ["rouge_laoguzhuangbei"] = "牢固装备",
  [":rouge_laoguzhuangbei"] = "你的装备不能被弃置",
  ["rouge_shenlongbaiwei1"] = "神龙摆尾Ⅰ",
  [":rouge_shenlongbaiwei1"] = "你每摸9张卡牌，你对随机敌方造成1点伤害",
  ["rouge_shenlongbaiwei2"] = "神龙摆尾Ⅱ",
  [":rouge_shenlongbaiwei2"] = "你每摸6张卡牌，你对随机敌方造成1点伤害",
  ["@rouge_shenlongbaiwei1"] = "神龙摆尾Ⅰ",
  ["@rouge_shenlongbaiwei2"] = "神龙摆尾Ⅱ",

  ["rouge_duoduoyishan1"] = "多多益善Ⅰ",
  [":rouge_duoduoyishan1"] = "每回合你第5次摸牌后,你摸1张牌",
  ["rouge_duoduoyishan2"] = "多多益善Ⅱ",
  [":rouge_duoduoyishan2"] = "每回合你第3次摸牌后,你摸1张牌",
  ["rouge_duoduoyishan3"] = "多多益善Ⅲ",
  [":rouge_duoduoyishan3"] = "每回合你第3次摸牌后,你摸2张牌",
  ["@rouge_duoduoyishan1-turn"] = "多多益善Ⅰ",
  ["@rouge_duoduoyishan2-turn"] = "多多益善Ⅱ",
  ["@rouge_duoduoyishan3-turn"] = "多多益善Ⅲ",

  ["rouge_jishiyu"] = "及时雨",
  [":rouge_jishiyu"] = "回合外失去最后一张手牌后，摸2张牌",

}



-- 状态技
---------------------------

RougeUtil:addBuffTalent { 1, "rouge_yanxian" }
RougeUtil:addBuffTalent { 1, "rouge_qiangquhaoduo" }



RougeUtil:addBuffTalent { 1, "rouge_dushu1" }
RougeUtil:addBuffTalent { 2, "rouge_dushu2" }


Fk:loadTranslationTable {
  ["rouge_yanxian"] = "眼线",
  ["@rouge_yanxian"] = "明牌",
  [":rouge_yanxian"] = "【过河拆桥】时目标手牌可见",
  ["rouge_qiangquhaoduo"] = "强取豪夺",
  [":rouge_qiangquhaoduo"] = "【顺手牵羊】时目标手牌可见",
  ["#rougelike1v1_PreEffect_Visibility"] = "战法：眼线/强夺豪取",
  ["rouge_dushu1"] = "赌术Ⅰ",
  [":rouge_dushu1"] = "你的拼点牌点数+3（最大为K）",
  ["rouge_dushu2"] = "赌术Ⅱ",
  [":rouge_dushu2"] = "你的拼点牌点数+6（最大为K）",

}
-- Misc: 系统耦合类
------------------------

RougeUtil:addBuffTalent { 4, "rouge_shangdao", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:addPlayerMark(player, "rougelike1v1_shop_num", 1)
end }

RougeUtil:addBuffTalent { 3, "rouge_yunchouweiwo", function(self, player)
  RougeUtil.sendTalentLog(player, self)
  player.room:addPlayerMark(player, "rougelike1v1_skill_num", 1)
end }

Fk:loadTranslationTable {
  ["rouge_shangdao"] = "商道",
  [":rouge_shangdao"] = "商店中商品展示数量+1",

  ["rouge_yunchouweiwo"] = "运筹帷幄",
  [":rouge_yunchouweiwo"] = "技能槽上限+1",
}
