local zhaoji = fk.CreateSkill {
  name = "#kq__zhaoji",
}

Fk:loadTranslationTable{
  ["#kq__zhaoji"] = "赵姬之乱",
  [":#kq__zhaoji"] = "当一名男性角色每回合首次造成伤害时，此伤害-1；若场上有赵姬，则将上述“男性角色”改为“非秦势力角色”。",
}

zhaoji:addEffect(fk.DamageCaused, {
  priority = 0.001,
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target == player then
      local damage_events = player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function (e)
        return e.data.from == target
      end, player.HistoryTurn)
      if #damage_events == 1 and damage_events[1].data == data then
        if table.find(player.room.alive_players, function (p)
          return Fk.generals[p.general].trueName == "zhaoji" or (Fk.generals[p.deputyGeneral] or {}).trueName == "zhaoji"
        end) then
          return target.kingdom ~= "qin"
        else
          return target:isMale()
        end
      end
    end
  end,
  on_trigger = function (self, event, target, player, data)
    data.to:broadcastSkillInvoke("qin__huoluan")
    data.to:chat("$qin__huoluan")
    data:changeDamage(-1)
  end,
})

return zhaoji
