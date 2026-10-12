local cuixin = fk.CreateSkill {
  name = "cuixin",
}

Fk:loadTranslationTable{
  ["cuixin"] = "摧心",
  [":cuixin"] = "当你不以此法对上家/下家使用的牌结算后，你可以视为对下家/上家使用一张同名牌。",

  ["#cuixin-choose"] = "摧心：选择对 %dest 使用【%arg】的副目标",
  ["cuixin_to"] = "视为对 %dest 使用【%arg】",

  ["$cuixin1"] = "今兵临城下，其王庭可摧。",
  ["$cuixin2"] = "四面皆奏楚歌，问汝降是不降？",
}

cuixin:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(cuixin.name) and data.extra_data and data.extra_data.cuixin_tos then
      local targets = {}
      if #data.extra_data.cuixin_tos == 1 then
        if #data.extra_data.cuixin_adjacent == 1 then
          if not player:isProhibited(player:getNextAlive(), data.card) then
            table.insert(targets, player:getNextAlive())
          else
            return
          end
        else
          for _, p in ipairs(data.extra_data.cuixin_adjacent) do
            if p ~= data.extra_data.cuixin_tos[1] then
              if not p.dead and not player:isProhibited(p, data.card) then
                table.insert(targets, p)
                break
              end
            end
          end
        end
      else
        for _, p in ipairs(data.extra_data.cuixin_adjacent) do
          if not p.dead and not player:isProhibited(p, data.card) then
            table.insert(targets, p)
          end
        end
      end
      if #targets > 0 then
        event:setCostData(self, {extra_data = targets})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).extra_data

    --FIXME: 操作方式待优化
    local choices = table.map(targets, function (p)
      return "cuixin_to::" .. p.id .. ":" .. data.card.name
    end)
    table.insert(choices, "Cancel")

    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = cuixin.name,
    })
    if choice == "Cancel" then return end
    local tos = { targets[table.indexOf(choices, choice)] }
    if data.card.skill:getMinTargetNum(player) == 2 then
      local card = Fk:cloneCard(data.card.name)
      card.skillName = cuixin.name
      local sub_tos = table.filter(room.alive_players, function (p)
        return card.skill:targetFilter(player, p, tos, {}, card, { bypass_distances = true, bypass_times = true })
      end)
      if #sub_tos == 0 then return end
      sub_tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = sub_tos,
        skill_name = cuixin.name,
        prompt = "#cuixin-choose::" .. target.id .. ":" .. card.name,
        cancelable = true,
      })
      if #sub_tos == 0 then return end
      table.insert(tos, sub_tos[1])
    end
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local card = Fk:cloneCard(data.card.name)
    card.skillName = cuixin.name
    player.room:useCard{
      card = card,
      from = player,
      tos = event:getCostData(self).tos,
      extraUse = true,
    }
  end,
})

cuixin:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(cuixin.name, true) and
      not table.contains(data.card.skillNames, cuixin.name) and
      data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local tos, adjacent = {}, {}
    for _, p in ipairs(room.alive_players) do
      if player:getNextAlive() == p or p:getNextAlive() == player then
        table.insertIfNeed(adjacent, p)
        if table.contains(data.tos, p) then
          table.insertIfNeed(tos, p)
        end
      end
    end
    if #tos > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.cuixin_tos = tos
      data.extra_data.cuixin_adjacent = adjacent
    end
  end,
})

return cuixin
