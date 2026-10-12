
local shenyu = fk.CreateSkill{
  name = "shenyu",
}

Fk:loadTranslationTable{
  ["shenyu"] = "神御",
  [":shenyu"] = "出牌阶段开始时，你可以视为使用一张无距离限制的【杀】，然后将<a href=':blood_blade'>【赤血刃】</a>置入唯一目标角色的装备区"..
  "（替换原装备）。每个结束阶段，若你本回合造成过伤害或使用过至少两张伤害牌，且【赤血刃】在其他角色装备区，你可以将其移动至你的装备区（替换原装备），"..
  "获得其和其与你之间角色各随机一张牌。",

  ["#shenyu-slash"] = "神御：视为使用一张无距离限制的【杀】，将【赤血刃】置入目标装备区",
  ["#shenyu-invoke"] = "神御：是否收回【赤血刃】？",
  ["shenyu_left"] = "左侧",
  ["shenyu_right"] = "右侧",

  ["$shenyu1"] = "神兵应召，万里归鞘！",
  ["$shenyu2"] = "赠你神兵，你可受得住？",
}

shenyu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shenyu.name) and player.phase == Player.Play and
      player:canUse(Fk:cloneCard("slash"), { bypass_distances = true, bypass_times = true })
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = shenyu.name,
      prompt = "#shenyu-slash",
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(self).extra_data
    room:useCard(use)
    if use.tos[1] and not use.tos[1].dead and player:getMark(shenyu.name) ~= 0 then
      local id = player:getMark(shenyu.name)
      if use.tos[1]:canMoveCardIntoEquip(id, true) then
        room:setCardMark(Fk:getCardById(id), MarkEnum.DestructIntoDiscard, 1)
        room:moveCardIntoEquip(use.tos[1], id, shenyu.name, true, player)
      end
    end
  end,
})

shenyu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shenyu.name) and target.phase == Player.Finish and
      player:getMark(shenyu.name) ~= 0 and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return table.contains(p:getCardIds("e"), player:getMark(shenyu.name))
      end) and
      player:canMoveCardIntoEquip(player:getMark(shenyu.name), true) then
      if #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) > 0 then
        return true
      end
      if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function (e)
        return e.data.from == player and e.data.card.is_damage_card
      end, Player.HistoryTurn) > 1 then
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:getCardOwner(player:getMark(shenyu.name))  ---@cast to ServerPlayer
    local left, right = 0, 0
    local temp = to
    while temp ~= player do
      left = left + 1
      temp = temp.next
    end
    right = #room.alive_players - left
    local choice = "both"
    if left > right then
      choice = "right"
    elseif left < right then
      choice = "left"
    end
    choice = room:askToChoice(player, {
      choices = choice == "both" and { "shenyu_left", "shenyu_right" } or { "shenyu_"..choice },
      all_choices = { "shenyu_left", "shenyu_right" },
      skill_name = shenyu.name,
      prompt = "#shenyu-invoke",
      cancelable = true
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getCardOwner(player:getMark(shenyu.name))  ---@cast to ServerPlayer
    local choice = event:getCostData(self).choice
    local targets, temp = {}, to
    while temp ~= player do
      table.insert(targets, temp)
      if choice == "shenyu_left" then
        temp = temp:getNextAlive()
      else
        temp = temp:getLastAlive()
      end
    end
    room:moveCardIntoEquip(player, player:getMark(shenyu.name), shenyu.name, true, player)
    for _, p in ipairs(targets) do
      if player.dead then return end
      if not p:isNude() then
        room:moveCardTo(room:tableRandomPick(p:getCardIds("he")), Card.PlayerHand, player, fk.ReasonPrey, shenyu.name, nil, false, player)
      end
    end
  end,
})

shenyu:addAcquireEffect(function (self, player, is_start, src)
  local room = player.room
  local id = room:printCard("blood_blade", Card.Heart, 13).id
  room:setPlayerMark(player, shenyu.name, id)
end)

return shenyu
