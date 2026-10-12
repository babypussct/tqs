local hannan = fk.CreateSkill {
  name = "os__hannan",
}

Fk:loadTranslationTable {
  ["os__hannan"] = "扞难",
  [":os__hannan"] = "出牌阶段限一次，你可以与一名其他角色拼点，没赢的角色受到另一名角色的1点伤害，然后你获得拼点牌中的伤害牌。",

  ["#os__hannan"] = "扞难：与一名角色拼点，没赢的角色受到1点伤害，然后你获得拼点牌中的伤害牌。",

  ["$os__hannan1"] = "辅君则当死谏，退敌则当死战！",
  ["$os__hannan2"] = "生辜七尺之形，死负一棺之土！",
}

hannan:addEffect("active", {
  anim_type = "offensive",
  prompt = "#os__hannan",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(hannan.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({ target }, hannan.name)
    local tos = { player, target }
    local cards = {pindian.fromCard, pindian.results[target].toCard}
    local winner = pindian.results[target].winner
    for i, to in ipairs(tos) do
      if not to.dead and to ~= winner then
        room:damage {
          from = tos[3 - i],
          to = to,
          damage = 1,
          skillName = hannan.name,
        }
      end
    end
    if player.dead then return end
    cards = table.filter(cards, function(c) return c.is_damage_card and room:getCardArea(c) == Card.DiscardPile end)
    if #cards > 0 then
      room:obtainCard(player, cards, true, fk.ReasonPrey, player, hannan.name)
    end
  end,
})

return hannan
