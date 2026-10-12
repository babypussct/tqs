local peidong = fk.CreateSkill {
  name = "peidong",
}

Fk:loadTranslationTable{
  ["peidong"] = "辔东",
  [":peidong"] = "你可以将【<a href=':m_liuyi__liulongcanjia'>六龙骖驾</a>】：<br />" ..
  "从装备区移动至下家，视为使用【杀】；<br />" ..
  "从其他角色场上获得，视为使用【闪】；<br />" ..
  "从手牌或牌堆中亮出，视为使用【桃】；<br />" ..
  "从游戏外置入宝物栏，视为使用【酒】。",

  ["#peidong-viewAs"] = "辔东：你可执行对应操作，视为使用此牌",

  ["$peidong1"] = "扶桑之所出，乃在朝阳溪。",
  ["$peidong2"] = "中心陵苍昊，布叶盖天涯。",
  ["$peidong3"] = "日出登东干，既夕没西枝。",
  ["$peidong4"] = "愿得纡阳辔，回日使东驰。",
}

local U = require "packages.utility.utility"

peidong:addEffect("viewas", {
  prompt = "#peidong-viewAs",
  pattern = "peach,slash,jink,analeptic",
  interaction = function(self, player)
    local allNames = { "slash" }
    local extraSlashes = table.filter(Fk:getAllCardNames("b"), function(name) return name:endsWith("__slash") end)
    table.insertTable(allNames, extraSlashes)
    table.insertTable(allNames, { "jink", "peach", "analeptic" })

    local names = {}
    local liulongFound = table.find(player:getEquipments(Card.SubtypeTreasure), function(id)
      return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
    end)
    if
      liulongFound and
      player:getNextAlive() ~= player and
      player:getNextAlive():canMoveCardIntoEquip(liulongFound)
    then
      table.insert(names, "slash")
      table.insertTable(names, extraSlashes)
    elseif
      table.find(Fk:currentRoom().alive_players, function(p)
        return table.find(p:getCardIds("ej"), function(id)
          return Fk:getCardById(id, true).name == "m_liuyi__liulongcanjia"
        end) ~= nil
      end)
    then
      table.insert(names, "jink")
    elseif
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
      end) or
      table.find(Fk:currentRoom().draw_pile, function(id)
        return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
      end)
    then
      table.insert(names, "peach")
    else
      local liulongHorseFound = table.find(Fk:currentRoom().void, function(id)
        return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
      end)

      if liulongHorseFound and player:canMoveCardIntoEquip(liulongHorseFound) then
        table.insert(names, "analeptic")
      end
    end

    if #names == 0 then
      return
    end

    names = player:getViewAsCardNames(peidong.name, names)
    if #names == 0 then
      return
    end

    return UI.CardNameBox { choices = names, all_choices = allNames }
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  view_as = function(self, player, cards)
    if #cards ~= 0 or self.interaction.data == nil then
      return
    end

    local name = self.interaction.data
    local liulongFound
    if name:endsWith("slash") then
      liulongFound = table.find(player:getEquipments(Card.SubtypeTreasure), function(id)
        return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
      end)
    elseif name == "jink" then
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        liulongFound = table.find(p:getCardIds("ej"), function(id)
          return Fk:getCardById(id, true).name == "m_liuyi__liulongcanjia"
        end)

        if liulongFound then
          break
        end
      end
    elseif name == "peach" then
      liulongFound = table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
      end)
      if not liulongFound then
        liulongFound = table.find(Fk:currentRoom().draw_pile, function(id)
          return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
        end)
      end
    elseif name == "analeptic" then
      liulongFound = table.find(Fk:currentRoom().void, function(id)
        return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
      end)
    end

    if not liulongFound then
      return
    end

    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = peidong.name
    card:addFakeSubcard(liulongFound)
    return card
  end,
  before_use = function (self, player, use)
    ---@type string
    local skillName = peidong.name
    local room = player.room

    local liulongCard = use.card.fake_subcards
    if use.card.trueName == "slash" then
      local nextPlayer = player:getNextAlive()
      if nextPlayer ~= player then
        room:moveCardIntoEquip(nextPlayer, liulongCard, skillName, true, player)
      else
        return skillName
      end
    elseif use.card.name == "jink" then
      room:obtainCard(player, liulongCard, true, fk.ReasonPrey, player, skillName)
    elseif use.card.name == "peach" then
      room:moveCardTo(liulongCard, Card.Processing, nil, fk.ReasonPut, skillName, nil, true, player)
      room:cleanProcessingArea(liulongCard, skillName)
    elseif use.card.name == "analeptic" then
      room:moveCardIntoEquip(player, liulongCard, skillName, true, player)
    end
  end,
  enabled_at_play = function(self, player)
    local names = {}
    local liulongFound = table.find(player:getEquipments(Card.SubtypeTreasure), function(id)
      return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
    end)
    if
      liulongFound and
      player:getNextAlive() ~= player and
      player:getNextAlive():canMoveCardIntoEquip(liulongFound)
    then
      table.insert(names, "slash")
    elseif
      table.find(Fk:currentRoom().alive_players, function(p)
        return table.find(p:getCardIds("ej"), function(id)
          return Fk:getCardById(id, true).name == "m_liuyi__liulongcanjia"
        end) ~= nil
      end)
    then
      table.insert(names, "jink")
    elseif
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
      end) or
      table.find(Fk:currentRoom().draw_pile, function(id)
        return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
      end)
    then
      table.insert(names, "peach")
    else
      local liulongHorseFound = table.find(Fk:currentRoom().void, function(id)
        return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
      end)

      if liulongHorseFound and player:canMoveCardIntoEquip(liulongHorseFound) then
        table.insert(names, "analeptic")
      end
    end

    if #names == 0 then
      return
    end

    return #player:getViewAsCardNames(peidong.name, names) > 0
  end,
  enabled_at_response = function(self, player, response)
    if response then
      return false
    end

    local names = {}
    local liulongFound = table.find(player:getEquipments(Card.SubtypeTreasure), function(id)
      return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
    end)
    if
      liulongFound and
      player:getNextAlive() ~= player and
      player:getNextAlive():canMoveCardIntoEquip(liulongFound)
    then
      table.insert(names, "slash")
    elseif
      table.find(Fk:currentRoom().alive_players, function(p)
        return table.find(p:getCardIds("ej"), function(id)
          return Fk:getCardById(id, true).name == "m_liuyi__liulongcanjia"
        end) ~= nil
      end)
    then
      table.insert(names, "jink")
    elseif
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
      end) or
      table.find(Fk:currentRoom().draw_pile, function(id)
        return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
      end)
    then
      table.insert(names, "peach")
    else
      local liulongHorseFound = table.find(Fk:currentRoom().void, function(id)
        return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
      end)

      if liulongHorseFound and player:canMoveCardIntoEquip(liulongHorseFound) then
        table.insert(names, "analeptic")
      end
    end

    if #names == 0 then
      return
    end

    return #player:getViewAsCardNames(peidong.name, names) > 0
  end,
})

peidong:addEffect("distance", {
  correct_func = function(self, from, to, card)
    if card and card.trueName == "slash" and table.contains(card.skillNames, peidong.name) then
      if Fk:currentRoom():getCardOwner(card.fake_subcards[1]) == from and from:getNextAlive() == to then
        local kNum = 0
        table.forEach(Fk:currentRoom().alive_players, function(p)
          kNum = kNum + #table.filter(p:getCardIds("ej"), function(id)
            return Fk:getCardById(id).number == 13
          end)
        end)
        return kNum
      end
    end
  end,
})

peidong:addAcquireEffect(function(self, player)
  local room = player.room
  if table.contains(room.disabled_packs, Fk:cloneCard("m_liuyi__liulongcanjia").package.name) then
    room:prepareDeriveCards({ { "m_liuyi__liulongcanjia", Card.Heart, 13 }, }, "peidong_derivecards")
  end
end)

return peidong
