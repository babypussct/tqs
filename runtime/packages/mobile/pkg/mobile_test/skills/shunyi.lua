
local U = require "packages.utility.utility"

local shunyi = fk.CreateSkill {
  name = "shunyi",
  dynamic_desc = function(self, player)
    return "shunyi_inner:"..table.concat(table.map(player:getTableMark("shunyi"), function (s)
      return Fk:translate(U.ConvertSuit(s, "int", "sym"))
    end), "")
  end,
}

Fk:loadTranslationTable{
  ["shunyi"] = "顺逸",
  [":shunyi"] = "当你使用点数唯一最小的手牌时，若此牌的花色为<font color='red'>♥</font>且点数大于X（X为你本回合发动本技能的次数），你可以将"..
  "此花色的所有手牌扣置于武将牌上直至当前回合结束，然后你摸一张牌。",

  [":shunyi_inner"] = "当你使用点数唯一最小的手牌时，若此牌的花色为{1}且点数大于X（X为你本回合发动本技能的次数），你可以将"..
  "此花色的所有手牌扣置于武将牌上直至当前回合结束，然后你摸一张牌。",

  ["#shunyi-invoke"] = "顺逸：是否将所有%arg手牌置于武将牌上直到回合结束并摸一张牌？",
  ["$shunyi"] = "顺逸",

  ["$shunyi1"] = "将军岂不知顺天者逸，逆天者劳乎？",
  ["$shunyi2"] = "我本山野村夫，不足与将军论天下大事。",
}

shunyi:addAcquireEffect(function (self, player)
  player.room:setPlayerMark(player, shunyi.name, {Card.Heart})
end)

shunyi:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shunyi.name) and-- not player:isKongcheng() and
      data:isUsingHandcard(player) and
      table.every(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).number > data.card.number
      end) and
      table.contains(player:getMark(shunyi.name), data.card.suit) and
      data.card.number > player:usedSkillTimes(shunyi.name, Player.HistoryTurn)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
      return room:askToSkillInvoke(player, {
        skill_name = shunyi.name,
        prompt = "#shunyi-invoke:::"..data.card:getSuitString(true),
      })
  end,
  on_use = function (self, event, target, player, data)
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).suit == data.card.suit
    end)
    if #cards > 0 then
      player:addToPile("$shunyi", cards, false, shunyi.name)
    end
    if not player.dead then
      player:drawCards(1, shunyi.name)
    end
  end,
})

shunyi:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("$shunyi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("$shunyi"), Player.Hand, player, fk.ReasonJustMove)
  end,
})

return shunyi
