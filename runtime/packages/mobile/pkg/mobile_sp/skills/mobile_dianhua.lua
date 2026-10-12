local mobileDianhua = fk.CreateSkill {
  name = "mobile__dianhua",
}

Fk:loadTranslationTable{
  ["mobile__dianhua"] = "点化",
  [":mobile__dianhua"] = "准备阶段或结束阶段，你可以观看牌堆顶的X张牌（X为你的标记数），将这些牌以任意顺序放回牌堆顶。",

  ["$mobile__dianhua1"] = "点之以形，化之以心。 ",
  ["$mobile__dianhua2"] = "俯仰喟天地，坐化对本心。",
}

mobileDianhua:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(mobileDianhua.name) and
      (player.phase == Player.Start or player.phase == Player.Finish) and
      not table.every({ "spade", "club", "heart", "diamond" }, function (suit)
        return player:getMark("@@mobile__falu" .. suit) == 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local n = 0
    for _, suit in ipairs({ "spade", "club", "heart", "diamond" }) do
      if player:getMark("@@mobile__falu" .. suit) > 0 then
        n = n + 1
      end
    end
    if n > 0 and player.room:askToSkillInvoke(player, { skill_name = mobileDianhua.name }) then
      event:setCostData(self, {n = n})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToGuanxing(player, { cards = room:getNCards(event:getCostData(self).n), bottom_limit = { 0, 0 } })
  end,
})

return mobileDianhua
