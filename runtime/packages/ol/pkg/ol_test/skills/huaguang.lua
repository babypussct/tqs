
local huaguang = fk.CreateSkill {
  name = "huaguang",
}

Fk:loadTranslationTable {
  ["huaguang"] = "华光",
  [":huaguang"] = "每轮开始时、准备阶段，你可以选择一项：1.将<a href=':colorful_lotus'>【彩莲】</a>置入一个装备栏；"..
  "2.修改<a href=':colorful_lotus'>【彩莲】</a>花色。",

  ["#huaguang-choice"] = "华光：你可以将【彩莲】置入一个装备栏，或修改其花色",
  ["#huaguang-equip"] = "华光：将【彩莲】置入一个装备栏",
  ["#huaguang-suit"] = "华光：修改【彩莲】的花色",

  ["$huaguang1"] = "",
  ["$huaguang2"] = "",
}

local U = require "packages.utility.utility"

local spec = {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "$Equip", "suit" },
      skill_name = huaguang.name,
      prompt = "#huaguang-choice",
      cancelable = true,
    })
    if choice == "Cancel" then return end
    if choice == "$Equip" then
      choice = room:askToChoice(player, {
        choices = { "WeaponSlot", "ArmorSlot", "TreasureSlot" },
        skill_name = huaguang.name,
        prompt = "#huaguang-equip",
        cancelable = true,
      })
    else
      choice = room:askToChoice(player, {
        choices = { "log_spade", "log_heart", "log_club", "log_diamond" },
        skill_name = huaguang.name,
        prompt = "#huaguang-suit",
        cancelable = true,
      })
    end
    event:setCostData(self, { choice = choice })
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local card = Fk:getCardById(player:getMark(huaguang.name))
    if choice:startsWith("log_") then
      card.suit = U.ConvertSuit(choice, "sym", "int")
    else
      room:setCardMark(card, MarkEnum.DestructOutMyEquip, 1)
      if room:getCardArea(card) ~= Card.Void then
        room:moveCardTo(card, Card.Processing, nil, fk.ReasonJustMove, huaguang.name, nil, true, player)
      end
      card.sub_type = Util.convertSubtypeAndEquipSlot(choice)
      if player.dead then return end
      if player:canMoveCardIntoEquip(card, true) then
        room:moveCardIntoEquip(player, card, huaguang.name, true, player)
      end
    end
  end,
}

huaguang:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(huaguang.name)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})
huaguang:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(huaguang.name) and player.phase == Player.Start
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

huaguang:addAcquireEffect(function (self, player, is_start, src)
  local room = player.room
  room:setPlayerMark(player, huaguang.name, room:printCard("colorful_lotus", Card.Heart, 1).id)
end)

return huaguang
