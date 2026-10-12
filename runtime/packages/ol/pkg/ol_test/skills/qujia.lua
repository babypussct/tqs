local qujia = fk.CreateSkill {
  name = "qujia",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["qujia"] = "驱驾",
  [":qujia"] = "限定技，回合结束后，若你本回合未杀死过角色，你选择一项：1.执行一个额外回合；2.本局使用【杀】的次数+1并获得一张【杀】。",
    --"若你执行额外回合且此回合内未杀死角色，你失去此技能并摸X张牌（X为你执行过的回合数且不超过你的体力上限）。",

  ["qujia_extra"] = "执行一个额外回合",
  ["qujia_slash"] = "使用【杀】次数上限+1，获得一张【杀】",
  ["@qujia"] = "驱驾",

  ["$qujia1"] = "韩暹！你若畏死，某便独享这护驾之功！",
  ["$qujia2"] = "驱驾千里，终得拨云见日，玉辂东归。",
}

qujia:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      player == target and
      player:hasSkill(qujia.name) and
      player:usedSkillTimes(qujia.name, Player.HistoryGame) == 0 and
      #player.room.logic:getEventsOfScope(GameEvent.Death, 1, function(e)
        local death = e.data
        return death.killer == player
      end, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askToChoice(
      player,
      {
        choices = { "qujia_extra", "qujia_slash", "Cancel" },
        skill_name = qujia.name,
      }
    )

    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    --[[if data.reason == qujia.name then
      room:handleAddLoseSkills(player, "-qujia")
      local n = #room.logic:getEventsOfScope(GameEvent.Turn, player.maxHp+1, function(e)
        return e.data.who == player
      end, Player.HistoryGame) - 1
      if n > 0 then
        player:drawCards(n, qujia.name)
      end
    else]]
    local choice = event:getCostData(self).choice
    if choice == "qujia_extra" then
      player:gainAnExtraTurn(true, qujia.name)
    else
      room:addPlayerMark(player, "@qujia")
      room:addPlayerMark(player, MarkEnum.SlashResidue)
      local card = room:getCardsFromPileByRule("slash")
      if #card == 0 then
        card = room:getCardsFromPileByRule("slash", 1, "discardPile")
      end
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, qujia.name, nil, false, player)
      end
    end
    --end
  end,
})

return qujia
