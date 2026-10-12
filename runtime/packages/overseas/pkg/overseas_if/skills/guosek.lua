local guosek = fk.CreateSkill {
  name = "os__guosek",
}

Fk:loadTranslationTable{
  ["os__guosek"] = "帼色",
  [":os__guosek"] = "当一名角色受伤状态变化后，若其判定区里没有【乐不思蜀】，你可以将你或其一张牌当作【乐不思蜀】置入其判定区，" ..
    "然后你摸两张牌。每轮限一次，有【乐不思蜀】判定生效后，你可令此【乐不思蜀】改为跳过弃牌阶段。",

  ["#os__guosek"] = "是否发动“帼色”，将你或 %dest 的一张牌当作【乐不思蜀】置入其判定区？",
  ["#os__guosek-judge"] = "是否发动“帼色”，令 %dest 此【乐不思蜀】改为跳过弃牌阶段？",

  ["$os__guosek1"] = "夫君今统一方，更应慎之再慎。",
  ["$os__guosek2"] = "如今江南初定，何不与民生息？",
}

-- 记录受伤情况
---@type TrigSkelSpec<DamageTrigFunc|HpLostTrigFunc|RecoverTrigFunc|MaxHpChangedTrigFunc>
local guosek_record = {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(guosek.name)
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.woundedBefore = target:isWounded()
  end
}

-- 受伤后、失去体力后、回复体力后、体力上限变化后执行
---@type TrigSkelSpec<DamageTrigFunc|HpLostTrigFunc|RecoverTrigFunc|MaxHpChangedTrigFunc>
local guosek_act = {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if not (player:hasSkill(guosek.name) and (data.extra_data or {}).woundedBefore ~= target:isWounded() and not (player:isNude() and target:isNude())) then return end
    local card = Fk:cloneCard("indulgence", nil, nil, guosek.name)
    return not target:isProhibitedTarget(card)
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = guosek.name,
      prompt = "#os__guosek::" .. target.id,
      data = data,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card_data = {}
    local visible_data = {}
    local targets = { target }
    if target ~= player then
      table.insert(targets, player)
    end
    for _, t in ipairs(targets) do
      local cards = t:getCardIds("h")
      if #cards > 0 then
        table.insert(card_data, { t:toLogString() .. Fk:translate("$Hand"), cards })
        for _, id in ipairs(cards) do
          if not player:cardVisible(id) then
            visible_data[tostring(id)] = false
          end
        end
      end
      if #t.player_cards[Player.Equip] > 0 then
        table.insert(card_data, { t:toLogString() .. Fk:translate("$Equip"), t:getCardIds(Player.Equip) })
      end
    end
    local card = room:askToChooseCard(player, {
      target = target,
      flag = { card_data = card_data, visible_data = visible_data },
      skill_name = guosek.name,
      prompt = "#os__guosek::" .. target.id,
    })
    local indulgence = Fk:cloneCard("indulgence", nil, nil, guosek.name, {card})
    room:moveCards{
      from = room:getCardOwner(card),
      fromArea = room:getCardArea(card),
      to = target,
      toArea = Player.Judge,
      ids = {card},
      moveReason = fk.ReasonJustMove,
      skillName = guosek.name,
      virtualEquip = indulgence,
    }
    if player:isAlive() then
      player:drawCards(2, guosek.name)
    end
  end,
}

-- 尚未验证线上结算
guosek:addEffect(fk.DamageInflicted, guosek_record)
guosek:addEffect(fk.PreHpLost, guosek_record)
guosek:addEffect(fk.PreHpRecover, guosek_record)
guosek:addEffect(fk.BeforeMaxHpChanged, guosek_record)

guosek:addEffect(fk.Damaged, guosek_act)
guosek:addEffect(fk.HpLost, guosek_act)
guosek:addEffect(fk.HpRecover, guosek_act)
guosek:addEffect(fk.MaxHpChanged, guosek_act)

-- 尚未验证线上结算
guosek:addEffect(fk.FinishJudge, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(guosek.name) and data.reason == "indulgence" and
      player:usedEffectTimes(self.name, Player.HistoryRound) == 0 and data:matchPattern()
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = self.name,
      prompt = "#os__guosek-judge::" .. target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    target:skip(Player.Discard)
    if data.results then
      table.removeOne(data.results, "good")
    end
    local effect_event = room.logic:getCurrentEvent():findParent(GameEvent.CardEffect, true)
    if effect_event then
      room.logic:getCurrentEvent():findParent(GameEvent.Judge, true):addExitFunc(function ()
        room:moveCards{
        ids = room:getSubcardsByRule(effect_event.data.card, { Card.Processing }),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonUse,
      }
        effect_event:shutdown()
      end)
    end
  end
})

return guosek
