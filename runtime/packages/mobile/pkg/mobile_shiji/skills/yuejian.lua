local yuejian = fk.CreateSkill {
  name = "mobile__yuejian",
}

Fk:loadTranslationTable{
  ["mobile__yuejian"] = "约俭",
  [":mobile__yuejian"] = "你的手牌上限等于体力上限；当你进入濒死状态时，你可以弃置两张牌，回复1点体力。",

  ["#mobile__yuejian-invoke"] = "约俭：你可以弃两张牌，回复1点体力",

  ["$mobile__yuejian1"] = "后宫节用，可树德于外。",
  ["$mobile__yuejian2"] = "减损之益，不亚多得。",
}

yuejian:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuejian.name) and #player:getCardIds("he") > 1
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = yuejian.name,
      prompt = "#mobile__yuejian-invoke",
      cancelable = true,
      will_throw = true,
      skip = true,
    })
    if #cards == 2 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self).cards, yuejian.name, player, player)
    if player:isWounded() and not player.dead then
      player.room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = yuejian.name,
      }
    end
  end,
})
yuejian:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:hasSkill(yuejian.name) then
      return player.maxHp
    end
  end
})

return yuejian
