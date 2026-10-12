
local qinli = fk.CreateSkill({
  name = "qinli",
})

Fk:loadTranslationTable{
  ["qinli"] = "勤励",
  [":qinli"] = "准备阶段或当你受到1点伤害后，你摸一张牌。" ..
  "每回合结束时，你可以将所有“勤励”牌置入弃牌堆，对当前回合角色造成1点伤害。若你因此失去所有手牌，改为对其造成等量伤害。",

  ["@@qinli-inhand"] = "勤励",
  ["#qinli-invoke"] = "勤励：你可以将所有“勤励”牌置入弃牌堆，对 %dest 造成%arg点伤害",

  ["$qinli1"] = "",
  ["$qinli2"] = "",
}

qinli:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, qinli.name, nil, "@@qinli-inhand")
  end,
})

qinli:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qinli.name) and player.phase == Player.Start
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, qinli.name, nil, "@@qinli-inhand")
  end,
})


qinli:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(qinli.name) and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@qinli-inhand") > 0
      end) and
      not target.dead
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@qinli-inhand") > 0
    end)
    local n = 1
    if #cards == player:getHandcardNum() then
      n = #cards
    end
    if room:askToSkillInvoke(player, {
      skill_name = qinli.name,
      prompt = "#qinli-invoke::"..target.id..":"..n,
    }) then
      event:setCostData(self, { tos = { target }, cards = cards, n = n })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self).cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, qinli.name, nil, true, player)
    if not target.dead then
      room:damage {
        from = player,
        to = target,
        damage = event:getCostData(self).n,
        skillName = qinli.name,
      }
    end
  end,
})

return qinli
