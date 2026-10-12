local yidu = fk.CreateSkill{
  name = "heg__yidu",
}

Fk:loadTranslationTable{
  ["heg__yidu"] = "遗毒",
  [":heg__yidu"] = "当你使用伤害类牌后，你可以展示一名未受到此牌伤害的目标角色至多两张手牌，若颜色均相同，你弃置这些牌。",

  ["#heg__yidu-invoke"] = "遗毒：你可以展示 %dest 至多两张手牌，若颜色相同则全部弃置",
  ["#heg__yidu-choose"] = "遗毒：你可以展示一名目标至多两张手牌，若颜色相同则全部弃置",

  ["$heg__yidu1"] = "彼之砒霜，吾之蜜糖。",
  ["$heg__yidu2"] = "巧动心思，以遗他人。",
}

yidu:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yidu.name) and data.card.is_damage_card and
      table.find(data.tos, function (p)
        return not (data.damageDealt and data.damageDealt[p]) and not p:isKongcheng() and not p.dead
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.tos, function (p)
      return not (data.damageDealt and data.damageDealt[p]) and not p:isKongcheng() and not p.dead
    end)
    if #target > 1 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = yidu.name,
        prompt = "#heg__yidu-choose",
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    elseif room:askToSkillInvoke(player, {
      skill_name = yidu.name,
      prompt = "#heg__yidu-invoke::"..targets[1].id,
    }) then
      event:setCostData(self, {tos = targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = room:askToChooseCards(player, {
      target = to,
      min = 1,
      max = 2,
      flag = "h",
      skill_name = yidu.name,
    })
    local yes = table.every(cards, function (id)
      return Fk:getCardById(id):compareColorWith(Fk:getCardById(cards[1]))
    end)
    to:showCards(cards)
    if yes then
      cards = table.filter(cards, function (id)
        return table.contains(to:getCardIds("h"), id)
      end)
      if #cards > 0 then
        room:throwCard(cards, yidu.name, to, player)
      end
    end
  end,
})

return yidu
