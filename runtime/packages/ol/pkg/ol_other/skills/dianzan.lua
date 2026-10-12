local dianzan = fk.CreateSkill {
  name = "dianzan",
}

Fk:loadTranslationTable{
  ["dianzan"] = "点赞",
  [":dianzan"] = "出牌阶段限一次，你可以给乐刘禅送花。",

  ["#dianzan"] = "点赞：你可以为刘禅助力",
}

dianzan:addEffect("active", {
  prompt = "#dianzan",
  target_num = 0,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(dianzan.name, Player.HistoryPhase) == 0
  end,
  target_filter = Util.FalseFunc,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    for _, p in ipairs(room.alive_players) do
      if p:hasSkill("tuoquan", true, true) then
        effect.from:chat("$@Flower:" .. p.id)
      end
    end
  end,
})

return dianzan
