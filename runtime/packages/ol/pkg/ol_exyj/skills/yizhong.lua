
local yizhong = fk.CreateSkill {
  name = "ol_ex__yizhong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_ex__yizhong"] = "毅重",
  [":ol_ex__yizhong"] = "锁定技，体力值大于等于你的角色的黑色【杀】对你无效；手牌数小于等于你的角色无法响应你的黑色【杀】。",

  ["$ol_ex__yizhong1"] = "在乱能整，讨暴克坚，此毅重也。",
  ["$ol_ex__yizhong2"] = "质忠性一，守执节义，自当无坚不陷。",
}

yizhong:addEffect(fk.PreCardEffect, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yizhong.name) and data.card.trueName == "slash" and data.to == player and
      data.from.hp >= player.hp and data.card.color == Card.Black
  end,
  on_use = function (self, event, target, player, data)
    player.room:broadcastPlaySound("./packages/standard_cards/audio/card/nioh_shield")
    player.room:setEmotion(player, "./packages/standard_cards/image/anim/nioh_shield")
    data.nullified = true
  end,
})

yizhong:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(yizhong.name) and
      data.card.color == Card.Black and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    local x = player:getHandcardNum()
    local targets = table.filter(player.room.alive_players, function(p)
      return p:getHandcardNum() <= x
    end)
    event:setCostData(self, { tos = targets, no_indicate = true })
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(event:getCostData(self).tos) do
      table.insertIfNeed(data.disresponsiveList, p)
    end
  end,
})

return yizhong
