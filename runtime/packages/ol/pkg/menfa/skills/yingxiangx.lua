local yingxiangx = fk.CreateSkill {
  name = "yingxiangx",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yingxiangx"] = "萦香",
  [":yingxiangx"] = "锁定技，其他角色获得你的牌称为“萦香”。“萦香”被使用后，你和有“萦香”的角色各摸一张牌。"..
    "若“萦香”不因使用而失去，你发动一次〖清绝〗（每轮限一次）。",

  ["@@yingxiangx-inhand"] = "萦香",

  ["$yingxiangx1"] = "风丝寸缕轻柔肠，夜雨把盏，屏后萦香。",
  ["$yingxiangx2"] = "白马簪缨缄数语，明明公议，空留荀香。",
}

yingxiangx:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yingxiangx.name) then
      for _, move in ipairs(data) do
        if move.from then
          for _, info in ipairs(move.moveInfo) do
            if info.beforeCard:getMark("@@yingxiangx-inhand") > 0 then
              return player:getMark("yingxiangx-round") == 0 or move.moveReason == fk.ReasonUse
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    --理论上一次move只会有一个moveReason
    if data[1].moveReason == fk.ReasonUse then
      local targets = table.filter(room:getAlivePlayers(), function(p)
        return p == player or table.find(p:getCardIds("h"), function(id)
          return Fk:getCardById(id):getMark("@@yingxiangx-inhand") > 0
        end) ~= nil
      end)
      for _, p in ipairs(targets) do
        if not p.dead then
          p:drawCards(1, yingxiangx.name)
        end
      end
    elseif player:getMark("yingxiangx-round") == 0 then
      room:setPlayerMark(player, "yingxiangx-round", 1)
      local skill = Fk.skills["qingjuex"]
      skill:use(event, target, player, {})
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(yingxiangx.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to and move.to ~= player and move.toArea == Card.PlayerHand then
        local cards = move.to:getCardIds("h")
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              table.contains(cards, info.cardId) then
              room:setCardMark(Fk:getCardById(info.cardId), "@@yingxiangx-inhand", 1)
            end
          end
        elseif move.skillName == "qingjuex" and move.proposer == player then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(cards, info.cardId) then
              room:setCardMark(Fk:getCardById(info.cardId), "@@yingxiangx-inhand", 1)
            end
          end
        end
      end
    end
  end,
})

return yingxiangx
