
local chidai = fk.CreateSkill {
  name = "chidai",
}

Fk:loadTranslationTable{
  ["chidai"] = "斥怠",
  [":chidai"] = "一名角色的回合结束时，若其手牌数小于体力值，你可以令其回复1点体力并摸X张牌；"..
  "若其手牌数大于体力值，你可以随机获得其X张手牌；若其手牌数等于体力值，你可以摸一张牌（X为其手牌数与体力值之差，且至多为5）。",

  ["#chidai1-invoke"] = "斥怠：你可以令 %dest 回复1点体力并摸%arg张牌",
  ["#chidai2-invoke"] = "斥怠：你可以随机获得 %dest %arg张手牌",
  ["#chidai3-invoke"] = "斥怠：你可以摸一张牌",

  ["$chidai1"] = "",
  ["$chidai2"] = "",
}

chidai:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chidai.name) and not target.dead and
      not (target == player and player:getHandcardNum() > player.hp)
  end,
  on_cost = function (self, event, target, player, data)
    local n = target.hp - target:getHandcardNum()
    local index = 3
    if n > 0 then
      index = 1
    elseif n < 0 then
      index = 2
    end
    if player.room:askToSkillInvoke(player, {
      skill_name = chidai.name,
      prompt = "#chidai"..index.."-invoke::"..target.id..":"..math.abs(n),
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target.hp - target:getHandcardNum()
    if n > 0 then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = chidai.name
      }
      if not target.dead then
        target:drawCards(n, chidai.name)
      end
    elseif n < 0 then
      local cards = room:tableRandomPick(target:getCardIds("h"), -n)
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, chidai.name, nil, false, player)
    elseif n == 0 then
      player:drawCards(1, chidai.name)
    end
  end,
})

return chidai
