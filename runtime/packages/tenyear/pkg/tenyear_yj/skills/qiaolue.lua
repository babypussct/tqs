local qiaolue = fk.CreateSkill {
  name = "qiaolue",
}

Fk:loadTranslationTable{
  ["qiaolue"] = "趫掠",
  [":qiaolue"] = "当你使用牌指定其他角色为目标后，若目标角色本局游戏第一次成为此牌名的目标，你可以获得其一张牌。",

  ["#qiaolue-invoke"] = "趫掠：你可以获得 %dest 一张牌",

  ["$qiaolue1"] = "冀州千里膏腴，尽是我黑山食邑！",
  ["$qiaolue2"] = "小的们，放开手脚，抢他个一干二净！",
}

qiaolue:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(qiaolue.name) and
      data.to ~= player and not data.to:isNude() then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.card.trueName == data.card.trueName and table.contains(use.tos, data.to)
      end, Player.HistoryGame)
      return #use_events == 1 and use_events[1].data == data.use
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = qiaolue.name,
      prompt = "#qiaolue-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = "he",
      skill_name = qiaolue.name,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, qiaolue.name, nil, false, player)
  end,
})

return qiaolue
