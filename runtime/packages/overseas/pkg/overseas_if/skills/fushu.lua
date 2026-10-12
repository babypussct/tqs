local fushu = fk.CreateSkill {
  name = "os__fushu",
}

Fk:loadTranslationTable{
  ["os__fushu"] = "复舒",
  [":os__fushu"] = "每回合限一次，当你需使用【桃】时，你可以展示一张手牌并与牌堆顶的一张牌比较点数大小："..
  "若展示的手牌点数大于牌堆顶的牌，你视为使用一张【桃】；若点数不大于牌堆顶的牌，你下次受到的伤害+1。"..
  "然后将你展示的手牌置入弃牌堆。",

  ["#os__fushu"] = "复舒：展示一张手牌与牌堆顶牌比较点数大小，若展示牌点数较大则视为使用【桃】，否则你下次受到伤害+1",
  ["@os__fushu"] = "复舒 受伤+",

  ["$os__fushu1"] = "东风不吝回青意，当还病树万木春。",
  ["$os__fushu2"] = "常怀仁爱之心，天必不绝其路。",
}

fushu:addEffect("viewas", {
  anim_type = "support",
  pattern = "peach",
  prompt = "#os__fushu",
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("peach", nil, nil, fushu.name)
    card:addFakeSubcards(cards)
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local id1, id2 = use.card.fake_subcards[1], room:getNCards(1)[1]
    local moves = {
      {
        ids = {id1},
        from = player,
        toArea = Card.Processing,
        moveReason = fk.ReasonPut,
        skillName = fushu.name,
        moveVisible = true,
      },
      {
        ids = {id2},
        toArea = Card.Processing,
        moveReason = fk.ReasonPut,
        skillName = fushu.name,
        moveVisible = true,
      }
    }
    room:sendLog{
      type = "#ShowPindianCard",
      from = player.id,
      arg = Fk:getCardById(id1):toLogString(),
    }
    room:moveCards(table.unpack(moves))
    room:sendFootnote({ id1 }, {
      type = "##PindianCard",
      from = player.id,
    })
    local winner
    if Fk:getCardById(id1).number > Fk:getCardById(id2).number then
      winner = player
    end
    room:sendLog{
      type = "#ShowPindianResult",
      from = player.id,
      to = {},
      arg = winner == player and "pindianwin" or "pindiannotwin"
    }

    room:cleanProcessingArea({ id1, id2 }, fushu.name)
    if winner ~= player then
      if not player.dead then
        room:addPlayerMark(player, "@os__fushu", 1)
      end
      return fushu.name
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(fushu.name, Player.HistoryTurn) == 0 and not player:isKongcheng()
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(fushu.name, Player.HistoryTurn) == 0 and not player:isKongcheng()
  end,
})

fushu:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@os__fushu") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(player:getMark("@os__fushu"))
    player.room:setPlayerMark(player, "@os__fushu", 0)
  end,
})

return fushu
