local hengsao = fk.CreateSkill {
  name = "#kq__hengsao",
}

Fk:loadTranslationTable{
  ["#kq__hengsao"] = "横扫六合",
  [":#kq__hengsao"] = "牌堆中加入【传国玉玺】和【真龙长剑】；若场上有嬴政，游戏开始时，嬴政将【传国玉玺】和【真龙长剑】置入装备区。",
}

hengsao:addEffect(fk.GameStart, {
  priority = 0.001,
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return table.find(player.room.alive_players, function (p)
      return Fk.generals[p.general].trueName == "yingzheng" or (Fk.generals[p.deputyGeneral] or {}).trueName == "yingzheng"
    end)
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local yingzheng = table.find(player.room.alive_players, function (p)
      return Fk.generals[p.general].trueName == "yingzheng" or (Fk.generals[p.deputyGeneral] or {}).trueName == "yingzheng"
    end)
    if yingzheng == nil or yingzheng.dead then return end
    local ids = {}
    for _, id in ipairs(room.draw_pile) do
      if (Fk:getCardById(id).name == "qin_dragon_sword" or Fk:getCardById(id).name == "qin_seal") and
        player:canMoveCardIntoEquip(id, false) then
        table.insert(ids, id)
      end
    end
    if #ids > 0 then
      room:moveCardIntoEquip(player, ids, hengsao.name, false)
    end
  end,

  can_refresh = function (self, event, target, player, data)
    return player.seat == 1
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local id = room:printCard("qin_dragon_sword", Card.Heart, 2).id
    table.insert(room.draw_pile, math.random(1, #room.draw_pile), id)
    id = room:printCard("qin_seal", Card.Heart, 7).id
    table.insert(room.draw_pile, math.random(1, #room.draw_pile), id)
    room:syncDrawPile()
  end,
})

return hengsao
