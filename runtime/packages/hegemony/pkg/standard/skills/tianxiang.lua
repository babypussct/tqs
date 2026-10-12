local tianxiang = fk.CreateSkill{
  name = "hs__tianxiang",
}
tianxiang:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tianxiang.name) and target == player and not player:isKongcheng() and
      (player:getMark("hs__tianxiang_damage-turn") == 0 or player:getMark("hs__tianxiang_loseHp-turn") == 0)
  end,
  on_cost = function(self, event, target, player, data)
    local tar, card, ok = player.room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      pattern = ".|.|heart|hand",
      targets = player.room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      cancelable = true,
      prompt = "#hs__tianxiang-choose",
      skill_name = tianxiang.name,
      will_throw = true,
    })
    if ok then
      event:setCostData(self, {tos = tar, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    local to = event:getCostData(self).tos[1]
    local cid = event:getCostData(self).cards
    room:throwCard(cid, tianxiang.name, player, player)

    if to.dead then return end
    local choices = {}
    if player:getMark("hs__tianxiang_loseHp-turn") == 0 then
      table.insert(choices, "hs__tianxiang_loseHp")
    end
    if data.from and not data.from.dead and player:getMark("hs__tianxiang_damage-turn") == 0 then
      table.insert(choices, "hs__tianxiang_damage")
    end
    local choice = room:askToChoice(player, {choices = choices, skill_name = tianxiang.name, prompt = "#hs__tianxiang-choice::"..to.id})
    if choice == "hs__tianxiang_loseHp" then
      room:setPlayerMark(player, "hs__tianxiang_loseHp-turn", 1)
      room:loseHp(to, 1, tianxiang.name)
      if not to.dead and (room:getCardArea(cid) == Card.DrawPile or room:getCardArea(cid) == Card.DiscardPile) then
        room:obtainCard(to, cid, true, fk.ReasonJustMove)
      end
    else
      room:setPlayerMark(player, "hs__tianxiang_damage-turn", 1)
      room:damage{
        from = data.from,
        to = to,
        damage = 1,
        skillName = tianxiang.name,
      }
      if not to.dead then
        to:drawCards(math.min(to:getLostHp(), 5), tianxiang.name)
      end
    end
  end,
})



Fk:loadTranslationTable{
  ["hs__tianxiang"] = "天香",
  [":hs__tianxiang"] = "当你受到伤害时，你可弃置一张<font color='red'>♥</font>手牌并选择一名其他角色。" ..
    "你防止此伤害，选择本回合未选择过的一项：1.令来源对其造成1点伤害，其摸X张牌（X为其已损失的体力值且至多为5）；" ..
    "2.令其失去1点体力，其获得牌堆或弃牌堆中你以此法弃置的牌。",

  ["#hs__tianxiang-choose"] = "天香：弃置一张<font color='red'>♥</font>手牌并选择一名其他角色",
  ["#hs__tianxiang-choice"] = "天香：选择一项令 %dest 执行",
  ["hs__tianxiang_damage"] = "令其受到1点伤害并摸已损失体力值的牌",
  ["hs__tianxiang_loseHp"] = "令其失去1点体力并获得你弃置的牌",

  ["$hs__tianxiang1"] = "接着哦~",
  ["$hs__tianxiang2"] = "替我挡着~",
}

return tianxiang