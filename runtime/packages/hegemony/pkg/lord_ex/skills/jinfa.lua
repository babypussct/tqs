
local jinfa = fk.CreateSkill{
  name = "ld__jinfa",
}

Fk:loadTranslationTable{
  ["ld__jinfa"] = "矜伐",
  [":ld__jinfa"] = "出牌阶段限一次，你可以拼点，若你赢，你获得其一张牌；若拼点牌中包含♠牌，则没赢的角色对赢的角色造成1点伤害。",

  ["#ld__jinfa"] = "矜伐：与一名角色拼点，若赢则获得其一张牌，若有♠拼点牌则赢的角色受到1点伤害",

  ["$ld__jinfa1"] = "居功者，当自矜，为将者，当善伐。",
  ["$ld__jinfa2"] = "此战伐敌所获，皆我之功。",
}

jinfa:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ld__jinfa",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(jinfa.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({ target }, jinfa.name)
    local winner = pindian.results[target].winner
    if winner == player and not player.dead and not target:isNude() then
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "he",
        skill_name = jinfa.name,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, jinfa.name, nil, false, player)
    end
    if (pindian.fromCard and pindian.fromCard.suit == Card.Spade) or
      (pindian.results[target].toCard and pindian.results[target].toCard.suit == Card.Spade) then
      local from, to
      if winner == player then
        from, to = target, player
      elseif winner == target then
        from, to = player, target
      end
      if to and not to.dead then
        room:damage{
          from = from,
          to = to,
          damage = 1,
          skillName = jinfa.name,
        }
      end
    end
  end,
})

return jinfa
