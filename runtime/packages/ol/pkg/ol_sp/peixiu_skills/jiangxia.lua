local jiangxia = fk.CreateSkill {
  name = "peixiu_jiangxia",
}

Fk:loadTranslationTable {
  ["peixiu_jiangxia"] = "江夏",
  [":peixiu_jiangxia"] = "你获得此技能后，可以令一名其他角色摸两张牌，然后交给你一张牌。",

  ["#peixiu_jiangxia-choose"] = "江夏：选择一名其他角色，其摸两张牌然后交给你一张牌",
  ["#peixiu_jiangxia-give"] = "江夏：请交给 %src 一张牌",
}

jiangxia:addEffect(fk.EventAcquireSkill, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jiangxia.name) and data.skill.name == jiangxia.name and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = jiangxia.name,
      prompt = "#peixiu_jiangxia-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    to:drawCards(2, jiangxia.name)
    if not to.dead and not to:isNude() then
      local card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = jiangxia.name,
        prompt = "#peixiu_jiangxia-give:"..player.id,
        cancelable = false,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, jiangxia.name, nil, false, to)
    end
  end
})

return jiangxia
