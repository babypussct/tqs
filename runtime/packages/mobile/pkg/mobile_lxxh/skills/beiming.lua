local beiming = fk.CreateSkill {
  name = "beiming",
}

Fk:loadTranslationTable{
  ["beiming"] = "孛明",
  [":beiming"] = "游戏开始时，你可以令至多两名角色分别从牌堆中随机获得一张攻击范围为X的武器牌（X为其手牌中的花色数）。",

  ["#beiming-choose"] = "孛明：你可以令至多两名角色获得武器牌",

  ["$beiming1"] = "孛星起于吴楚，吾等应举刀兵！",
  ["$beiming2"] = "尽点淮南兵马，以讨司马逆臣！",
}

beiming:addEffect(fk.GameStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(beiming.name)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 2,
      targets = room.alive_players,
      skill_name = beiming.name,
      prompt = "#beiming-choose",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, to in ipairs(event:getCostData(self).tos) do
      if not to.dead then
        local suits = {}
        for _, id in ipairs(to:getCardIds("h")) do
          table.insertIfNeed(suits, Fk:getCardById(id).suit)
        end
        table.removeOne(suits, Card.NoSuit)
        local weapons = {}
        for _, id in ipairs(room.draw_pile) do
          local card = Fk:getCardById(id)
          if card.sub_type == Card.SubtypeWeapon and card.attack_range == #suits then
            table.insert(weapons, id)
          end
        end

        if #weapons > 0 then
          room:obtainCard(to, room:tableRandomPick(weapons), true, fk.ReasonPrey, to, beiming.name)
        end
      end
    end
  end,
})

return beiming
