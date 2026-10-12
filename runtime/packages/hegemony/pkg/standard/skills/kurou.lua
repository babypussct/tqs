local kurou = fk.CreateSkill{
  name = "hs__kurou",
}

Fk:loadTranslationTable{
  ["hs__kurou"] = "苦肉",
  [":hs__kurou"] = "出牌阶段限一次，你可以弃置一张牌，然后你失去1点体力，摸三张牌，于此阶段内使用【杀】的次数上限+1。",

  ["#hs__kurou"] = "苦肉：弃置一张牌，失去1点体力，摸三张牌，本阶段使用【杀】次数+1",

  ["$hs__kurou1"] = "我这把老骨头，不算什么！",
  ["$hs__kurou2"] = "为成大业，死不足惜！",
}

kurou:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#hs__kurou",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(kurou.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, kurou.name, player, player)
    if player.dead then return end
    room:loseHp(player, 1, kurou.name)
    if player.dead then return end
    player:drawCards(3, kurou.name)
    if player.dead then return end
    room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", 1)
  end
})

return kurou
