local function findSkillOwner(skill_name, excluded)
  return table.filter(Fk:currentRoom().alive_players, function (p)
    return p:hasSkill(skill_name) and p:usedSkillTimes(skill_name, Player.HistoryPhase) == 0 and p ~= excluded
  end)
end

local jiejie = fk.CreateSkill{
  name = "jiejie&",
  dynamic_desc = function (self, player, lang)
    local owners = findSkillOwner("jiejie", player)
    if #owners == 1 then
      return "jiejie&-solo:" .. owners[1]:toLogString()
    else
      return "jiejie&"
    end
  end
}

Fk:loadTranslationTable{
  ["jiejie&"] = "诫节",
  [":jiejie&"] = "出牌阶段限一次，你可以令一名拥有〖诫节〗的其他角色观看你的手牌，然后其可以选择一种花色，若你手牌："..
  "包含此花色，你本回合使用此花色的牌无次数限制，然后弃置其余花色的手牌；不包含此花色，你获得此花色的一张牌。"..
  "若你以此法向其展示牌所包含的花色为本轮唯一最多，其视为对你发动一次〖清识〗。",
  [":jiejie&-solo"] = "出牌阶段限一次，你可以令{1}观看你的手牌，然后其可以选择一种花色，若你手牌："..
  "包含此花色，你本回合使用此花色的牌无次数限制，然后弃置其余花色的手牌；不包含此花色，你获得此花色的一张牌。"..
  "若你以此法向其展示牌所包含的花色为本轮唯一最多，其视为对你发动一次〖清识〗。",

  ["#jiejie&"] = "诫节：令%src观看你的手牌，然后其选择一种花色，根据是否包含此花色执行效果",
  ["#jiejie&-multi"] = "诫节：令一名拥有〖诫节〗的其他角色观看你的手牌，然后其选择一种花色，根据是否包含此花色执行效果",
}

jiejie:addEffect("active", {
  anim_type = "control",
  prompt = function(self, player)
    local owners = findSkillOwner("jiejie", player)
    if #owners == 1 then
      return "#jiejie&:" .. owners[1].id
    else
      return "#jiejie&-multi"
    end
  end,
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and #findSkillOwner("jiejie", player) > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected)
    if #findSkillOwner("jiejie", player) == 1 then
      return false
    else
      return #selected == 0 and table.contains(findSkillOwner("jiejie", player), to_select)
    end
  end,
  feasible = function (self, player, selected)
    if #findSkillOwner("jiejie", player) == 1 then
      return #selected == 0
    else
      return #selected == 1
    end
  end,
  on_cost = function (self, player, data, extra_data)
    local owners = findSkillOwner("jiejie", player)
    if #owners == 1 then
      data.tos = owners
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    target:addSkillUseHistory("jiejie", 1)
    target:broadcastSkillInvoke("jiejie")
    local suits = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    table.removeOne(suits, Card.NoSuit)
    local yes = #suits > target:getMark("@jiejie-round")
    if yes then
      room:setPlayerMark(target, "@jiejie-round", #suits)
    end
    local choice = room:askToViewCardsAndChoice(target, {
      cards = player:getCardIds("h"),
      choices = { "log_spade", "log_heart", "log_club", "log_diamond", "Cancel" },
      skill_name = "jiejie",
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
          room:throwCard(others, "jiejie", player, player)
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
      not target.dead and
      Fk.skills["jiejie"]:getSkeleton():withinBranchTimesLimit(target, "jiejie_most", Player.HistoryRound)
    then
      target:addSkillBranchUseHistory("jiejie", "jiejie_most", 1)
      local skill = Fk.skills["qingshix"] --[[@as TriggerSkill]]
      local event = fk.Damaged:new(room, target, {})
      event:setCostData(skill, {tos = {player}})
      skill:use(event, target, target, {})
    end
  end,
})

return jiejie
