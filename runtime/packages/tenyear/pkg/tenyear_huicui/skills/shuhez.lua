local shuhez = fk.CreateSkill {
  name = "shuhez",
}

Fk:loadTranslationTable{
  ["shuhez"] = "疏和",
  [":shuhez"] = "每回合限一次，当其他角色使用伤害牌时，你可以从牌堆中获得一张【酒】（没有则摸一张牌），令其选择一项："..
  "1.此牌无效并视为使用一张【酒】，2.令你摸一张牌。",

  ["shuhez_use"] = "此牌无效，你视为使用【酒】",
  ["shuhez_draw"] = "%src摸一张牌",

  ["$shuhez1"] = "今日以酒会友，切莫伤了和气。",
  ["$shuhez2"] = "吾恃三分薄面，诸君且一饮而尽！",
}

shuhez:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(shuhez.name) and
      data.card.is_damage_card and player:usedSkillTimes(shuhez.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule("analeptic")
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, shuhez.name, nil, false, player)
    else
      player:drawCards(1, shuhez.name)
    end
    if target.dead then return end
    local all_choices = {"shuhez_use", "shuhez_draw:"..player.id}
    local choices = table.simpleClone(all_choices)
    if player.dead then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = shuhez.name,
      all_choices = all_choices,
    })
    if choice == "shuhez_use" then
      --data:removeAllTargets()
      data:setNullified()
      room:useVirtualCard("analeptic", nil, target, target, shuhez.name, true)
    elseif choice:startsWith("shuhez_draw") then
      player:drawCards(1, shuhez.name)
    end
  end,
})

return shuhez
