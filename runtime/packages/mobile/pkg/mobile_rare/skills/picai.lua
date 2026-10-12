local picai = fk.CreateSkill {
  name = "changshi__picai",
}

Fk:loadTranslationTable{
  ["changshi__picai"] = "庀材",
  [":changshi__picai"] = "出牌阶段限一次，你可以进行判定，若结果与本次流程中的其他判定结果均不同，你可重复此流程。最后你可将本次流程中所有"..
  "生效的判定牌交给一名角色。",

  ["#changshi__picai"] = "庀材：连续判定直到出现相同花色，然后可以将判定牌交给一名角色",
  ["#changshi__picai-ask"] = "庀材：是否继续判定？",
  ["#changshi__picai-give"] = "庀材：你可以将这些判定牌交给一名角色",

  ["$changshi__picai1"] = "修得广厦千万，可庇汉室不倾。",
}

picai:addEffect("active", {
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(picai.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from

    local cards = {}
    while true do
      local parsePattern = table.concat(table.map(cards, function(card)
        return card:getSuitString()
      end), ",")

      local judge = {
        who = player,
        reason = picai.name,
        pattern = ".|.|" .. (parsePattern == "" and "." or "^(" .. parsePattern .. ")"),
        skipDrop = true,
      }
      room:judge(judge)
      table.insert(cards, judge.card)
      if not table.every(cards, function(card)
          return card == judge.card or judge.card:compareSuitWith(card, true)
        end) or
        player.dead or
        not room:askToSkillInvoke(player, {
          skill_name = picai.name,
          prompt = "#changshi__picai-ask",
        })
      then
        break
      end
    end

    cards = table.filter(cards, function(card)
      return room:getCardArea(card.id) == Card.Processing
    end)
    if #cards == 0 then return end

    if not player.dead then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        skill_name = picai.name,
        prompt = "#changshi__picai-give",
        cancelable = true,
      })
      if #to > 0 then
        room:moveCardTo(cards, Card.PlayerHand, to[1], fk.ReasonGive, picai.name, nil, true, player)
      end
    end
    room:cleanProcessingArea(cards)
  end,
})

return picai
