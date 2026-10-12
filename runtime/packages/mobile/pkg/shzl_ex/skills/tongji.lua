local tongji = fk.CreateSkill{
  name = "mobile__tongji",
}

Fk:loadTranslationTable{
  ["mobile__tongji"] = "同疾",
  [":mobile__tongji"] = "当其他角色成为【杀】的目标时，若你在其攻击范围内，且你不是此【杀】的使用者，其可弃置一张牌将此【杀】转移给你。",

  ["#mobile__tongji-invoke"] = "同疾：你可以弃置一张牌，将【杀】转移给 %src",

  ["$mobile__tongji1"] = "嗯额，反了！反了！反了！",
  ["$mobile__tongji2"] = "冒犯天威，大逆不道！",
}

tongji:addEffect(fk.TargetConfirming, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(tongji.name) and data.card.trueName == "slash" and
      target:inMyAttackRange(player) and data.from ~= player and not target:isNude() and
      not table.contains(data.use.tos, player) and not data.cancelled and
      not data.from:isProhibited(player, data.card)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = tongji.name,
      prompt = "#mobile__tongji-invoke:"..player.id,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:doIndicate(target, {player})
    room:throwCard(event:getCostData(self).cards, tongji.name, target, target)
    if data:cancelCurrentTarget() then
      data:addTarget(player)
    end
  end,
})

return tongji
