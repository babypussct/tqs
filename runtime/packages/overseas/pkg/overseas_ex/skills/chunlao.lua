local chunlao = fk.CreateSkill{
  name = "os_ex__chunlao",
}

Fk:loadTranslationTable{
  ["os_ex__chunlao"] = "醇醪",
  [":os_ex__chunlao"] = "准备阶段，若场上没有“醇”，你可以选择一名角色，将其区域内的一张牌置于其武将牌上，称为“醇”。" ..
  "有“醇”的角色使用【杀】时，其可以交给你一张牌，令此【杀】伤害+1；"..
  "其进入濒死状态时，你可以移去其“醇”并摸一张牌，然后其回复1点体力。",

  ["os__dense_alcohol"] = "醇",
  ["#os_ex__chunlao-ask"] = "醇醪：你可以将一名角色区域内的一张牌置为其“醇”",
  ["#os_ex__chunlao-give"] = "醇醪：你可以交给 %src 一张牌，令此【杀】伤害+1",
  ["#os_ex__chunlao-invoke"] = "醇醪：你可以移去 %dest 的“醇”并摸一张牌，令其回复1点体力",

  ["$os_ex__chunlao1"] = "唉，帐中不可无酒啊！",
  ["$os_ex__chunlao2"] = "无碍（wài），且饮一杯！",
}

chunlao:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(chunlao.name) and
      player.phase == Player.Start and
      table.every(player.room.alive_players, function(p)
        return #p:getPile("os__dense_alcohol") == 0 and not p:isAllNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return #p:getPile("os__dense_alcohol") == 0 and not p:isAllNude()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os_ex__chunlao-ask",
      skill_name = chunlao.name,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cid = room:askToChooseCard(player, {
      target = to,
      flag = "hej",
      skill_name = chunlao.name,
    })
    to:addToPile("os__dense_alcohol", cid, true, chunlao.name)
  end,
})

chunlao:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chunlao.name) and
      target and #target:getPile("os__dense_alcohol") > 0 and
      data.card.trueName == "slash" and not target:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = chunlao.name,
      cancelable = true,
      prompt = "#os_ex__chunlao-give:" .. player.id,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = event:getCostData(self).cards or {}
    if not table.contains(player:getCardIds("h"), card[1]) then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, chunlao.name, nil, false, target)
    end
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

chunlao:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chunlao.name) and
      #target:getPile("os__dense_alcohol") > 0 and target.dying
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chunlao.name,
      prompt = "#os_ex__chunlao-invoke::"..target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = chunlao.name
    local room = player.room
    room:moveCards{
      ids = target:getPile("os__dense_alcohol"),
      from = target,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      proposer = player,
      skillName = skillName,
    }
    if player:isAlive() then
      player:drawCards(1, skillName)
    end
    if target:isAlive() then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = skillName,
      }
    end
  end,
})

return chunlao
