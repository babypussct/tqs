
local qiansu = fk.CreateSkill {
  name = "qiansu"
}

Fk:loadTranslationTable{
  ["qiansu"] = "谦素",
  [":qiansu"] = "其他角色的结束阶段，若其手牌数比你多，你可以摸三张牌，然后交给该角色其中一张牌。",

  ["#qiansu-invoke"] = "谦素：你可以摸三张牌，交给 %dest 其中一张牌",
  ["#qiansu-give"] = "谦素：请交给 %dest 其中一张牌",

  ["$qiansu1"] = "",
  ["$qiansu2"] = "",
}

qiansu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(qiansu.name) and target.phase == Player.Finish and
      target:getHandcardNum() > player:getHandcardNum()
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = qiansu.name,
      prompt = "#qiansu-invoke::"..target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(3, qiansu.name)
    if target.dead then return end
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #cards == 0 then return end
    local card = room:askToCards(player, {
      skill_name = qiansu.name,
      min_num = 1,
      max_num = 1,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#qiansu-give::"..target.id,
      include_equip = false,
      cancelable = false,
    })
    room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonGive, qiansu.name, nil, false, player)
  end,
})

return qiansu
