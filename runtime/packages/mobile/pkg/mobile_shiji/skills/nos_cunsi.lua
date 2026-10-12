local cunsi = fk.CreateSkill {
  name = "nos__cunsi",
}

Fk:loadTranslationTable{
  ["nos__cunsi"] = "存嗣",
  [":nos__cunsi"] = "出牌阶段限一次，你可以将武将牌翻至背面朝上，令一名角色获得一张【杀】，其使用下一张【杀】造成的伤害+1。",

  ["#nos__cunsi"] = "存嗣：你可以翻面，令一名角色获得一张【杀】，且其使用下一张【杀】伤害+1",
  ["@@nos__cunsi"] = "存嗣",

  ["$nos__cunsi1"] = "存亡之际，将军休要迟疑。",
  ["$nos__cunsi2"] = "为保汉嗣，死而后已！",
}

cunsi:addEffect("active", {
  anim_type = "support",
  prompt = "#nos__cunsi",
  card_num = 0,
  target_num = 1,
  can_use = function (self, player)
    return player.faceup and player:usedSkillTimes(cunsi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    player:turnOver()
    if not target.dead then
      room:addPlayerMark(target, "@@nos__cunsi", 1)
      local cards = room:getCardsFromPileByRule("slash", 1, "allPiles")
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonJustMove, cunsi.name)
      end
    end
  end,
})
cunsi:addEffect(fk.AfterCardUseDeclared, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@nos__cunsi") > 0 and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@@nos__cunsi")
    player.room:setPlayerMark(player, "@@nos__cunsi", 0)
  end,
})

return cunsi
