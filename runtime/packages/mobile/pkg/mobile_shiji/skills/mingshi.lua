local mingshi = fk.CreateSkill {
  name = "mobile__mingshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__mingshi"] = "名士",
  [":mobile__mingshi"] = "锁定技，当你受到伤害后，若你有“谦”标记，伤害来源须弃置其区城内的一张牌，若弃置的牌为：黑色，你获得之；"..
  "红色，你回复1点体力。",

  ["#mobile__mingshi-discard"] = "名士：请弃置区城内一张牌，若为黑色则 %src 获得，若为红色则 %scr 回复体力",

  ["$mobile__mingshi1"] = "纵有强权在侧，亦不可失吾风骨。",
  ["$mobile__mingshi2"] = "黜邪崇正，何惧之有？",
}

mingshi:addEffect(fk.Damaged, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mingshi.name) and
      player:getMark("@@mobile__kongrong_qian") > 0 and
      data.from and not data.from.dead and not data.from:isAllNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, {data.from})
    local cards = table.filter(data.from:getCardIds("hej"), function (id)
      return not data.from:prohibitDiscard(id)
    end)
    local card = room:askToCards(data.from, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      pattern = tostring(Exppattern{ id = cards }),
      expand_pile = data.from:getCardIds("j"),
      prompt = "#mobile__mingshi-discard:"..player.id,
      skill_name = mingshi.name,
      cancelable = false,
    })
    local color = Fk:getCardById(card[1]).color
    room:throwCard(card, mingshi.name, data.from, data.from)
    if not player.dead then
      if color == Card.Black and room:getCardArea(card[1]) == Card.DiscardPile then
        room:obtainCard(player, card, true, fk.ReasonJustMove, player, mingshi.name)
      elseif color == Card.Red and player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = mingshi.name,
        }
      end
    end
  end,
})

return mingshi
