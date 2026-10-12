local osJuxiangOther = fk.CreateSkill {
  name = "os__juxiang_other&"
}

Fk:loadTranslationTable{
  ["os__juxiang_other&"] = "踞襄",
  [":os__juxiang_other&"] = "出牌阶段限一次，你可以选择装备区的一张牌置于张绣的装备区中，" ..
  "若其对应的装备栏已被废除，则改为交给其此装备牌，然后恢复其对应装备栏。",
}

osJuxiangOther:addEffect("active", {
  anim_type = "support",
  can_use = function(self, player)
    if player:usedSkillTimes(osJuxiangOther.name, Player.HistoryPhase) < 1 and player.kingdom == "qun" then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p:hasSkill("os__juxiang") and p ~= player
      end)
    end
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Equip then
      local subtype = Fk:getCardById(to_select).sub_type
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if
          p:hasSkill("os__juxiang") and
          p ~= player and
          (p:hasEmptyEquipSlot(subtype) or #p:getAvailableEquipSlots(subtype) == 0)
        then
          return true
        end
      end
    end
    return false
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local cards = effect.cards
    if #cards ~= 1 then
      return
    end

    local player = effect.from
    local subtype = Fk:getCardById(cards[1]).sub_type
    local targets = table.filter(room.alive_players, function(p)
      return
        p:hasSkill("os__juxiang") and
        p ~= player and
        (p:hasEmptyEquipSlot(subtype) or #p:getAvailableEquipSlots(subtype) == 0)
    end)
    local target
    if #targets == 1 then
      target = targets[1]
    else
      target = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        skill_name = "os__juxiang",
        cancelable = false,
      })[1]
    end
    if not target then
      return false
    end

    room:notifySkillInvoked(player, "os__juxiang", "support")
    player:broadcastSkillInvoke("os__juxiang")
    room:doIndicate(player, { target })
    if #target:getAvailableEquipSlots(subtype) > 0 then
      room:moveCardTo(cards, Card.PlayerEquip, target, fk.ReasonPut, "os__juxiang", nil, true, player)
    else
      room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, "os__juxiang", nil, true, player)
      room:resumePlayerArea(target, Util.convertSubtypeAndEquipSlot(subtype))
    end
  end,
})

return osJuxiangOther
