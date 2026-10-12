local shilus = fk.CreateSkill {
  name = "shilus",
}

Fk:loadTranslationTable {
  ["shilus"] = "嗜戮",
  [":shilus"] = "当一名角色死亡时，你可将其所有武将牌置于你的武将牌旁（称为“戮”），若你为来源，你从剩余武将牌堆额外获得两张“戮”。" ..
      "准备阶段，你可以弃置至多X张牌（X为“戮”数），摸等量的牌。",

  ["@&massacre"] = "戮",
  ["#shilus-cost"] = "发动 嗜戮，弃置至多%arg张牌并摸等量的牌",
  ["#shilus-invoke"] = "发动 嗜戮，获得%dest的武将牌作为“戮”",

  ["$shilus1"] = "以杀立威，谁敢反我？",
  ["$shilus2"] = "将这些乱臣贼子，尽皆诛之！",
}

shilus:addEffect(fk.Deathed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shilus.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, { skill_name = shilus.name, prompt = "#shilus-invoke::" .. target.id }) then
      room:doIndicate(player.id, { target.id })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    if not target.general:startsWith("blank_") and target.general ~= "anjiang" then
      room:findGeneral(target.general)
      table.insert(cards, target.general)
    end
    if target.deputyGeneral and target.deputyGeneral ~= "" and not target.deputyGeneral:startsWith("blank_") and target.deputyGeneral ~= "anjiang" then
      room:findGeneral(target.deputyGeneral)
      table.insert(cards, target.deputyGeneral)
    end
    if data.damage and data.damage.from == player then
      table.insertTableIfNeed(cards, room:getNGenerals(2))
    end
    if #cards > 0 then
      local generals = player:getMark("@&massacre")
      if generals == 0 then generals = {} end
      table.insertTableIfNeed(generals, cards)
      room:setPlayerMark(player, "@&massacre", generals)
    end
  end,
})

shilus:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(shilus.name) then return false end
    return player == target and player.phase == Player.Start and type(player:getMark("@&massacre")) == "table" and
        #player:getMark("@&massacre") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = #player:getMark("@&massacre")
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = x,
      include_equip = true,
      skill_name = shilus.name,
      cancelable = true,
      prompt = "#shilus-cost:::" .. tostring(x),
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, shilus.name, player, player)
    if not player.dead then
      room:drawCards(player, #event:getCostData(self).cards, shilus.name)
    end
  end,
})

local shilus_spec = {
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:returnToGeneralPile(player:getTableMark("@&massacre"), "bottom")
    room:setPlayerMark(player, "@&massacre", 0)
  end,
}

shilus:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@&massacre") ~= 0 and target == player and data.skill.name == shilus.name
  end,
  on_refresh = shilus_spec.on_refresh,
})

shilus:addEffect(fk.BuryVictim, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@&massacre") ~= 0 and target == player
  end,
  on_refresh = shilus_spec.on_refresh,
})

return shilus
