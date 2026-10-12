local jiushi = fk.CreateSkill {
  name = "m_ex__jiushi",
  dynamic_desc = function(self, player)
    return player:getMark("m_ex__jiushi_upgrade") > 0 and "m_ex__jiushi_upgrade" or "m_ex__jiushi"
  end,
}

Fk:loadTranslationTable{
  ["m_ex__jiushi"] = "酒诗",
  [":m_ex__jiushi"] = "当你需要使用【酒】时，若你的武将牌正面向上，你可以翻面，视为使用一张【酒】；"..
  "当你受到伤害后，若你的武将牌背面向上，且你未因此次伤害发动过〖酒诗〗，你可以翻面并随机获得牌堆里的一张锦囊牌。",

  [":m_ex__jiushi_upgrade"] = "当你需要使用【酒】时，若你的武将牌正面向上，你可以翻面，视为使用一张【酒】；"..
  "当你受到伤害后，若你的武将牌背面向上，且你未因此次伤害发动过〖酒诗〗，你可以翻面；当你翻面后，你随机获得牌堆里的一张锦囊牌。",

  ["#m_ex__jiushi-active"] = "酒诗：你可以翻面来视为使用一张【酒】",
  ["#m_ex__jiushi-turnover"] = "酒诗：是否翻回正面？",

  ["$m_ex__jiushi1"] = "乐饮过三爵，缓带倾庶羞。",
  ["$m_ex__jiushi2"] = "归来宴平乐，美酒斗十千。",
}

jiushi:addEffect("viewas", {
  anim_type = "support",
  prompt = "#m_ex__jiushi-active",
  pattern = "analeptic",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = Util.FalseFunc,
  before_use = function(self, player)
    player:turnOver()
  end,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("analeptic")
    c.skillName = jiushi.name
    return c
  end,
  enabled_at_play = function(self, player)
    return player.faceup
  end,
  enabled_at_response = function(self, player, response)
    return not response and player.faceup
  end,
})

jiushi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jiushi.name) and not player.faceup then
      local logic = player.room.logic
      local damage_event = logic:getCurrentEvent():findParent(GameEvent.Damage, true)
      return damage_event ~= nil and #logic:getEventsByRule(GameEvent.SkillEffect, 1, function(e)
        if e.data.skill.trueName == "jiushi" then
          local dying_event = e.parent
          if dying_event and dying_event.event == GameEvent.Dying then
            return dying_event.data.damage == data
          end
        end
      end, damage_event.id) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jiushi.name,
      prompt = "#m_ex__jiushi-turnover",
    })
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    if not player.dead and player:getMark("m_ex__jiushi_upgrade") == 0 then
      local room = player.room
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick")
      if #cards > 0 then
        room:obtainCard(player, cards, false, fk.ReasonJustMove, player, jiushi.name)
      end
    end
  end,
})

jiushi:addEffect(fk.TurnedOver, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiushi.name) and player:getMark("m_ex__jiushi_upgrade") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player.room:getCardsFromPileByRule(".|.|.|.|.|trick")
    if #cards > 0 then
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player, jiushi.name)
    end
  end,
})

jiushi:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "m_ex__jiushi_upgrade", 0)
end)

return jiushi
