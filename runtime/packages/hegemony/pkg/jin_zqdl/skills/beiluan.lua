local beiluan = fk.CreateSkill({
  name = "heg__beiluan",
})

Fk:loadTranslationTable{
  ["heg__beiluan"] = "备乱",
  [":heg__beiluan"] = "当你受到伤害后，你可以令伤害来源所有非装备手牌视为【杀】直到当前回合结束。",

  ["#heg__beiluan-invoke"] = "备乱：是否令 %dest 本回合非装备手牌视为【杀】？",
  ["@@heg__beiluan-turn"] = "备乱",

  ["$heg__beiluan1"] = "秣马厉兵，筹伐不臣！",
  ["$heg__beiluan2"] = "枕戈待旦，秣马征平。",
}

beiluan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(beiluan.name) and
      data.from and not data.from.dead
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = beiluan.name,
      prompt = "#heg__beiluan-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(data.from, "@@heg__beiluan-turn", 1)
  end
})

beiluan:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return player:getMark("@@heg__beiluan-turn") > 0 and
      card.type ~= Card.TypeEquip and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})

return beiluan
