local jiejie = fk.CreateSkill{
  name = "jiejie",
  attached_skill_name = "jiejie&",
  max_branches_use_time = {
    ["jiejie_most"] = {
      [Player.HistoryRound] = 2,
    },
  },
  related_skills = { "qingshix" },
}

Fk:loadTranslationTable{
  ["jiejie"] = "诫节",
  [":jiejie"] = "每名角色的出牌阶段限一次，当前回合角色可以令你观看其手牌，然后你可以选择一种花色，若其手牌："..
  "包含此花色，其本回合使用此花色的牌无次数限制，然后弃置其余花色的手牌；不包含此花色，其从牌堆或弃牌堆中随机获得此花色的一张牌。"..
  "每轮限两次，若其本轮以此法令你观看的牌所包含的花色为唯一最多，你视为对其发动一次〖清识〗。",

  ["#jiejie"] = "诫节：观看你的手牌，然后选择一种花色，根据是否包含此花色执行效果",
  ["#jiejie-choice"] = "诫节：选择一种花色，包含此花色则其弃置其他花色手牌，否则其获得一张此花色牌",
  ["@jiejie-round"] = "诫节",

  ["$jiejie1"] = "职守，人之大义也，安可不出？",
  ["$jiejie2"] = "为人执鞭而弃其事，不祥，不可也。",
  ["$jiejie3"] = "军旅之间可以济者，唯仁与恕。",
  ["$jiejie4"] = "在职思其所司，在义思其所立。",
}


jiejie:addEffect("active", {
  anim_type = "control",
  prompt = "#jiejie",
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(jiejie.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local suits = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    table.removeOne(suits, Card.NoSuit)
    local yes = #suits > player:getMark("@jiejie-round")
    if yes then
      room:setPlayerMark(player, "@jiejie-round", #suits)
    end
    local choice = room:askToViewCardsAndChoice(player, {
      cards = player:getCardIds("h"),
      choices = { "log_spade", "log_heart", "log_club", "log_diamond", "Cancel" },
      skill_name = jiejie.name,
      prompt = "#jiejie-choice::"..player.id,
    })
    if choice ~= "Cancel" then
      if table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getSuitString(true) == choice
      end) then
        local others = table.filter(player:getCardIds("h"), function (id)
          return Fk:getCardById(id):getSuitString(true) ~= choice and not player:prohibitDiscard(id)
        end)
        if #others > 0 then
          room:throwCard(others, jiejie.name, player, player)
        end
        if not player.dead then
          room:addTableMarkIfNeed(player, "jiejie-turn", choice)
        end
      else
        local card = room:getCardsFromPileByRule(".|.|" .. string.sub(choice, 5))
        if #card == 0 then
          card = room:getCardsFromPileByRule(".|.|" .. string.sub(choice, 5), 1, "discardPile")
        end
        if #card > 0 then
          room:obtainCard(player, card, false, fk.ReasonPrey, player, jiejie.name)
        end
      end
    end
    if
      yes and
      not player.dead and
      jiejie:withinBranchTimesLimit(player, "jiejie_most", Player.HistoryRound)
    then
      player:addSkillBranchUseHistory(jiejie.name, "jiejie_most", 1)
      local skill = Fk.skills["qingshix"] --[[@as TriggerSkill]]
      local event = fk.Damaged:new(room, player, {})
      event:setCostData(skill, {tos = {player}})
      skill:use(event, player, player, {})
    end
  end,
})

jiejie:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(player:getTableMark("jiejie-turn"), data.card:getSuitString(true))
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

jiejie:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    local mark = player:getTableMark("jiejie-turn")
    if #mark > 0 then
      return card and card:matchVSPattern(".|.|" ..
        table.concat(table.map(mark, function(suit) return string.sub(suit, 5) end), ","))
    end
  end,
})

return jiejie
