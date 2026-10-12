local gongtu = fk.CreateSkill {
  name = "gongtu",
}

Fk:loadTranslationTable{
  ["gongtu"] = "宫图",
  [":gongtu"] = "游戏开始时，你可以依次指定两种类别；当连续两张被使用的牌的类别与你选择的顺序相同时，你可从牌堆随机获得两张不同点数的牌（点数由你选择）。",

  ["#gongtu-order"] = "宫图：请依次选择两种类别，此后技能将根据所选顺序触发",
  ["@gongtu-order"] = "宫图",
  ["#gongtu-obtain"] = "宫图：请选择两个点数，你从牌堆随机获得两个点数的牌各一张",

  ["$gongtu1"] = "百丈危楼，亦起于微末宣毫之上。",
  ["$gongtu2"] = "图规土木，步步为营，正合水到渠成之妙。",
}

gongtu:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gongtu.name)
  end,
  on_cost = function(self, event, target, player, data)
    local choices = player.room:askToChoices(
      player,
      {
        min_num = 2,
        max_num = 2,
        choices = { "basic", "trick", "equip" },
        skill_name = gongtu.name,
        prompt = "#gongtu-order",
      }
    )

    if #choices == 2 then
      event:setCostData(self, { choices = choices })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local choices = table.map(event:getCostData(self).choices, function(choice) return choice .. "_char" end)
    player.room:setPlayerMark(player, "@gongtu-order", choices)
  end,
})

gongtu:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(gongtu.name) and player:getMark("@gongtu-order") ~= 0) then
      return false
    end

    local room = player.room
    local lastUse = room.logic:getEventsByRule(GameEvent.UseCard, 1, function(e)
      return e.id ~= room.logic:getCurrentEvent().id
    end, Player.HistoryGame)

    local gongtuOrder = player:getMark("@gongtu-order")
    return
      #lastUse > 0 and
      lastUse[1].data.card:getTypeString() .. "_char" == gongtuOrder[1] and
      data.card:getTypeString() .. "_char" == gongtuOrder[2]
  end,
  on_cost = function(self, event, target, player, data)
    local choiceList = {}
    for i = 1, 13 do
      table.insert(choiceList, Card:getNumberStr(i))
    end

    local choices = player.room:askToChoices(
      player,
      {
        min_num = 2,
        max_num = 2,
        choices = choiceList,
        skill_name = gongtu.name,
        prompt = "#gongtu-obtain",
      }
    )

    if #choices == 2 then
      event:setCostData(self, { choices = choices })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = event:getCostData(self).choices
    local idsPack = {
      [choices[1]] = {},
      [choices[2]] = {},
    }
    for _, id in ipairs(room.draw_pile) do
      local number = Fk:getCardById(id):getNumberStr()
      if number == choices[1] then
        table.insert(idsPack[choices[1]], id)
      elseif number == choices[2] then
        table.insert(idsPack[choices[2]], id)
      end
    end

    local toObtain = {}
    if #idsPack[choices[1]] > 0 then
      table.insert(toObtain, room:tableRandomPick(idsPack[choices[1]]))
    end
    if #idsPack[choices[2]] > 0 then
      table.insert(toObtain, room:tableRandomPick(idsPack[choices[2]]))
    end

    if #toObtain > 0 then
      room:obtainCard(player, toObtain, false, fk.ReasonPrey, player, gongtu.name)
    end
  end,
})

return gongtu
