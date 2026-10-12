local moyou = fk.CreateSkill {
  name = "moyou",
}

Fk:loadTranslationTable{
  ["moyou"] = "谟猷",
  [":moyou"] = "你每使用两张手牌结算后，可以摸三张牌令本回合使用牌无距离限制，并选择一种花色弃置手牌中所有此花色的牌，"..
    "若你的手牌未含有所有类型，则你下次使用基本牌无次数限制，下次使用锦囊牌不可响应。",

  ["#moyou-invoke"] = "谟猷：你可以摸三张牌，然后弃置一种花色的所有手牌",
  ["#moyou-choice"] = "谟猷：请弃置一种花色的手牌",
  ["@moyou"] = "谟猷",

  ["$moyou1"] = "阿瞒依计而行，本初指日可缚。",
  ["$moyou2"] = "谋定而动，何人能阻？",
}

local U = require "packages.utility.utility"

moyou:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(moyou.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player:getMark(moyou.name) % 2 == 0 or
      player.room:askToSkillInvoke(player, {
        skill_name = moyou.name,
        prompt = "#moyou-invoke",
      })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, moyou.name)
    if player:getMark(moyou.name) % 2 == 1 then return end
    room:addPlayerMark(player, MarkEnum.BypassDistancesLimit.."-turn", 1)
    player:drawCards(3, moyou.name)
    if player.dead or player:isKongcheng() then return end
    local listNames = { "log_spade", "log_club", "log_heart", "log_diamond" }
    local listCards = { {}, {}, {}, {} }
    for _, id in ipairs(player:getCardIds("h")) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit and not player:prohibitDiscard(id) then
        table.insertIfNeed(listCards[suit], id)
      end
    end
    if table.every(listCards, function(v)
      return #v == 0
    end) then return end
    local choices = U.askForChooseCardList(room, player, listNames, listCards, 1, 1, moyou.name, "#moyou-choice", false, false)
    local cards = listCards[table.indexOf(listNames, choices[1])]
    room:throwCard(cards, moyou.name, player, player)
    if player.dead then return end
    listNames = {0, 0, 0}
    for _, id in ipairs(player:getCardIds("h")) do
      listNames[Fk:getCardById(id).type] = 1
    end
    if not table.every(listNames, function(v)
      return v == 1
    end) then
      room:setPlayerMark(player, "@moyou", { "basic_char", "trick_char" })
    end
  end,
})

moyou:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and player:hasSkill(moyou.name) and
      table.contains(player:getTableMark("@moyou"), data.card:getTypeString() .. "_char")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:removeTableMark(player, "@moyou", data.card:getTypeString() .. "_char")
    if data.card:isCommonTrick() then
      data.disresponsiveList = table.simpleClone(player.room.players)
    end
  end,
})

--技能被无效时会获得永久的基本牌无次数限制、锦囊牌不可被抵消buff
moyou:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      table.contains(player:getTableMark("@moyou"), data.card:getTypeString() .. "_char")
  end,
  on_refresh = function(self, event, target, player, data)
    if data.card.type == Card.TypeBasic then
      data.extraUse = true
    elseif data.card:isCommonTrick() then
      data.unoffsetableList = table.simpleClone(player.room.players)
    end
  end,
})

moyou:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return card and card.type == Card.TypeBasic and table.contains(player:getTableMark("@moyou"), "basic_char")
  end,
})

moyou:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, moyou.name, 0)
  room:setPlayerMark(player, "@moyou", 0)
end)

moyou:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return moyou
