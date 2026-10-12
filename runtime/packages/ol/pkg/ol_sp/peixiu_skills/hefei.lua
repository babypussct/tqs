local hefei = fk.CreateSkill {
  name = "peixiu_hefei",
}

Fk:loadTranslationTable {
  ["peixiu_hefei"] = "合肥",
  [":peixiu_hefei"] = "你获得此技能后，可以弃置至多两张牌，然后摸等量的牌。",

  ["#peixiu_hefei-discard"] = "合肥：弃置至多两张牌，然后摸等量的牌",
}

hefei:addEffect(fk.EventAcquireSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(hefei.name) and data.skill.name == hefei.name and
      #player:getCardIds("he") > 1
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 2,
      include_equip = true,
      skill_name = hefei.name,
      prompt = "#peixiu_hefei-discard",
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards or {}
    room:throwCard(cards, hefei.name, player, player)
    if not player.dead then
      player:drawCards(#cards, hefei.name)
    end
  end
})

return hefei
