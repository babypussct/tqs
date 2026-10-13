local shaqiu = fk.CreateSkill {
  name = "#kq__shaqiu",
}

Fk:loadTranslationTable{
  ["#kq__shaqiu"] = "沙丘之变",
  [":#kq__shaqiu"] = "当一名角色死亡时，将其所有牌随机分配给所有男性角色；若场上有赵高，则将上述“随机分配给所有男性角色”改为“交给赵高”。",
}

shaqiu:addEffect(fk.Death, {
  priority = 0.001,
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and not player:isNude()
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local zhaogao = table.find(player.room.alive_players, function (p)
      return Fk.generals[p.general].trueName == "zhaogao" or (Fk.generals[p.deputyGeneral] or {}).trueName == "zhaogao"
    end)
    if zhaogao then
      zhaogao:broadcastSkillInvoke("qin__gaizhao")
      zhaogao:chat("$qin__gaizhao")
      room:obtainCard(zhaogao, target:getCardIds("he"), true, fk.ReasonGive, player)
    else
      local targets = table.filter(room.alive_players, function (p)
        return p:isMale()
      end)
      if #targets == 0 then return end
      local mapper = {}
      for _, id in ipairs(target:getCardIds("he")) do
        local p = room:tableRandomPick(targets)
        mapper[p] = mapper[p] or {}
        table.insert(mapper[p], id)
      end
      local moves = {}
      for p, ids in pairs(mapper) do
        table.insert(moves, {
          ids = ids,
          from = player,
          to = p,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          skillName = shaqiu.name,
          moveVisible = false,
        })
      end
      room:moveCards(table.unpack(moves))
    end
  end,
})

return shaqiu
