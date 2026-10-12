local kuangfu = fk.CreateSkill{
  name = "kuangfu",
}

Fk:loadTranslationTable{
  ["kuangfu"] = "狂斧",
  [":kuangfu"] = "出牌阶段内限一次，当你使用【杀】指定目标后，你可以获得目标角色装备区里的一张牌，然后若此【杀】未造成伤害，你弃置两张牌。",

  ["#kuangfu-invoke"] = "狂斧：你可以获得 %dest 装备区一张牌",

  ["$kuangfu1"] = "吾乃上将潘凤，可斩华雄！",
  ["$kuangfu2"] = "这家伙，还是给我用吧！",
}

kuangfu:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(kuangfu.name) and
      data.card.trueName == "slash" and player.phase == Player.Play and #data.to:getCardIds("e") > 0 and
      player:usedSkillTimes(kuangfu.name, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = kuangfu.name,
      prompt = "#kuangfu-invoke::" .. data.to.id,
    }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = "e",
      skill_name = kuangfu.name,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, kuangfu.name, nil, false, player)
    data.extra_data = data.extra_data or {}
    data.extra_data.kuangfuUser = player.id
  end,
})

kuangfu:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return (data.extra_data or {}).kuangfuUser == player.id and not player.dead and not data.damageDealt
  end,
  on_use = function (self, event, target, player, data)
    player.room:askToDiscard(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = kuangfu.name,
      cancelable = false,
    })
  end,
})

return kuangfu
