local yizhu = fk.CreateSkill {
  name = "os__yizhu",
}

Fk:loadTranslationTable {
  ["os__yizhu"] = "遗珠",
  [":os__yizhu"] = "游戏开始时或结束阶段，你摸X张牌，然后选择两张牌作为“遗珠”牌随机洗入牌堆顶前2X张牌中（X为存活角色数且至多为4），"..
  "并展示“遗珠”牌的牌名。" ..
  "其他角色使用“遗珠”牌指定唯一目标后，你可以修改或增加一个目标，然后你将此牌从“遗珠”记录中移除并摸一张牌。",

  ["#os__yizhu-card"] = "遗珠：将两张牌作为“遗珠”洗入牌堆",
  ["@$os__yizhu"] = "遗珠", -- 别人只知道name
  ["#os__yizhu-invoke"] = "遗珠：你可以为 %src 对 %dest 使用的%arg修改或增加一个目标",
  ["os__yizhu_remove_add"] = "修改目标",
  ["os__yizhu_add"] = "增加目标",
  ["#os__yizhu-add"] = "遗珠：为 %src 对 %dest 使用的%arg增加一个目标",
  ["#os__yizhu-remove_add"] = "遗珠：为 %src 对 %dest 使用的%arg修改一个目标",

  ["$os__yizhu1"] = "若见吾女，还望善待之。",
  ["$os__yizhu2"] = "明珠遗于城中，老夫夜不能寐。",
}

local keep_places = {Card.PlayerHand, Card.DrawPile, Card.Processing}

---@param player ServerPlayer
local doYizhu = function(self, event, target, player, data)
  local room = player.room
  local x = math.min(#room.alive_players, 4)
  player:drawCards(x, yizhu.name)
  if player.dead or player:isNude() then return end
  local cards = room:askToCards(player, {
    min_num = math.min(#player:getCardIds("he"), 2),
    max_num = 2,
    include_equip = true,
    skill_name = yizhu.name,
    cancelable = false,
    prompt = "#os__yizhu-card",
  })
  local name_record = player:getTableMark("@$os__yizhu")
  local moves = {}
  for _, id in ipairs(cards) do
    local card = Fk:getCardById(id)
    -- 进入装备区、弃牌堆会失效，另外的一些区域也失效得了，暂未测试
    local record = {tostring(player.id)}
    table.insertTable(record, keep_places)
    room:setCardMark(card, "os__yizhu-inarea", record)
    table.insert(name_record, card.name)
    table.insert(moves, {
      ids = { id },
      from = player,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = yizhu.name,
      drawPilePosition = math.random(math.min(#room.draw_pile, 2 * x)),
    })
  end
  room:setPlayerMark(player, "@$os__yizhu", name_record)
  room:moveCards(table.unpack(moves))
end

yizhu:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yizhu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = doYizhu,
})

yizhu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yizhu.name) and player.phase == Player.Finish
  end,
  on_cost = Util.TrueFunc,
  on_use = doYizhu,
})

yizhu:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(yizhu.name) and
      data:isOnlyTarget(data.to) and data.card.type ~= Card.TypeEquip and
      table.every(Card:getIdList(data.card), function(id)
        local record = Fk:getCardById(id):getMark("os__yizhu-inarea")
        return type(record) == "table" and tonumber(record[1]) == player.id
      end) and data.firstTarget
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"os__yizhu_remove_add", "os__yizhu_add", "Cancel"}
    if data.card.sub_type == Card.SubtypeDelayedTrick then
      table.remove(choices, 2)
    end
    local choice = player.room:askToChoice(player, {
      skill_name = yizhu.name,
      prompt = "#os__yizhu-invoke:" .. target.id .. ":" .. data.to.id .. ":" .. data.card:toLogString(),
      choices = choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local onlyAdd = choice == "os__yizhu_add"
    local oldTarget = data.to
    if not onlyAdd then
      data:cancelTarget(oldTarget)
    end
    -- FIXME: 结算问题，可以杀自己吗？
    local targets = data:getExtraTargets()
    if not onlyAdd then
      table.removeOne(targets, oldTarget)
    end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = "os__yizhu",
      prompt = (onlyAdd and "#os__yizhu-add" or "#os__yizhu-remove_add") .. ":" .. target.id .. ":" .. data.to.id .. ":" .. data.card:toLogString(),
    })
    if #to > 0 then
      data:addTarget(to)
    end
    if player.dead then return end
    local mark = player:getTableMark("@$os__yizhu")
    for _, id in ipairs(Card:getIdList(data.card)) do
      table.removeOne(mark, Fk:getCardById(id).name)
    end
    room:setPlayerMark(player, "@$os__yizhu", #mark > 0 and mark or 0)
    player:drawCards(1, yizhu.name)
  end,
})

yizhu:addEffect(fk.BeforeCardsMove, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return
      player == player.room.players[1] and
      table.find(data, function(move)
        if not table.contains(keep_places, move.toArea) then
          return table.find(move.moveInfo, function(info)
            local record = Fk:getCardById(info.cardId):getMark("os__yizhu-inarea")
            return type(record) == "table" and table.contains(keep_places, info.fromArea)
          end) ~= nil
        end
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if not table.contains(keep_places, move.toArea) then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          local record = card:getMark("os__yizhu-inarea")
          if type(record) == "table" then
            local t = room:getPlayerById(tonumber(record[1]))
            local mark = t:getTableMark("@$os__yizhu")
            table.removeOne(mark, card.name)
            room:setCardMark(card, "os__yizhu-inarea", 0)
            room:setPlayerMark(t, "@$os__yizhu", #mark > 0 and mark or 0)
          end
        end
      end
    end
  end,
})

return yizhu
