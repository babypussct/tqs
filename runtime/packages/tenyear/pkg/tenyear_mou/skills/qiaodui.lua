local qiaodui = fk.CreateSkill {
  name = "qiaodui",
}

Fk:loadTranslationTable {
  ["qiaodui"] = "巧对",
  [":qiaodui"] = "每回合限一次，当你使用牌指定其他角色为目标后，你可以交给一名其他角色至多两张牌，令此牌额外结算一次；" ..
      "当你成为其他角色使用牌的目标后，你可以交给一名其他角色至多两张牌，令此牌无效。",

  ["#qiaodui1-invoke"] = "巧对：交给一名角色至多两张牌，令你使用的%arg额外结算一次",
  ["#qiaodui2-invoke"] = "巧对：交给一名角色至多两张牌，令 %dest 使用的%arg无效",

  ["$qiaodui1"] = "败军之将，免死为幸，不敢效陈、韩。",
  ["$qiaodui2"] = "水月虽异，皆照忠臣肝胆。",
}

qiaodui:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiaodui.name) and data.firstTarget and
        (data.card.type ~= Card.TypeEquip) and
        player:usedSkillTimes(qiaodui.name, Player.HistoryTurn) == 0 and
        table.find(data.use.tos, function(p)
          return p ~= player
        end) and
        not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 2,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = qiaodui.name,
      prompt = "#qiaodui1-invoke:::" .. data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 and #cards > 0 then
      event:setCostData(self, { tos = to, cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards or {}
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, qiaodui.name, nil, false, player)
    data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
  end,
})

qiaodui:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiaodui.name) and
        data.card.type ~= Card.TypeEquip and
        player:usedSkillTimes(qiaodui.name, Player.HistoryTurn) == 0 and
        data.from ~= player and
        not player:isNude() and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 2,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = qiaodui.name,
      prompt = "#qiaodui2-invoke::" .. data.from.id .. ":" .. data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 and #cards > 0 then
      event:setCostData(self, { tos = to, cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards or {}
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, qiaodui.name, nil, false, player)
    data.use.nullifiedTargets = table.simpleClone(room.players)
  end,
})

return qiaodui
