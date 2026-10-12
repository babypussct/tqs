local weilie = fk.CreateSkill {
  name = "os__weilie",
}

Fk:loadTranslationTable{
  ["os__weilie"] = "炜烈",
  [":os__weilie"] = "出牌阶段，你可以弃置一张牌，令一名角色回复1点体力，然后若其已受伤，其摸两张牌。"..
  "（每局游戏限两次，你每次发动〖浮萍〗记录牌名时，此技能可发动次数+1）。",

  ["#os__weilie"] = "炜烈：弃一张牌，令一名角色回复1点体力",

  ["$os__weilie1"] = "虽山崩城摧，此心绝决断不可易!",
  ["$os__weilie2"] = "愿效古之烈女，为后来者作则。"
}

weilie:addEffect("active", {
  anim_type = "support",
  times = function(self, player)
    return 2 + player:usedEffectTimes("#fuping_2_trig", Player.HistoryGame) - player:usedSkillTimes(weilie.name, Player.HistoryGame)
  end,
  prompt = "#os__weilie",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(weilie.name, Player.HistoryGame) < player:usedEffectTimes("#fuping_2_trig", Player.HistoryGame) + 2
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and to_select:isWounded()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, weilie.name, player, player)
    if target:isWounded() and not target.dead then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = weilie.name
      }
    end
    if target:isWounded() and not target.dead then
      target:drawCards(2, weilie.name)
    end
  end,
})

return weilie
