local yuanyu = fk.CreateSkill {
  name = "os__yuanyu",
  derived_piles = "@[os__yuanyu_resent]",
}
Fk:loadTranslationTable {
  ["os__yuanyu"] = "怨语",
  [":os__yuanyu"] = "出牌阶段限一次，你可以摸两张牌并将一张手牌置于武将牌上，称为“怨”，然后选择一名其他角色：你与其弃牌阶段开始时，" ..
      "或当该角色造成1点伤害后，其也须放置一张“怨”直到你触发〖夕颜〗。",

  ["#os__yuanyu"] = "怨语：摸两张牌，然后将一张手牌置为“怨”",
  ["#os__yuanyu-choose"] = "怨语：选择一张手牌置为“怨”，并指定一名其他角色",
  ["@@os__yuanyu"] = "怨语",
  ["#os__yuanyu-put"] = "怨语：请将一张手牌置为 %src 的“怨”",
  ["@[os__yuanyu_resent]"] = "怨",
  ["@[os__yuanyu]"] = "怨 牌堆",

  ["$os__yuanyu1"] = "生为君眷，死为君伥，黄泉不改，九幽不妄。",
  ["$os__yuanyu2"] = "纵食珍馐、着金玉、居雕栋，亦不及得一人。",
}

local U = require "packages.utility.utility"

Fk:addQmlMark {
  name = yuanyu.name,
  how_to_show = function(name, value, p)
    local suits = {}
    for _, id in ipairs(p:getPile("@[os__yuanyu_resent]")) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    return table.concat(table.map(suits, function(suit)
      return U.ConvertSuit(suit, "int", "sym")
    end), " ")
  end,
  qml_path = "packages/utility/qml/ViewPile" --好像有
}

yuanyu:addEffect("active", {
  anim_type = "control",
  prompt = "#os__yuanyu",
  max_phase_use_time = 1,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    player:drawCards(2, yuanyu.name)
    if player.dead or player:isKongcheng() or #room:getOtherPlayers(player, false) == 0 then return end
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|.|hand",
      prompt = "#os__yuanyu-choose",
      skill_name = yuanyu.name,
      cancelable = false,
    })
    if #to > 0 and card then
      local targetRecorded = player:getTableMark("os__yuanyu_targets")
      if not table.contains(targetRecorded, to[1].id) then
        table.insert(targetRecorded, to[1].id)
        room:setPlayerMark(player, "os__yuanyu_targets", targetRecorded)
        room:addPlayerMark(to[1], "@@os__yuanyu")
        if player:getMark("@[os__yuanyu]") == 0 then
          room:setPlayerMark(player, "@[os__yuanyu]", 1)
        end
      end
      player:addToPile("@[os__yuanyu_resent]", card, true, yuanyu.name)
    end
  end,
})

yuanyu:addEffect(fk.Damage, {
  anim_type = "control",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuanyu.name) and target and not target:isKongcheng() and
        table.contains(player:getTableMark("os__yuanyu_targets"), target.id)
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { target } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      prompt = "#os__yuanyu-put:" .. player.id,
      skill_name = yuanyu.name,
      cancelable = false,
    })
    player:addToPile("@[os__yuanyu_resent]", card, true, yuanyu.name)
  end,
})

yuanyu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuanyu.name) and target.phase == Player.Discard then
      if target == player then
        return table.find(player:getTableMark("os__yuanyu_targets"), function(id)
          local p = player.room:getPlayerById(id)
          return not p:isKongcheng() and not p.dead
        end)
      else
        return not target:isKongcheng() and table.contains(player:getTableMark("os__yuanyu_targets"), target.id)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    if target == player then
      tos = table.filter(room.alive_players, function(p)
        return table.contains(player:getTableMark("os__yuanyu_targets"), p.id)
      end)
    else
      tos = { target }
    end
    room:sortByAction(tos)
    event:setCostData(self, { tos = tos })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos ---@type ServerPlayer[]
    for _, to in ipairs(tos) do
      if player.dead then break end
      local targetRecorded = player:getTableMark("os__yuanyu_targets")
      if targetRecorded == 0 then break end
      if not to.dead and not to:isKongcheng() and table.contains(targetRecorded, to.id) then
        local card = room:askToCards(to, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          prompt = "#os__yuanyu-put:" .. player.id,
          skill_name = yuanyu.name,
          cancelable = false,
        })
        player:addToPile("@[os__yuanyu_resent]", card, true, yuanyu.name)
      end
    end
  end,
})

yuanyu:addLoseEffect(function(self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getTableMark("os__yuanyu_targets")) do
    room:removePlayerMark(room:getPlayerById(id), "@@os__yuanyu")
  end
  room:setPlayerMark(player, "os__yuanyu_targets", 0)
end)

return yuanyu
