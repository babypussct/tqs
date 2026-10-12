local tianshu = fk.CreateSkill {
  name = "mobile__tianshu",
}

Fk:loadTranslationTable{
  ["mobile__tianshu"] = "天书",
  [":mobile__tianshu"] = "出牌阶段开始时，若<a href=':js__peace_spell'>【太平要术】</a>不在游戏内、在牌堆或弃牌堆中，"..
  "你可以弃置一张牌，令一名角色获得【太平要术】并使用之。",

  ["#mobile__tianshu-invoke"] = "天书：你可以弃置一张牌，令一名角色获得【太平要术】并使用",

  ["$mobile__tianshu1"] = "其耆欲深者，其天机浅。",
  ["$mobile__tianshu2"] = "杀生者不死，生生者不生。",
}

tianshu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(tianshu.name) and player.phase == Player.Play and not player:isNude() then
      local spell = player.room:prepareDeriveCards({{"js__peace_spell", Card.Heart, 3}}, "mobile__tianshu_spell")[1]
      return table.contains({Card.Void, Card.DrawPile, Card.DiscardPile}, player.room:getCardArea(spell))
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("he"), function(id)
      return not player:prohibitDiscard(id)
    end)
    local tos, id = room:askToChooseCardsAndPlayers(player, {
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = 1,
      targets = room.alive_players,
      pattern = tostring(Exppattern{ id = cards }),
      skill_name = tianshu.name,
      prompt = "#mobile__tianshu-invoke",
      cancelable = true,
    })
    if #tos > 0 and #id > 0 then
      event:setCostData(self, {tos = tos, cards = id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:throwCard(event:getCostData(self).cards, tianshu.name, player, player)
    local spell = room:prepareDeriveCards({{"js__peace_spell", Card.Heart, 3}}, "mobile__tianshu_spell")[1]
    if not to.dead and table.contains({Card.Void, Card.DrawPile, Card.DiscardPile}, room:getCardArea(spell)) then
      room:moveCardTo(spell, Player.Hand, to, fk.ReasonPrey, tianshu.name)
      local card = Fk:getCardById(spell)
      if table.contains(to:getCardIds("h"), spell) and card.name == "js__peace_spell" and to:canUseTo(card, to) then
        room:useCard{
          from = to,
          tos = {to},
          card = card,
        }
      end
    end
  end,
})

return tianshu
