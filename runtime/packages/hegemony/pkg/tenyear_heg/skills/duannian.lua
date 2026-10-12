local duannian = fk.CreateSkill{
  name = "ty_heg__duannian",
}
duannian:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duannian.name)
      and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(player:getCardIds("h"), duannian.name, player, player)
    if player.dead then return end
    player:drawCards(player.maxHp - player:getHandcardNum(), duannian.name)
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__duannian"] = "断念",
  [":ty_heg__duannian"] = "出牌阶段结束时，你可弃置所有手牌，然后将手牌摸至体力上限。",

  ["$ty_heg__duannian1"] = "断思量，莫思量。",
  ["$ty_heg__duannian2"] = "一别两宽，不负相思。",
}

return duannian
