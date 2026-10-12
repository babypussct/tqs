local yimou = fk.CreateSkill{
  name = "mobile__yimou",
}

Fk:loadTranslationTable{
  ["mobile__yimou"] = "毅谋",
  [":mobile__yimou"] = "当至你距离1以内的角色受到伤害后，你可以选择一项：1.令其从牌堆获得一张【杀】；2.令其将一张手牌交给另一名角色，摸一张牌。",

  ["mobile__yimou_slash"] = "%dest获得一张【杀】",
  ["mobile__yimou_give"] = "%dest将一张手牌交给另一名角色，摸一张牌",
  ["#mobile__yimou-give"] = "毅谋：将一张手牌交给一名其他角色，然后摸一张牌",

  ["$mobile__yimou1"] = "泰然若定，攻敌自溃！",
  ["$mobile__yimou2"] = "吾等当为大义，兴大谋，成大事！",
}

yimou:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yimou.name) and target:distanceTo(player) <= 1 and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = { "mobile__yimou_slash::"..target.id }
    if not target:isKongcheng() and #room:getOtherPlayers(target, false) > 0 then
      table.insert(choices, "mobile__yimou_give::"..target.id)
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = yimou.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:notifySkillInvoked(player, yimou.name, "masochism", {target})
    if choice:startsWith("mobile__yimou_slash") then
      player:broadcastSkillInvoke(yimou.name, 1)
      local id = room:getCardsFromPileByRule("slash")
      if #id > 0 then
        room:obtainCard(target, id, true, fk.ReasonJustMove)
      end
    else
      player:broadcastSkillInvoke(yimou.name, 2)
      local to, cards = room:askToChooseCardsAndPlayers(target, {
        min_card_num = 1,
        max_card_num = 1,
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(target, false),
        pattern = ".|.|.|hand",
        skill_name = yimou.name,
        prompt = "#mobile__yimou-give",
        cancelable = false,
      })
      room:moveCardTo(cards, Player.Hand, to[1], fk.ReasonGive, yimou.name, nil, false, target)
      if not target.dead then
        target:drawCards(1, yimou.name)
      end
    end
  end,
})

return yimou
