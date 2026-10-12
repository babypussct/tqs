local fenyin = fk.CreateSkill {
  name = "fenyin",
}

Fk:loadTranslationTable{
  ["fenyin"] = "奋音",
  [":fenyin"] = "你的回合内，当你使用和上一张牌颜色不同的牌时，你可以摸一张牌。",

  ["@fenyin-turn"] = "奋音",

  ["$fenyin1"] = "吾军杀声震天，则敌心必乱！",
  ["$fenyin2"] = "阵前亢歌，以振军心！",
}

fenyin:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fenyin.name) and (data.extra_data or {}).can_fenyin
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, fenyin.name)
  end,
})
fenyin:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(fenyin.name, true) and
      data.card.color ~= Card.NoColor and player.room.current == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@fenyin-turn")
    if mark ~= 0 and mark ~= data.card:getColorString() then
      data.extra_data = data.extra_data or {}
      data.extra_data.can_fenyin = true
    end
    room:setPlayerMark(player, "@fenyin-turn", data.card:getColorString())
  end,
})

local AI = Fk.Ltk.AI
fenyin:addAI(AI.reuse("biyue", AI.InvokeStrategy))

return fenyin
