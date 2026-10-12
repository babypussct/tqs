local hangzhu = fk.CreateSkill {
  name = "hangzhu",
}

Fk:loadTranslationTable{
  ["hangzhu"] = "夯筑",
  [":hangzhu"] = "出牌阶段限一次，你可以将至少一张牌置于你的武将牌上，称为“基”，然后令一名其他角色弃置所有这些点数的牌。" ..
  "若“基”中有重复点数，则弃置所有重复点数的“基”并摸等量张牌；若“基”包含13个点数，你可将所有“基”交给一名角色并令其回复体力至上限。",

  ["#hangzhu-active"] = "夯筑：你可将至少一张牌置于你的武将牌上，称为“基”，然后令一名其他角色弃置所有这些点数的牌",
  ["hangzhu_ji"] = "基",
  ["#hangzhu-choose"] = "夯筑：你可令一名其他角色弃置所有你本次置为“基”的点数的牌",
  ["#hangzhu-give"] = "夯筑：你可将所有“基”交给一名角色并令其回复体力至上限",

  ["$hangzhu1"] = "夯土为基，须分九层，不容丝毫差池。",
  ["$hangzhu2"] = "基石斜则梁殿颓，不足成万丈之始。",
}

hangzhu:addEffect("active", {
  prompt = "#hangzhu-active",
  min_card_num = 1,
  max_card_num = function(self, player)
    return math.max(#player:getCardIds("he"), 1)
  end,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(hangzhu.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = Util.TrueFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = hangzhu.name
    local player = effect.from
    local cards = effect.cards
    player:addToPile("hangzhu_ji", cards, true, skillName, player)
    if not player:isAlive() then
      return false
    end

    local targets = room:getOtherPlayers(player, false)
    if #targets > 0 then
      local to = room:askToChoosePlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = skillName,
          cancelable = false,
          prompt = "#hangzhu-choose",
        }
      )[1]

      local toThrow = table.filter(to:getCardIds("he"), function(id)
        local number = Fk:getCardById(id).number
        if number < 1 or to:prohibitDiscard(id) then
          return false
        end

        return not not table.find(cards, function(cardId) return Fk:getCardById(cardId).number == number end)
      end)

      if #toThrow > 0 then
        room:throwCard(toThrow, skillName, to, to)
      end
    end

    if not player:isAlive() then
      return false
    end

    local numberMapper = {}
    table.forEach(player:getPile("hangzhu_ji"), function(id)
      local number = Fk:getCardById(id):getNumberStr()
      numberMapper[number] = numberMapper[number] or {}
      table.insert(numberMapper[number], id)
    end)

    local toDiscard = {}
    local numberNum = 0
    for _, ids in pairs(numberMapper) do
      if #ids > 1 then
        table.insertTable(toDiscard, ids)
      else
        numberNum = numberNum + 1
      end
    end

    if #toDiscard > 0 then
      room:throwCard(toDiscard, skillName, player, player)
      if player:isAlive() then
        player:drawCards(#toDiscard, skillName)
      end
    end

    if player:isAlive() and numberNum > 12 then
      local tos = room:askToChoosePlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          targets = room:getAlivePlayers(false),
          skill_name = skillName,
          prompt = "#hangzhu-give",
        }
      )

      if #tos > 0 then
        local to = tos[1]
        room:obtainCard(to, player:getPile("hangzhu_ji"), true, fk.ReasonGive, player, skillName)

        if to:isAlive() and to:isWounded() then
          room:recover{
            who = to,
            num = to.maxHp - to.hp,
            skillName = skillName,
            recoverBy = player,
          }
        end
      end
    end
  end,
})

return hangzhu
