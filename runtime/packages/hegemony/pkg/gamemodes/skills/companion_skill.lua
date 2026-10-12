local companionSkill = fk.CreateSkill{
  name = "companion_skill&",
}
local H = require "packages.hegemony.util"
companionSkill:addEffect("viewas", {
  name = "companion_skill&",
  anim_type = "support",
  prompt = "#companion_skill&",
  pattern = ".",
  interaction = function(self, player)
    if Fk.currentResponsePattern == nil then
      return UI.OptionBox { options = { "companion_peach", "draw2" }, direct_send = true }
    end
  end,
  card_filter = Util.FalseFunc,
  refresh_interaction = function(self, player, selected_cards, selected_targets)
    if player:canUse(Fk:cloneCard("peach", Card.NoSuit, 0, companionSkill.name)) then
      return { "companion_peach", "draw2" }
    end
    return { "draw2" }
  end,
  view_as = function(self)
    if Fk.currentResponsePattern then
      return Fk:cloneCard("peach", Card.NoSuit, 0, companionSkill.name)
      --注意：此处仅在客户端可返回卡牌
      --用于响应使用的情况，让req使用cardskill的target_filter
    end
  end,
  on_use = function(self, room, effect, card, params)
    local player = effect.from
    H.removeHegMark(player.room, player, "companion", 1)
    if effect.interaction_data == "draw2" then
      player:drawCards(2, companionSkill.name)
    else
      --case: nil（响应使用）、"companion_peach"
      return {---@type UseCardDataSpec
        from = player,
        tos = effect.tos,
        card = Fk:cloneCard("peach", Card.NoSuit, 0, companionSkill.name),
      }
    end
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@!!companion") > 0
  end,
  enabled_at_response = function(self, player)
    return player:getMark("@!!companion") > 0 and
      player:canUseOrResponseInCurrent(Fk:cloneCard("peach", Card.NoSuit, 0, companionSkill.name))
  end,
})

Fk:loadTranslationTable{
  ["companion_skill&"] = "珠联璧合",
  [":companion_skill&"] = "你可弃一枚“珠联璧合”，视为使用【桃】或摸两张牌。",
  ["#companion_skill&"] = "你可弃一枚“珠联璧合”，视为使用【桃】或摸两张牌",
  ["companion"] = "珠联璧合",
  ["companion_peach"] = "视为使用【桃】",
}

return companionSkill
