local yanshi = fk.CreateSkill {
  name = "os__yanshi",
}

Fk:loadTranslationTable{
  ["os__yanshi"] = "言誓",
  [":os__yanshi"] = "游戏开始时，你选择一名其他角色。" ..
    "当你或其每回合首次受到伤害后，你摸三张牌并令伤害来源获得1枚“誓”（至多3枚）。" ..
    "出牌阶段，你可以将一张手牌当单目标伤害牌对一名有“誓”的角色使用，此牌结算结束后，你弃其1枚“誓”。",

  ["@os__oath"] = "誓",
  ["#os__yanshi-choose"] = "言誓：请选择一名其他角色",
  ["#os__yuanshi-vs"] = "发动 言誓，将一张手牌当单目标伤害牌对一名有“誓”的角色使用",
  ["@os__yanshi"] = "言誓",

  ["$os__yanshi1"] = "骨肉至亲，血脉相连。",
  ["$os__yanshi2"] = "挟长持短，昼夜哀酸！",
  ["$os__yanshi3"] = "当以贼血，污此白刃！",
}

yanshi:addEffect("active", {
  audio_index = 3,
  prompt = "#os__yuanshi-vs",
  card_num = 1,
  target_num = 1,
  handly_pile = true,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(true), to_select)
  end,
  interaction_helper = function(self, player, selected_cards)
    local all_names = table.filter(Fk:getAllCardNames("bt"), function(name)
      local card = Fk:cloneCard(name, nil, nil, yanshi.name, selected_cards)
      return card.is_damage_card and not card.multiple_targets
    end)
    local names = player:getViewAsCardNames(yanshi.name, all_names, selected_cards)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  fix_targets = function(self, player, selected_cards, card, extra_data)
    if self.interaction.data == nil then return {} end
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if self.interaction.data == nil or to_select:getMark("@os__oath") == 0 then return false end
    local card = Fk:cloneCard(self.interaction.data, nil, nil, yanshi.name, selected_cards)
    return player:canUseTo(card, to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    room:useVirtualCard(self.interaction.data, effect.cards, player, to, yanshi.name)
    room:removePlayerMark(to, "@os__oath")
  end,
  can_use = function (self, player)
    return not table.every(Fk:currentRoom().alive_players, function (p)
      return p:getMark("@os__oath") == 0
    end)
  end
})

yanshi:addEffect(fk.GameStart, {
  audio_index = 1,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yanshi.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yanshi.name
    local room = player.room
    local targets = room:getOtherPlayers(player, false)
    if #targets == 0 then
      return false
    end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__yanshi-choose",
      skill_name = skillName,
      cancelable = false,
    })[1]
    room:setPlayerMark(player, "@os__yanshi", to)
  end,
})

yanshi:addEffect(fk.Damaged, {
  audio_index = 2,
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(yanshi.name) then return false end
    if target == player or (player:getMark("@os__yanshi") == target and target:isAlive()) then
      local damage_event = player.room.logic:getActualDamageEvents(1, function(e) return e.data.to == target end)[1]
      return damage_event and damage_event.data == data
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, yanshi.name)
    local from = data.from
    if not from or from.dead then return end
    local oath = from:getMark("@os__oath")
    if oath < 3 then
      room:addPlayerMark(from, "@os__oath")
    end
  end,
})

yanshi:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if table.every(room.alive_players, function(p) return
    not p:hasSkill("os__yanshi", true) and not p:hasSkill("os__renchou", true)
  end) then
    table.forEach(room.alive_players, function (p)
      room:setPlayerMark(p, "@os__oath", 0)
    end)
  end
end)


return yanshi
