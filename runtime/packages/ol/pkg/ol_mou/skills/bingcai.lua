local bingcai = fk.CreateSkill{
  name = "bingcai",
}

Fk:loadTranslationTable{
  ["bingcai"] = "并才",
  [":bingcai"] = "每回合第一张基本牌被使用时，你可重铸一张牌，若这两张牌均为伤害牌或非伤害牌，则此牌额外结算一次。"..
    "然后若重铸的牌为锦囊牌，你为〖理贤〗添加一个牌名：【顺手牵羊】；【过河拆桥】；【铁索连环】。"..
    "以上牌名均添加完后，〖理贤〗于你的准备阶段也可发动。",

  ["#bingcai1-invoke"] = "并才：是否重铸一张牌？若为伤害类，此%arg额外结算一次",
  ["#bingcai2-invoke"] = "并才：是否重铸一张牌？若不为伤害类，此%arg额外结算一次",
  ["#bingcai-choice"] = "并才：选择为“理贤”添加的牌名",

  ["$bingcai1"] = "举案并肩，良缘天定。",
  ["$bingcai2"] = "愿得一心人，白首不相离。",
}


local U = require "packages.utility.utility"

bingcai:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(bingcai.name) and data.card.type == Card.TypeBasic and not player:isNude() then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.card.type == Card.TypeBasic
      end, Player.HistoryTurn)
      return #events == 1 and events[1] == player.room.logic:getCurrentEvent()
    end
  end,
  on_cost = function(self, event, target, player, data)
    local i = data.card.is_damage_card and 1 or 2
    local card = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = bingcai.name,
      cancelable = true,
      pattern = ".",
      prompt = "#bingcai"..i.."-invoke:::"..data.card:toLogString(),
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(event:getCostData(self).cards[1])
    room:recastCard(event:getCostData(self).cards, player, bingcai.name)
    if (card.is_damage_card and data.card.is_damage_card) or
      (not card.is_damage_card and not data.card.is_damage_card) then
      data.additionalEffect = (data.additionalEffect or 0) + 1
    end
    if card.type == Card.TypeTrick and player:hasSkill("lixian", true) then
      local names = {"snatch", "dismantlement", "iron_chain"}
      local mark = player:getMark("@$lixian")
      if type(mark) ~= "table" then
        mark = {"ex_nihilo"}
      else
        names = table.filter(names, function(name)
          return not table.contains(mark, name)
        end)
        if #names == 0 then return end
      end
      local choice = U.askForChooseCardNames(room, player,
        names,
        1,
        1,
        bingcai.name,
        "#bingcai-choice"
      )[1]
      table.insert(mark, choice)
      room:setPlayerMark(player, "@$lixian", mark)
    end
  end,
})

return bingcai
