local sheyi = fk.CreateSkill {
  name = "sheyi",
}

Fk:loadTranslationTable{
  ["sheyi"] = "舍裔",
  [":sheyi"] = "每轮限一次，当一名其他角色受到伤害时，若其体力值小于你，你可以交给其至少X张牌，防止此伤害（X为你的体力值）。",

  ["#sheyi-invoke"] = "舍裔：你可以交给 %dest 至少%arg张牌，防止其受到的伤害",

  ["$sheyi1"] = "二子不可兼顾，妾身唯保其一。",
  ["$sheyi2"] = "吾子虽弃亦可，前遗万勿有失。",
}

sheyi:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(sheyi.name) and target.hp < player.hp and
      #player:getCardIds("he") >= player.hp and
      player:usedSkillTimes(sheyi.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = player.hp,
      max_num = 999,
      include_equip = true,
      skill_name = sheyi.name,
      prompt = "#sheyi-invoke::"..target.id..":"..player.hp,
      cancelable = true,
    })
    if #cards >= player.hp then
      event:setCostData(self, {tos = {target}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
    player.room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, target, fk.ReasonGive, sheyi.name, nil, false, player)
  end,
})

return sheyi
