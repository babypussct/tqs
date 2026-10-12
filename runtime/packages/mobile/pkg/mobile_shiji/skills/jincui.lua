local jincui = fk.CreateSkill {
  name = "mobile__jincui",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["mobile__jincui"] = "尽瘁",
  [":mobile__jincui"] = "限定技，出牌阶段，你可以与一名其他角色交换座次，然后你失去X点体力（X为你的体力值-本局游戏发动〖镇庭〗次数），"..
  "若你未因此失去体力，你加1点体力上限，然后删去〖镇庭〗的背水选项。",

  ["#mobile__jincui"] = "尽瘁：你可以与一名角色交换座次，失去%arg点体力",

  ["$mobile__jincui1"] = "伐魏虽俯仰惟艰，臣甘愿效死于前！",
  ["$mobile__jincui2"] = "臣敢竭股肱之力，誓死为陛下前驱！",
}

jincui:addEffect("active", {
  anim_type = "special",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#mobile__jincui:::"..math.max(player.hp - player:usedSkillTimes("zhenting", Player.HistoryGame), 0)
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(jincui.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:swapSeat(player, target)
    if player.dead then return end
    local n = player.hp - player:usedSkillTimes("zhenting", Player.HistoryGame)
    if n > 0 then
      room:loseHp(player, n, jincui.name)
    else
      room:setPlayerMark(player, jincui.name, 1)
      room:changeMaxHp(player, 1)
    end
  end,
})

return jincui
