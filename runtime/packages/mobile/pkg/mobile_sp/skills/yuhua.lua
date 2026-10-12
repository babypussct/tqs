local yuhua = fk.CreateSkill{
  name = "yuhua",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yuhua"] = "羽化",
  [":yuhua"] = "锁定技，你的非基本牌不计入手牌上限；结束阶段，若你手牌数大于体力值，你观看牌堆顶X张牌（X为你手牌类别数），"..
  "将其中任意数量的牌置于牌堆顶，其余的牌置于牌堆底。",

  ["$yuhua1"] = "此乃仙人之物，不可轻弃。",
  ["$yuhua2"] = "凤羽飞烟，乘化仙尘。",
}

yuhua:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuhua.name) and player.phase == Player.Finish and
      player:getHandcardNum() > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    room:askToGuanxing(player, { cards = room:getNCards(#types) })
  end,
})

yuhua:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(yuhua.name) and card.type ~= Card.TypeBasic
  end,
})

return yuhua
