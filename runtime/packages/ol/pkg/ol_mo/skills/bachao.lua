local bachao = fk.CreateSkill {
  name = "bachao",
}

Fk:loadTranslationTable{
  ["bachao"] = "霸朝",
  [":bachao"] = "出牌阶段开始时，你可以令所有其他角色同时选择是否交给你一张牌，然后你可以对未以此法交给你非基本牌的一名角色造成1点伤害，"..
  "若你选择自己，本阶段你使用当前手牌无次数和距离限制并<a href='#RuMoDesc'><font color='red'>入魔</font></a>。",

  ["#bachao-invoke"] = "霸朝：令所有角色同时选择是否交给你一张牌，然后可以对一名未交给你非基本牌的角色造成1点伤害",
  ["#bachao-give"] = "霸朝：交给 %src 一张牌，若不交出非基本牌则可能受到伤害",
  ["#bachao-choose"] = "霸朝：你可以对其中一名角色造成伤害，若选择自己则本阶段使用手牌无距离次数限制",
  ["@@bachao-inhand-phase"] = "霸朝",

  ["$bachao1"] = "众卿别来无恙！",
  ["$bachao2"] = "改弦更张、乾坤倒转，待我重整江山！",
  ["$bachao3"] = "豺狼聚野，万民皆唤我，魂归来兮！",
  ["$bachao4"] = "钝劣无能者，跪服便罢！",
  ["$bachao5"] = "天下离孤久矣，此来当还黎庶以泰宁！",
}

bachao:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bachao.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = bachao.name,
      prompt = "#bachao-invoke",
    }) then
      event:setCostData(self, {tos = room:getOtherPlayers(player)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    local result = room:askToJointCards(player, {
      players = targets,
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = bachao.name,
      cancelable = true,
      prompt = "#bachao-give:"..player.id,
    })
    local moves = {}
    targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:isNude()
    end)
    table.insert(targets, player)
    for p, cards in pairs(result) do
      if #cards > 0 then
        table.insert(moves, {
          ids = cards,
          from = p,
          to = player,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonGive,
          skillName = bachao.name,
          proposer = p,
          moveVisible = false,
        })
        if Fk:getCardById(cards[1]).type == Card.TypeBasic then
          table.insert(targets, p)
        end
      else
        table.insert(targets, p)
      end
    end
    if #moves > 0 then
      room:moveCards(table.unpack(moves))
    end
    if player.dead then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#bachao-choose",
      skill_name = bachao.name,
      cancelable = true,
    })
    if #to > 0 then
      room:damage{
        from = player,
        to = to[1],
        damage = 1,
        skillName = bachao.name,
      }
      if to[1] == player and not player.dead then
        if not player:hasSkill("#rumo", true) then
          room:notifySkillInvoked(player, bachao.name, "big")
          room:handleAddLoseSkills(player, "#rumo", nil, false, true)
        end
        for _, id in ipairs(player:getCardIds("h")) do
          room:setCardMark(Fk:getCardById(id), "@@bachao-inhand-phase", 1)
        end
      end
    end
  end,
})

bachao:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return
      #Card:getIdList(data.card) == 1 and
      Fk:getCardById(Card:getIdList(data.card)[1]):getMark("@@bachao-inhand-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

bachao:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and #Card:getIdList(card) == 1 and
      Fk:getCardById(Card:getIdList(card)[1]):getMark("@@bachao-inhand-phase") > 0
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    return card and #Card:getIdList(card) == 1 and
      Fk:getCardById(Card:getIdList(card)[1]):getMark("@@bachao-inhand-phase") > 0
  end,
})

return bachao
