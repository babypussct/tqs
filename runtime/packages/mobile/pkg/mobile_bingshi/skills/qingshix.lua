local qingshix = fk.CreateSkill {
  name = "qingshix",
}

Fk:loadTranslationTable{
  ["qingshix"] = "清识",
  [":qingshix"] = "当你受到伤害后，你可以选择一名角色，若你与其阵营：相同，你与其各摸一张牌；不同，你弃置你与其各一张牌。",

  ["#qingshix-invoke"] = "清识：选择一名角色，若与其阵营相同则各摸一张牌，否则你弃置双方各一张牌",

  ["$qingshix1"] = "会在事纵恣，非持久处下之道。",
  ["$qingshix2"] = "智多而肆，吾畏其有他志。",
}

qingshix:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingshix.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      prompt = "#qingshix-invoke",
      skill_name = qingshix.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if player:isFriend(to) then
      player:drawCards(1, qingshix.name)
      if not to.dead then
        to:drawCards(1, qingshix.name)
      end
    else
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = qingshix.name,
        cancelable = false,
      })
      if to:isAlive() and not to:isNude() then
        local id = room:askToChooseCard(
          player,
          {
            target = to,
            flag = "he",
            skill_name = qingshix.name,
          }
        )

        room:throwCard(id, qingshix.name, to, player)
      end
    end
  end
})

return qingshix
