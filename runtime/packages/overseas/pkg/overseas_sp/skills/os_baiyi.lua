local osBaiyi = fk.CreateSkill {
  name = "os__baiyi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__baiyi"] = "败移",
  [":os__baiyi"] = "限定技，出牌阶段，若你已受伤，你可选择其他两名角色，令这两名角色交换座次。",
  ["#os__baiyi"] = "选择其他两名角色，令这两名角色交换座次。",

  ["$os__baiyi1"] = "吾不听公休之言，以致须行此策。",
  ["$os__baiyi2"] = "诸将无过，且按吾之略再图破敌。",
}

osBaiyi:addEffect("active", {
  anim_type = "control",
  prompt = "#os__baiyi",
  card_num = 0,
  target_num = 2,
  target_filter = function(self, player, to_select, selected)
    return #selected < 2 and to_select ~= player
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(osBaiyi.name, Player.HistoryGame) == 0 and player:isWounded()
  end,
  on_use = function(self, room, effect)
    local from, to = effect.tos[1], effect.tos[2]
    room:swapSeat(from, to)
  end
})

return osBaiyi
