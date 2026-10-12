
local zhengul = fk.CreateSkill({
  name = "zhengul",
})

Fk:loadTranslationTable{
  ["zhengul"] = "贞骨",
  [":zhengul"] = "你受到伤害后，你可以令一名角色随机从牌堆获得两张牌名字数不同的牌并将你的武将牌翻面，然后若你的翻面状态与伤害来源："..
  "不同，本轮〖五绝〗亮出的牌数+1（至多为5）；相同，你本回合无法响应其他角色使用的牌。",

  ["#zhengul-choose"] = "贞骨：令一名角色获得两张牌名字数不同的牌，你翻面",
  ["@@zhengul-turn"] = "不能响应牌",

  ["$zhengul1"] = "",
  ["$zhengul2"] = "",
}

zhengul:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = zhengul.name,
      prompt = "#zhengul-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      local k = tostring(Fk:getCardById(id):getNameLength())
      cards[k] = cards[k] or {}
      table.insert(cards[k], id)
    end
    local keys = {}
    for k, _ in pairs(cards) do
      table.insert(keys, k)
    end
    keys = room:tableRandomPick(keys, 2)
    local ids = {}
    for _, k in ipairs(keys) do
      table.insert(ids, room:tableRandomPick(cards[k]))
    end
    room:moveCardTo(ids, Card.PlayerHand, to, fk.ReasonJustMove, zhengul.name, nil, false, player)
    if player.dead then return end
    player:turnOver()
    if player.dead or data.from == nil or data.from.dead then return end
    if (player.faceup and data.from.faceup) or (not player.faceup and not data.from.faceup) then
      if player:getMark("zhengul-round") < 2 then
        room:addPlayerMark(player, "zhengul-round", 1)
      end
    else
      room:setPlayerMark(player, "@@zhengul-turn", 1)
    end
  end,
})

zhengul:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target ~= player and player:getMark("@@zhengul-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertIfNeed(data.disresponsiveList, player)
  end,
})

return zhengul
