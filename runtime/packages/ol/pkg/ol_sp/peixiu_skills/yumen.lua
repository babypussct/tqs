local yumen = fk.CreateSkill {
  name = "peixiu_yumen",
}

Fk:loadTranslationTable {
  ["peixiu_yumen"] = "玉门",
  [":peixiu_yumen"] = "已连环的角色不能响应你的牌。",
}

yumen:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yumen.name) and
      table.find(player.room.alive_players, function(p)
        return p.chained
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(room.alive_players) do
      if p.chained then
        table.insertIfNeed(data.disresponsiveList, p)
      end
    end
  end
})

return yumen
