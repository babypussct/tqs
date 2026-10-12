local fendi = fk.CreateSkill {
  name = "ol__fendi",
}

Fk:loadTranslationTable {
  ["ol__fendi"] = "分敌",
  [":ol__fendi"] = "当你使用【杀】指定唯一目标后，你可以展示其至多X张手牌（X为你的体力上限）。若如此做，直到此【杀】结算结束，" ..
      "其只能使用或打出这些牌；当此【杀】对其造成伤害后，你获得其手牌或弃牌堆中的这些牌。",

  ["#ol__fendi-invoke"] = "分敌：展示 %dest 至多%arg张手牌，其只能使用或打出这些牌，若对其造成伤害则你获得这些牌",
  ["@@ol__fendi-inhand"] = "分敌",

  ["$ol__fendi1"] = "善攻者，敌不知其所守，是以围师必阙！",
  ["$ol__fendi2"] = "我若撤围以回城，贼必自出而意散。",
}

fendi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fendi.name) and data.card.trueName == "slash" and
        data:isOnlyTarget(data.to) and not data.to:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
          skill_name = fendi.name,
          prompt = "#ol__fendi-invoke::" .. data.to.id .. ":" .. player.maxHp,
        }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      skill_name = fendi.name,
      target = data.to,
      min = 1,
      max = player.maxHp,
      flag = "h",
    })
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event == nil then return end
    local banner = room:getBanner("ol__fendi_record") or {}
    table.insert(banner, { use_event.id, data.to.id, cards })
    room:setBanner("ol__fendi_record", banner)
    for _, id in ipairs(cards) do
      room:addCardMark(Fk:getCardById(id), "@@ol__fendi-inhand", 1)
    end
    data.to:showCards(cards)
  end,
})

fendi:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    local room = player.room
    return target == player and room:getBanner("ol__fendi_record") and
        table.find(room:getBanner("ol__fendi_record"), function(info)
          return info[1] == room.logic:getCurrentEvent().id
        end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local record = room:getBanner("ol__fendi_record")
    for i = 1, #record do
      if record[i][1] == room.logic:getCurrentEvent().id then
        table.remove(record, i)
        break
      end
    end
    room:setBanner("ol__fendi_record", #record > 0 and record or nil)
  end,
})

fendi:addEffect(fk.Damage, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead and player.room.logic:damageByCardEffect() then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event == nil then return false end
      local record = room:getBanner("ol__fendi_record")
      if record then
        for _, info in ipairs(record) do
          if info[1] == use_event.id and info[2] == data.to.id then
            event:setCostData(self, { tos = { data.to }, cards = info[3] })
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards or {}
    local handCards = data.to:getCardIds("h")
    local toObtain = table.filter(cards, function(id)
      return table.contains(handCards, id) or table.contains(room.discard_pile, id)
    end)
    if #toObtain > 0 then
      room:moveCardTo(toObtain, Player.Hand, player, fk.ReasonPrey, fendi.name, nil, true, player)
    end
  end,
})

fendi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local mark = Fk:currentRoom():getBanner("ol__fendi_record")
    if mark and card then
      local cardList = card:isVirtual() and card.subcards or { card.id }
      return #cardList > 0 and
          table.find(mark, function(info)
            return info[2] == player.id and
                table.find(cardList, function(id)
                  return not table.contains(info[3], id)
                end) ~= nil
          end)
    end
  end,
  prohibit_response = function(self, player, card)
    local mark = Fk:currentRoom():getBanner("ol__fendi_record")
    if mark and card then
      local cardList = card:isVirtual() and card.subcards or { card.id }
      return #cardList > 0 and
          table.find(mark, function(info)
            return info[2] == player.id and
                table.find(cardList, function(id)
                  return not table.contains(info[3], id)
                end) ~= nil
          end)
    end
  end,
})

return fendi
