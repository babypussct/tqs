local kunyu = fk.CreateSkill {
  name = "kunyu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["kunyu"] = "鹍浴",
  [":kunyu"] = "锁定技，你的体力上限始终为1，当你濒死求桃结算后，若体力值仍小于1，你将牌堆中的一张火属性伤害牌移出游戏，然后将体力值调整至1点。",

  ["$kunyu1"] = "君岂不闻，山皆有其愚公乎？",
  ["$kunyu2"] = "衰桐凤不栖，昆山玉已碎！",
}

kunyu:addEffect(fk.AskForPeachesDone, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kunyu.name) and player.hp <= 0 and
      table.find(player.room.draw_pile, function(id)
        return Fk:getCardById(id).damage_type == fk.FireDamage
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local toRemove = nil
    --从牌堆底开始检索，优先移除【火攻】
    for i = #room.draw_pile, 1, -1 do
      local id = room.draw_pile[i]
      local card = Fk:getCardById(id)
      if card.damage_type == fk.FireDamage then
        if card.type == Card.TypeTrick then
          toRemove = id
          break
        end
        toRemove = toRemove or id
      end
    end

    if toRemove then
      room:moveCardTo(toRemove, Card.Void, nil, fk.ReasonJustMove, kunyu.name, nil, true, player)
      if not player.dead and player.hp < 1 then
        room:setPlayerProperty(player, "hp", 1)
      end
    end
  end,
})
kunyu:addEffect(fk.BeforeMaxHpChanged, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(kunyu.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    data:preventMaxHpChange()
  end,
})

return kunyu
