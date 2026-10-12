local mingluan = fk.CreateSkill {
  name = "mingluan",
}

Fk:loadTranslationTable{
  ["mingluan"] = "鸣鸾",
  [":mingluan"] = "其他角色的结束阶段，若本回合有角色回复过体力，你可以弃置至少一张牌，然后摸等同于当前回合角色手牌数的牌（最多摸至五张）。",

  ["#mingluan-invoke"] = "鸣鸾：弃置至少一张牌，然后摸 %dest 手牌数的牌，最多摸至五张",

  ["$mingluan1"] = "鸾笺寄情，笙歌动心。",
  ["$mingluan2"] = "鸾鸣轻歌，声声悦耳。",
}

mingluan:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(mingluan.name) and target.phase == Player.Finish and
      #player.room.logic:getEventsOfScope(GameEvent.Recover, 1, Util.TrueFunc, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = room:askToDiscard(
      player,
      {
        min_num = 1,
        max_num = #player:getCardIds("he"),
        include_equip = true,
        skill_name = mingluan.name,
        prompt = "#mingluan-invoke::" .. target.id,
        skip = true,
      }
    )
    if #ids > 0 then
      event:setCostData(self, { cards = ids })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, mingluan.name, player, player)

    if player.dead or target:isKongcheng() or player:getHandcardNum() > 4 then return end
    local n = math.min(5 - player:getHandcardNum(), target:getHandcardNum())
    player:drawCards(n, mingluan.name)
  end,
})

return mingluan
