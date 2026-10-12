
local zhanshi = fk.CreateSkill{
  name = "zhanshi",
}

Fk:loadTranslationTable {
  ["zhanshi"] = "瞻势",
  [":zhanshi"] = "当有角色进行拼点时，你可以选择此次拼点中的任意名角色并弃置等量张牌，"..
  "此次拼点结算后，所选角色中每有一名角色赢，你摸三张牌。",

  ["#zhanshi-invoke"] = "瞻势：弃置任意张牌，选择等量拼点的角色，若你选择的角色拼点赢则摸三张牌",

  ["$zhanshi1"] = "今观其兵寡，吾等未必无胜战之机。",
  ["$zhanshi2"] = "吾等只需城门不失，便有回转之力。",
  ["$zhanshi3"] = "如今优势尚存，吾等还需死守。",
  ["$zhanshi4"] = "待孙策粮草有缺，其军必退。",
}

zhanshi:addEffect(fk.StartPindian, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhanshi.name) and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(data.tos)
    table.insertIfNeed(targets, data.from)
    targets = table.filter(targets, function (p)
      return not p.dead
    end)
    local tos, cards = room:askToChooseCardsAndPlayers(player,{
      min_num = 1,
      max_num = #targets,
      min_card_num = 1,
      max_card_num = #targets,
      targets = targets,
      skill_name = zhanshi.name,
      will_throw = true,
      equal = true,
      prompt = "#zhanshi-invoke",
    })
    if #tos > 0 and #cards > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos, cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards or {}
    room:throwCard(cards, zhanshi.name, player, player)
    data.extra_data = data.extra_data or {}
    data.extra_data.zhanshi = data.extra_data.zhanshi or {}
    data.extra_data.zhanshi[player] = event:getCostData(self).tos
  end,
})

zhanshi:addEffect(fk.PindianFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and
      data.extra_data and (data.extra_data.zhanshi or {})[player]
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, v in pairs(data.results) do
      if table.contains(data.extra_data.zhanshi[player], v.winner) then
        n = n + 3
      end
    end
    if n > 0 then
      player:drawCards(n, zhanshi.name)
    end
  end,
})

return zhanshi