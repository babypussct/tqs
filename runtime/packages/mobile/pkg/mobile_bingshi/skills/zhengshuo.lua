local zhengshuo = fk.CreateSkill {
  name = "zhengshuo",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["zhengshuo"] = "正朔",
  [":zhengshuo"] = "限定技，出牌阶段，你可以令所有角色依次弃置所有手牌，然后洗牌，若如此做，所有角色各摸四张牌。",

  ["#zhengshuo"] = "正朔：令所有角色弃置所有手牌，洗牌，然后各摸四张牌",

  ["$zhengshuo1"] = "安帝以来，唯有名号，尺土一民，皆非汉有。",
  ["$zhengshuo2"] = "孙权在远称臣，此即天人之应也。",
}

zhengshuo:addEffect("active", {
  anim_type = "control",
  prompt = "#zhengshuo",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zhengshuo.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_cost = function(self, player, data)
    return { tos = player.room:getAlivePlayers() }
  end,
  on_use = function(self, room, effect)
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead then
        p:throwAllCards("h", zhengshuo.name)
      end
    end
    room:shuffleDrawPile()
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead then
        p:drawCards(4, zhengshuo.name)
      end
    end
  end,
})

return zhengshuo
