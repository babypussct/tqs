local renshan = fk.CreateSkill {
  name = "renshan",
}

Fk:loadTranslationTable{
  ["renshan"] = "仁善",
  [":renshan"] = "每回合限X次，你不以此法获得牌后，你可以摸一张牌并交给一名手牌数不大于你的其他角色一张牌（X为你的体力值）。",

  ["#renshan-give"] = "仁善：将一张牌交给一名手牌数不大于你的其他角色",

  ["$renshan1"] = "既有宗族之情，何虑天下之争？",
  ["$renshan2"] = "善者不为人所欺，必有春风来报。",
}

renshan:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  times = function (self, player)
    return player.hp - player:usedSkillTimes(renshan.name, Player.HistoryTurn)
  end,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(renshan.name) and player:usedSkillTimes(renshan.name, Player.HistoryTurn) < player.hp then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand and
          move.skillName ~= renshan.name and #move.moveInfo > 0 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, renshan.name)
    if player.dead or player:isNude() then return end
    local room = player.room
    local x = player:getHandcardNum()
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and p:getHandcardNum() <= x
    end)
    if #targets == 0 then return end
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = renshan.name,
      prompt = "#renshan-give",
      cancelable = false,
      no_indicate = true
    })
    if #tos > 0 and #cards > 0 then
      room:obtainCard(tos[1], cards, false, fk.ReasonGive, player, renshan.name)
    end
  end,
})

return renshan
