local wooden_ox_skill = fk.CreateSkill{
  name = "wooden_ox_skill",
  attached_equip = "wooden_ox",
}
wooden_ox_skill:addEffect("active", {
  prompt = "#wooden_ox-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(wooden_ox_skill.name, Player.HistoryPhase) == 0 and #player:getPile("$sa_carriage") < 5
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player.player_cards[Player.Hand], to_select)
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = effect.from
    player:addToPile("$sa_carriage", effect.cards[1], false, wooden_ox_skill.name)
    if player.dead then return end
    local ox = table.find(player:getCardIds("e"), function (id) return Fk:getCardById(id).name == "wooden_ox" end)
    if ox then
      local targets = table.filter(room.alive_players, function(p)
        return p ~= player and p:hasEmptyEquipSlot(Card.SubtypeTreasure) end)
      if #targets > 0 then
        local tos = room:askToChoosePlayers(player, {cancelable = true, max_num = 1, min_num = 1, skill_name = wooden_ox_skill.name, targets = targets, prompt = "#wooden_ox-move" })
        if #tos > 0 then
          room:moveCardTo(ox, Card.PlayerEquip, tos[1], fk.ReasonPut, wooden_ox_skill.name, nil, true, player, nil)
        end
      end
    end
  end,
})
wooden_ox_skill:addEffect(fk.AfterCardsMove, {
  -- name = "#wooden_ox_trigger",
  mute = true,
  priority = 5,
  can_trigger = function(self, event, target, player, data)
    if player:getPile("$sa_carriage") == 0 then return false end
    for _, move in ipairs(data) do
      for _, info in ipairs(move.moveInfo) do
        if Fk:getCardById(info.cardId).name == "wooden_ox" then
          --多个木马同时移动的情况取其中之一即可，不再做冗余判断
          if info.fromArea == Card.Processing then
            local room = player.room
            --注意到一次交换事件的过程中的两次移动事件都是在一个parent事件里进行的，因此查询到parent事件为止即可
            local move_event = room.logic:getCurrentEvent():findParent(GameEvent.MoveCards, true) ---@class GameEvent.MoveCards
            if not move_event then return end
            local parent_event = move_event.parent
            local move_events = room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
              if e.id >= move_event.id or e.parent ~= parent_event then return false end
              for _, last_move in ipairs(e.data) do
                if last_move.moveReason == fk.ReasonExchange and last_move.toArea == Card.Processing then
                  return true
                end
              end
            end, parent_event.id)
            if #move_events > 0 then
              for _, last_move in ipairs(move_events[1].data) do
                if last_move.moveReason == fk.ReasonExchange then
                  for _, last_info in ipairs(last_move.moveInfo) do
                    if Fk:getCardById(last_info.cardId).name == "wooden_ox" then
                      if last_move.from == player and last_info.fromArea == Card.PlayerEquip then
                        if move.toArea == Card.PlayerEquip then
                          if move.to ~= player then
                            event:setCostData(self, {extra_data = move.to})
                            return true
                          end
                        else
                          event:setCostData(self, nil)
                          return true
                        end
                      end
                    end
                  end
                end
              end
            end
          elseif move.moveReason == fk.ReasonExchange then
            if move.from == player and info.fromArea == Card.PlayerEquip and move.toArea ~= Card.Processing then
              --适用于被修改了移动区域的情况，如销毁，虽然说原则上移至处理区是不应销毁的
              event:setCostData(self, nil)
              return true
            end
          elseif move.from == player and info.fromArea == Card.PlayerEquip then
            if move.toArea == Card.PlayerEquip then
              if move.to ~= player then
                event:setCostData(self, {extra_data = move.to})
                return true
              end
            else
              event:setCostData(self, nil)
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, _, player, data)
    local room = player.room
    local cards = player:getPile("$sa_carriage")
    if event:getCostData(self) ~= nil then
      event:getCostData(self).extra_data:addToPile("$sa_carriage", cards, false, wooden_ox_skill.name)
    else
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, wooden_ox_skill.name, nil, true)
    end
  end,
})
wooden_ox_skill:addEffect("filter", {
  handly_cards = function (self, player)
    if player:hasSkill("wooden_ox_skill") then
      return player:getPile("$sa_carriage")
    end
  end,
})

Fk:loadTranslationTable{
  ["wooden_ox"] = "木牛流马",
  [":wooden_ox"] = "装备牌·宝物<br/><b>宝物技能</b>：<br/>" ..
    "1. 出牌阶段限一次，你可将一张手牌置入仓廪（称为“辎”，“辎”数至多为5），然后你可将装备区里的【木牛流马】置入一名其他角色的装备区。<br/>" ..
    "2. 你可如手牌般使用或打出“辎”。<br/>" ..
    "3. 当你并非因交换而失去装备区里的【木牛流马】前，若目标区域不为其他角色的装备区，则当你失去此牌后，你将所有“辎”置入弃牌堆。<br/>"..
    "◆“辎”对你可见。<br/>◆此延时类效果于你的死亡流程中能被执行。",
  ["wooden_ox_skill"] = "木牛",
  [":wooden_ox_skill"] = "出牌阶段限一次，你可将一张手牌置入仓廪（称为“辎”，“辎”数至多为5），然后你可将装备区里的【木牛流马】置入一名其他角色的装备区。你可如手牌般使用或打出“辎”。",
  ["#wooden_ox-move"] = "你可以将【木牛流马】移动至一名其他角色的装备区",
  ["$sa_carriage"] = "辎",
  ["#wooden_ox_trigger"] = "木牛流马",
  ["#wooden_ox-prompt"] = "你可以将一张手牌扣置于木牛流马下",
}

return wooden_ox_skill
