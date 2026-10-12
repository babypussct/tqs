local polu = fk.CreateSkill {
  name = "polu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["polu"] = "破橹",
  [":polu"] = "锁定技，回合开始时，你获得游戏外、牌堆或弃牌堆中的一张<a href=':mobile__catapult'>【霹雳车】</a>并使用之；"..
  "当你受到1点伤害后，若你的装备区里没有【霹雳车】，你摸一张牌，然后随机从牌堆中获得一张武器牌并使用之。",

  ["#polu-use"] = "破橹：请使用%arg",

  ["$polu1"] = "设此发石车，可破袁军高橹。",
  ["$polu2"] = "霹雳之声，震丧敌胆。",
}

local mobile__catapult = { { "mobile__catapult", Card.Diamond, 9 } }

polu:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(polu.name) and
      target == player and
      #player:getAvailableEquipSlots(Card.SubtypeWeapon) > 0 and
      table.contains(
        { Card.Void, Card.DrawPile, Card.DiscardPile },
        player.room:getCardArea(player.room:prepareDeriveCards(mobile__catapult, "mobile__catapult")[1])
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:prepareDeriveCards(mobile__catapult, "mobile__catapult")[1]
    if not id then return end
    room:obtainCard(player, id, true, fk.ReasonPrey, player, polu.name)
    local card = Fk:getCardById(id)
    if table.contains(player:getCardIds("h"), id) and player:canUseTo(card, player) then
      room:useCard{
        from = player,
        tos = { player },
        card = card,
      }
    end
  end,
})

polu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(polu.name) and
      target == player and
      not table.find(player:getEquipments(Card.SubtypeWeapon), function(id)
        return Fk:getCardById(id).name == "mobile__catapult"
      end)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = polu.name
    local room = player.room
    player:drawCards(1, skillName)
    if not player:isAlive() then return false end

    local ids = {}
    for _, id in ipairs(room.draw_pile) do
      if Fk:getCardById(id).sub_type == Card.SubtypeWeapon then table.insert(ids, id) end
    end
    if #ids == 0 then return end
    local id = room:tableRandomPick(ids)
    room:obtainCard(player, id, true, fk.ReasonPrey, player, skillName)
    local card = Fk:getCardById(id)
    if table.contains(player:getCardIds("h"), id) and player:canUse(card) then
      if player:canUseTo(card, player) then
        room:useCard({
          from = player,
          tos = {player},
          card = card,
        })
      else
        room:askToUseRealCard(player, {
          pattern = {card.id},
          skill_name = polu.name,
          prompt = "#polu-use:::"..card:toLogString(),
          cancelable = false,
        })
      end
    end
  end,
})

return polu
