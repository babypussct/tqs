local osYuhua = fk.CreateSkill {
  name = "os__yuhua",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__yuhua"] = "羽化",
  [":os__yuhua"] = "锁定技，弃牌阶段，你的非基本牌不计入手牌上限。当你于回合外失去非基本牌后，" ..
  "你可观看牌堆顶的X张牌并将其置于牌堆顶或牌堆底，然后你可摸X张牌（X为你此次失去牌的数量且至多为5）。",

  ["os__yuhuaDraw"] = "摸%arg张牌",

  ["$os__yuhua1"] = "凤羽飞烟，乘化仙尘。",
  ["$os__yuhua2"] = "此乃仙人之物，不可轻弃。",
}

osYuhua:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(osYuhua.name) and player.room.current ~= player then
      for _, move in ipairs(data) do
        if move.from == player and move.to ~= player then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              Fk:getCardById(info.cardId).type ~= Card.TypeBasic then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = osYuhua.name })
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osYuhua.name
    local num = 0
    for _, move in ipairs(data) do
      if move.from == player then
        num = num + #table.filter(move.moveInfo, function(info)
          return (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip)
        end)
      end
    end
    num = math.min(5, num)
    local room = player.room
    room:askToGuanxing(player, { cards = room:getNCards(num) })
    if
      room:askToChoice(
        player,
        {
          choices = { "os__yuhuaDraw:::" .. num, "Cancel" },
          skill_name = skillName,
        }
      ) ~= "Cancel"
    then
      player:drawCards(num, skillName)
    end
  end,
})

osYuhua:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(osYuhua.name) and card.type ~= Card.TypeBasic
  end,
})

osYuhua:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(osYuhua.name) and player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    ---@type string
    local skillName = osYuhua.name
    player:broadcastSkillInvoke(skillName)
    player.room:notifySkillInvoked(player, skillName, "defensive")
  end,
})

return osYuhua
