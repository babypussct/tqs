
local bingling = fk.CreateSkill{
  name = "bingling",
}

Fk:loadTranslationTable{
  ["bingling"] = "冰伶",
  [":bingling"] = "当你使用【杀】指定目标时，你可以弃置目标角色两张牌。若这两张牌类别/花色/牌名字数/点数相同，"..
  "则你获得这两张牌/回复1点体力/摸相当于其中一张牌名字数的牌/令其失去所有体力；若皆不同，则你受到1点无来源的火焰伤害。",

  ["#bingling-invoke"] = "冰伶：你可以弃置 %dest 两张牌并执行后续效果",

  ["$bingling1"] = "身如冰上雪，剑如雪上霜。",
  ["$bingling2"] = "一点霜痕，万里寒生。",
}

bingling:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bingling.name) and
      data.card.trueName == "slash" and #data.to:getCardIds("he") > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = bingling.name,
      prompt = "#bingling-invoke::"..data.to.id,
    }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      min = 2,
      max = 2,
      target = data.to,
      flag = "he",
      skill_name = bingling.name,
    })
    local choices = {}
    if Fk:getCardById(cards[1]).type == Fk:getCardById(cards[2]).type then
      table.insert(choices, 1)
    end
    if Fk:getCardById(cards[1]).suit == Fk:getCardById(cards[2]).suit then
      table.insert(choices, 2)
    end
    local n = Fk:getCardById(cards[1]):getNameLength()
    if n == Fk:getCardById(cards[2]):getNameLength() then
      table.insert(choices, 3)
    end
    if Fk:getCardById(cards[1]).number == Fk:getCardById(cards[2]).number then
      table.insert(choices, 4)
    end
    room:throwCard(cards, bingling.name, data.to, player)
    if table.contains(choices, 1) and not player.dead then
      cards = table.filter(cards, function (id)
        return table.contains(room.discard_pile, id)
      end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, bingling.name, nil, true, player)
      end
    end
    if table.contains(choices, 2) and not player.dead then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = bingling.name,
      }
    end
    if table.contains(choices, 3) and not player.dead then
      player:drawCards(n, bingling.name)
    end
    if table.contains(choices, 4) and data.to.hp > 0 then
      room:loseHp(data.to, data.to.hp, bingling.name, player)
    end
    if #choices == 0 and not player.dead then
      room:damage{
        to = player,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = bingling.name,
      }
    end
  end,
})

return bingling
