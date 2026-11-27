
local shilus = fk.CreateSkill {
  name = "nos_heg__shilus",
}

Fk:loadTranslationTable {
  ["nos_heg__shilus"] = "嗜戮",
  [":nos_heg__shilus"] = "当一名角色死亡时，你可以将其武将牌置于你的武将牌旁，称为“戮”，若杀死其的角色是你，你从剩余武将牌堆额外获得两张“戮”。" ..
  "准备阶段，你可以弃置至多X张牌（X为“戮”数），摸等量的牌。",

  ["@&massacre"] = "戮",
  ["#nos_heg__shilus-discard"] = "嗜戮：你可以弃置至多%arg张牌，摸等量的牌",
  ["#nos_heg__shilus-invoke"] = "嗜戮：是否获得 %dest 的武将牌作为“戮”？",

  ["$nos_heg__shilus1"] = "以杀立威，谁敢反我？",
  ["$nos_heg__shilus2"] = "将这些乱臣贼子，尽皆诛之！",
}

local H = require "packages.hegemony.util"

shilus:addEffect(fk.Death, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shilus.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = shilus.name,
      prompt = "#nos_heg__shilus-invoke::" .. target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local general, deputyGeneral = H.getActualGeneral(target), H.getActualGeneral(target, true)
    if general and general ~= "" and not general:startsWith("blank_") then
      room:findGeneral(general)
      table.insert(cards, general)
    end
    if deputyGeneral and deputyGeneral ~= "" and not deputyGeneral:startsWith("blank_") then
      room:findGeneral(deputyGeneral)
      table.insert(cards, deputyGeneral)
    end
    if data.killer == player then
      table.insertTableIfNeed(cards, room:getNGenerals(2))
    end
    if #cards > 0 then
      local generals = player:getTableMark("@&massacre")
      table.insertTableIfNeed(generals, cards)
      room:setPlayerMark(player, "@&massacre", generals)
    end
  end,
})

shilus:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shilus.name) and player.phase == Player.Start and
      #player:getTableMark("@&massacre") > 0
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
      prompt = "#nos_heg__shilus-discard:::" .. x,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards or {}
    room:throwCard(cards, shilus.name, player, player)
    if not player.dead then
      room:drawCards(player, #cards, shilus.name)
    end
  end,
})

shilus:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:returnToGeneralPile(player:getTableMark("@&massacre"))
  room:setPlayerMark(player, "@&massacre", 0)
end)

return shilus
