local jinjiu = fk.CreateSkill {
  name = "m_ex__jinjiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_ex__jinjiu"] = "禁酒",
  [":m_ex__jinjiu"] = "锁定技，你的【酒】的牌名视为【杀】且此【杀】为普【杀】；"..
  "当你受到渠道为因【酒】生效而伤害值基数增加的【杀】的伤害时，你令伤害值-X （X为因【酒】生效而增加的伤害值基数）；"..
    "其他角色于你的回合内不能使用【酒】。",

  ["$m_ex__jinjiu1"] = "耽此黄汤，岂不误事？",
  ["$m_ex__jinjiu2"] = "陷阵营中，不可饮酒。",
}

jinjiu:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jinjiu.name) and data.card and data.card.trueName == "slash" then
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if parentUseData then
        local drankBuff = parentUseData and (parentUseData.data.extra_data or {}).drankBuff or 0
        if drankBuff > 0 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if parentUseData then
      local drankBuff = parentUseData and (parentUseData.data.extra_data or {}).drankBuff or 0
      if drankBuff > 0 then
        data:changeDamage(-drankBuff)
      end
    end
  end,
})

jinjiu:addEffect("filter", {
  card_filter = function(self, card, player, isJudgeEvent)
    return player:hasSkill(jinjiu.name) and card.name == "analeptic" and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, player, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
})

jinjiu:addEffect("prohibit", {
  anim_type = "offensive",
  prohibit_use = function(self, player, card)
    return card.name == "analeptic" and Fk:currentRoom():getCurrent() and Fk:currentRoom():getCurrent():hasSkill(jinjiu.name)
  end,
})

return jinjiu
