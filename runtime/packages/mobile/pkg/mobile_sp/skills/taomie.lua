local taomie = fk.CreateSkill {
  name = "taomie",
}

Fk:loadTranslationTable{
  ["taomie"] = "讨灭",
  [":taomie"] = "当你受到伤害后或当你造成伤害后，你可以令伤害来源或受伤角色获得“讨灭”标记（如场上已有标记则转移给该角色），"..
  "你和拥有“讨灭”标记的角色互相视为在对方的攻击范围内；当你对有“讨灭”标记的角色造成伤害时，你选择一项：1.令此伤害+1；"..
  "2.你获得其区域里的一张牌并可将此牌交给另一名角色；背水：弃置其“讨灭”标记，本次伤害不令其获得“讨灭”标记。",
  ["#taomie-invoke"] = "讨灭：是否令 %dest 获得“讨灭”标记？",
  ["@@taomie"] = "讨灭",
  ["taomie_damage"] = "此伤害+1",
  ["taomie_prey"] = "获得其区域内一张牌，且可以交给另一名角色",
  ["taomie_beishui"] = "背水：弃置其“讨灭”标记，且本次伤害不令其获得标记",
  ["#taomie-choose"] = "讨灭：你可以将此%arg交给另一名角色",

  ["$taomie1"] = "犯我辽东疆界，必遭后报！",
  ["$taomie2"] = "韩濊之乱，再无可生之机！",
  ["$taomie3"] = "颅且远行万里，要席何用？",
}

taomie:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(taomie.name) and
      data.to:isAlive() and
      data.to:getMark("@@taomie") == 0 and
      not (data.extra_data and data.extra_data.taomie)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = taomie.name, prompt = "#taomie-invoke::" .. data.to.id })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@@taomie", 0)
    end
    room:doIndicate(player, { data.to })
    room:setPlayerMark(data.to, "@@taomie", 1)
  end,
})

taomie:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(taomie.name) and
      data.from and
      data.from:isAlive() and
      data.from:getMark("@@taomie") == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = taomie.name, prompt = "#taomie-invoke::" .. data.from.id })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@@taomie", 0)
    end
    room:doIndicate(player, { data.from })
    room:setPlayerMark(data.from, "@@taomie", 1)
  end,
})

taomie:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(taomie.name) and
      data.to:getMark("@@taomie") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = taomie.name
    local room = player.room
    local all_choices = { "taomie_damage", "taomie_prey", "taomie_beishui" }
    local choices = table.clone(all_choices)
    if data.to:isNude() then
      choices = { "taomie_damage" }
    end
    local choice = room:askToChoice(player, { choices = choices, skill_name = skillName, all_choices = all_choices })
    if choice ~= "taomie_prey" then
      data:changeDamage(1)
    end
    if choice ~= "taomie_damage" then
      if choice == "taomie_beishui" then
        room:setPlayerMark(data.to, "@@taomie", 0)
        data.extra_data = data.extra_data or {}
        data.extra_data.taomie = true
      end
      if data.to:isNude() then return end
      room:doIndicate(player, { data.to })
      local id = room:askToChooseCard(player, { target = data.to, flag = "hej", skill_name = skillName })

      room:obtainCard(player, id, false, fk.ReasonPrey, player, skillName)
      if not player:isAlive() then return end
      local targets = room:getOtherPlayers(data.to)
      table.removeOne(targets, player)
      if #targets == 0 or room:getCardOwner(id) ~= player or room:getCardArea(id) ~= Card.PlayerHand then return end

      local to = room:askToChoosePlayers(
        player,
        {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#taomie-choose:::" .. Fk:getCardById(id):toLogString(),
          skill_name = skillName,
        }
      )
      if #to > 0 then
        room:obtainCard(to[1], id, false, fk.ReasonGive, player, skillName)
      end
    end
  end,
})

taomie:addEffect("atkrange", {
  within_func = function (self, from, to)
    ---@type string
    local skillName = taomie.name
    if from:hasSkill(skillName) then
      return to:getMark("@@taomie") > 0
    end
    if to:hasSkill(skillName) then
      return from:getMark("@@taomie") > 0
    end
  end,
})

return taomie
