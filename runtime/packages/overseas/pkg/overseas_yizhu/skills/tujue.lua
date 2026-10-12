local tujue = fk.CreateSkill {
  name = "os__tujue",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__tujue"] = "途绝",
  [":os__tujue"] = "限定技，当你处于濒死状态时，你可以将所有牌交给一名其他角色，你回复X点体力并摸X张牌（X为你以此法交给其的牌数，至少为5）。",

  ["#os__tujue-choose"] = "途绝：你可以将所有牌交给一名角色，回复体力并摸等量牌",

  ["$os__tujue1"] = "返蜀中不得，请纳哀师归命以免死。",
  ["$os__tujue2"] = "天无绝人之路，当置之死地而后生！",
}

tujue:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tujue.name) and
      player.dying and not player:isNude() and
      player:usedSkillTimes(tujue.name, Player.HistoryGame) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#os__tujue-choose",
      skill_name = tujue.name
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("he")
    room:moveCardTo(cards, Card.PlayerHand, event:getCostData(self).tos[1], fk.ReasonGive, tujue.name, nil, false, player)
    if player.dead then return end
    local n = math.max(5, #cards)
    room:recover{
      who = player,
      num = n,
      recoverBy = player,
      skillName = tujue.name,
    }
    if player.dead then return end
    player:drawCards(n, tujue.name)
  end,
})

return tujue
