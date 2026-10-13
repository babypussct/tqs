local xiechan = fk.CreateSkill {
  name = "v11__xiechan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["v11__xiechan"] = "挟缠",
  [":v11__xiechan"] = "限定技，出牌阶段，你可以与对手拼点，若你赢，则你视为对其使用一张【决斗】，否则其视为对你使用一张【决斗】。",

  ["#v11__xiechan"] = "挟缠：与对手拼点，若赢视为对其使用【决斗】，否则其对你使用【决斗】",

  ["$v11__xiechan1"] = "休走，你我今日定要分个胜负！",
  ["$v11__xiechan2"] = "不是你死，便是我亡！",
}

xiechan:addEffect("active", {
  anim_type = "offensive",
  prompt = "#v11__xiechan",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(xiechan.name, Player.HistoryGame) == 0 and player:canPindian(player.next)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = player.next
    local pindian = player:pindian({to}, xiechan.name)
    local user = (pindian.results[to].winner == player) and {player, to} or {to, player}
    room:useVirtualCard("duel", nil, user[1], user[2], xiechan.name)
  end,
})

return xiechan
