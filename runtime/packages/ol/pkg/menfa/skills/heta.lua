
local heta = fk.CreateSkill{
  name = "heta",
}

Fk:loadTranslationTable{
  ["heta"] = "和他",
  [":heta"] = "你使用基本牌或普通锦囊牌时，你可以令此牌增加或减少任意个目标。然后若其本回合此前未成为过牌的目标，你弃置一张牌。",

  ["#heta-choose"] = "和他：为%arg增加/减少任意个目标",

  ["$heta1"] = "兵者不可为首，待他州发动再和之不迟。",
  ["$heta2"] = "学从袁，职自董，当助袁氏乎？当助董氏乎？",
}

heta:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(heta.name) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and #data.tos > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.tos, function (p)
      return not p.dead
    end)
    table.insertTable(targets, data:getExtraTargets({ bypass_distances = true, bypass_times = true }))
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #targets,
      prompt = "#heta-choose:::"..data.card:toLogString(),
      skill_name = heta.name,
      cancelable = true,
      target_tip_name = "addandcanceltarget_tip",
      extra_data = table.map(data.tos, Util.IdMapper),
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos or {}
    local targets = table.simpleClone(tos)
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      if e.data == data then
        return true
      else
        for _, p in ipairs(e.data.tos) do
          table.removeOne(targets, p)
        end
      end
    end, Player.HistoryTurn)
    for _, p in ipairs(tos) do
      if table.contains(data.tos, p) then
        data:removeTarget(p)
      else
        data:addTarget(p)
      end
    end
    if #targets > 0 then
      room:askToDiscard(player, {
        min_num = #targets,
        max_num = #targets,
        include_equip = true,
        skill_name = heta.name,
        cancelable = false,
      })
    end
  end,
})

return heta
