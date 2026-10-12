local limu = fk.CreateSkill {
  name = "ofl_heg__limu",
}

Fk:loadTranslationTable{
  ["ofl_heg__limu"] = "立牧",
  [":ofl_heg__limu"] = "出牌阶段限一次，你可以将一张<font color='red'>♦</font>牌当【乐不思蜀】对你使用，然后你回复1点体力，"..
  "本回合可以多使用此牌点数张【杀】。",

  ["#ofl_heg__limu"] = "立牧：将一张<font color='red'>♦</font>牌当【乐不思蜀】对自己使用，回复1点体力，出【杀】次数增加此牌点数",

  ["$ofl_heg__limu1"] = "米贼作乱，吾必为益州自保。",
  ["$ofl_heg__limu2"] = "废史立牧，可得一方安定。",
}

limu:addEffect("active", {
  anim_type = "control",
  prompt = "#ofl_heg__limu",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:hasDelayedTrick("indulgence") and not table.contains(player.sealedSlots, Player.JudgeSlot)
  end,
  target_filter = Util.FalseFunc,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and Fk:getCardById(to_select).suit == Card.Diamond then
      local card = Fk:cloneCard("indulgence")
      card:addSubcard(to_select)
      return not player:prohibitUse(card) and not player:isProhibited(player, card)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local n = Fk:getCardById(effect.cards[1]).number
    room:useVirtualCard("indulgence", effect.cards, player, player, limu.name)
    if not player.dead then
      room:recover{
        who = player,
        num = 1,
        skillName = limu.name,
      }
    end
    if not player.dead then
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn", n)
    end
  end,
})

return limu
