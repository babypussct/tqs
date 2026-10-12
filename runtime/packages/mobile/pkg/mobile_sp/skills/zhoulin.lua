local zhoulin = fk.CreateSkill{
  name = "zhoulin",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["zhoulin"] = "咒鳞",
  [":zhoulin"] = "限定技，出牌阶段，若你有〖兽法〗，则你可以获得2点护甲并选择一种野兽效果，令你直到你的下个回合开始，" ..
  "“兽法”必定执行此野兽效果。",

  ["#zhoulin"] = "咒鳞：你可以获得2点护甲，选择一种“兽法”效果必定生效直到你下回合开始",
  ["@zhoulin"] = "咒鳞",
  ["zhoulin_bao"] = "豹：伤害来源受到1点无来源伤害",
  ["zhoulin_ying"] = "鹰：随机获得伤害来源一张牌",
  ["zhoulin_xiong"] = "熊：随机弃置伤害来源装备区一张牌",
  ["zhoulin_tu"] = "兔：伤害来源摸一张牌",

  ["$zhoulin1"] = "料一山野书生，安识我南中御兽之术！",
  ["$zhoulin2"] = "本大王承天大法，岂与诸葛亮小计等同！",
}

zhoulin:addEffect("active", {
  anim_type = "support",
  prompt = "#zhoulin",
  card_num = 0,
  target_num = 0,
  interaction = UI.ComboBox { choices = { "zhoulin_bao", "zhoulin_ying", "zhoulin_xiong", "zhoulin_tu" } },
  can_use = function(self, player)
    return player:usedSkillTimes(zhoulin.name, Player.HistoryGame) == 0 and player:hasSkill("shoufa")
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:changeShield(player, 2)
    room:setPlayerMark(player, "@zhoulin", "shoufa_"..self.interaction.data:split("_")[2])
  end,
})
zhoulin:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@zhoulin") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@zhoulin", 0)
  end,
})

return zhoulin
