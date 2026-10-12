local congfeng = fk.CreateSkill {
  name = "ty__congfeng",
}

Fk:loadTranslationTable{
  ["ty__congfeng"] = "从风",
  [":ty__congfeng"] = "你/其他角色不因此技能获得其他角色/你的牌后，可以再随机获得一张。",

  ["#ty__congfeng-invoke"] = "从风：是否再获得 %dest 一张牌？",

  ["$ty__congfeng1"] = "生义孰轻孰重，马某还拎的清！",
  ["$ty__congfeng2"] = "是他刘禅无德，非我等无义！",
}

congfeng:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(congfeng.name) then
      for _, move in ipairs(data) do
        if move.from and (move.from == player or move.to == player) and
          move.toArea == Player.Hand and move.skillName ~= congfeng.name and
          not move.from.dead and not move.to.dead and not move.from:isNude() then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function (self, event, target, player, data)
    local dat = {}
    for _, move in ipairs(data) do
      if move.from and (move.from == player or move.to == player) and
        move.toArea == Player.Hand and move.skillName ~= congfeng.name then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insert(dat, {move.from, move.to})
            break
          end
        end
      end
    end
    for _, d in ipairs(dat) do
      if not player:hasSkill(congfeng.name) then return end
      if not d[1].dead and not d[2].dead and not d[1]:isNude() then
        event:setCostData(self, { src = d[2], tos = {d[1]} })
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local src = event:getCostData(self).src
    local to = event:getCostData(self).tos[1]
    return player.room:askToSkillInvoke(src, {
      skill_name = congfeng.name,
      prompt = "#ty__congfeng-invoke::"..to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local src = event:getCostData(self).src
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(room:tableRandomPick(to:getCardIds("he")), Card.PlayerHand, src, fk.ReasonPrey, congfeng.name, nil, false, src)
  end,
})

return congfeng
