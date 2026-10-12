local rencheng = fk.CreateSkill {
  name = "rencheng",
  dynamic_desc = function (self, player, lang)
    if player:getMark("rencheng_upgrade") > 0 then
      return "rencheng_upgrade"
    else
      return "rencheng"
    end
  end,
}

Fk:loadTranslationTable{
  ["rencheng"] = "仁诚",
  [":rencheng"] = "出牌阶段限一次，你可以摸两张牌，然后你可以交给一名其他角色至多两张牌。",

  [":rencheng_upgrade"] = "出牌阶段限一次，你可以摸三张牌，然后你可以交给一名其他角色至多三张牌，若这些牌中："..
  "有基本牌，其下个出牌阶段使用牌无距离限制；有锦囊牌，你可弃置一名角色区城内一张牌；有装备牌，你与其各回复1点体力。",

  ["#rencheng"] = "仁诚：你可以摸%arg张牌，然后可交给1名其他角色至多%arg张牌",
  ["#rencheng-give"] = "仁诚：你可以交给一名其他角色至多%arg张牌",
  ["#rencheng-discard"] = "仁诚：你可以弃置一名角色区城内一张牌",
  ["@@rencheng"] = "仁诚",

  ["$rencheng1"] = "父祖珠玉在前，孤岂为桓灵。",
  ["$rencheng2"] = "在庭之木不翦，无以成栋梁。",
}

rencheng:addEffect("active", {
  anim_type = "support",
  prompt = function(self, player)
    return "#rencheng:::" .. ((player:getMark("rencheng_upgrade") > 0) and "3" or "2")
  end,
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function (self, player)
    return player:usedSkillTimes(rencheng.name, Player.HistoryPhase) == 0
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local skillName = rencheng.name
    local upgrade = (player:getMark("rencheng_upgrade") > 0)
    local x = upgrade and 3 or 2
    player:drawCards(x, skillName)
    if player.dead or player:isNude() or #room.alive_players < 2 then return end
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = x,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = skillName,
      prompt = "#rencheng-give:::" .. x,
      cancelable = true,
    })
    if #tos > 0 and #cards > 0 then
      if upgrade then
        local to = tos[1]
        local types = {}
        for _, id in ipairs(cards) do
          table.insertIfNeed(types, Fk:getCardById(id).type)
        end
        room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, skillName, nil, false, player)
        if table.contains(types, Card.TypeBasic) and not to.dead then
          room:setPlayerMark(to, "@@rencheng", 1)
        end
        if table.contains(types, Card.TypeTrick) and not player.dead then
          tos = table.filter(room.alive_players, function(p)
            return not p:isAllNude()
          end)
          if #tos > 0 then
            tos = room:askToChoosePlayers(player, {
              min_num = 1,
              max_num = 1,
              targets = tos,
              skill_name = skillName,
              prompt = "#rencheng-discard",
              cancelable = true,
            })
            if #tos > 0 then
              local id = room:askToChooseCard(player, {
                target = tos[1],
                flag = "he",
                skill_name = skillName,
              })
              room:throwCard(id, skillName, tos[1], player)
            end
          end
        end
        if table.contains(types, Card.TypeEquip) then
          if not player.dead and player:isWounded() then
            room:recover{
              who = player,
              num = 1,
              recoverBy = player,
              skillName = skillName
            }
          end
          if not to.dead and to:isWounded() then
            room:recover{
              who = to,
              num = 1,
              recoverBy = player,
              skillName = skillName
            }
          end
        end
      else
        room:moveCardTo(cards, Card.PlayerHand, tos[1], fk.ReasonGive, skillName, nil, false, player)
      end
    end
  end,
})

rencheng:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill)
    return player.phase == Player.Play and player:getMark("@@rencheng") > 0
  end,
})

rencheng:addEffect(fk.EventPhaseEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return player == target and player.phase == Player.Play and player:getMark("@@rencheng") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@rencheng", 0)
  end
})

return rencheng
