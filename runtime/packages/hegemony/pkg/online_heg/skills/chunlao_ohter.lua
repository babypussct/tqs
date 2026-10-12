local chunlao = fk.CreateSkill {
  name = "ol_heg__chunlao_other&",
}

Fk:loadTranslationTable {
  ["ol_heg__chunlao_other&"] = "醇醪",
  [":ol_heg__chunlao_other&"] = "与你势力相同的角色可以移去一枚“阴阳鱼”或“珠联璧合”标记，视为使用一张【酒】。",
  ["#ol_heg__chunlao"] = "醇醪：移去一枚“阴阳鱼”或“珠联璧合”标记，视为使用一张【酒】",
}

local H = require "packages.hegemony.util"

chunlao:addEffect("viewas", {
  anim_type = "support",
  prompt = "#ol_heg__chunlao",
  pattern = "analeptic",
  mute_card = false,
  interaction = function(self, player)
    local names = {}
    if player:getMark("@!!yinyangfish") > 0 then
      table.insertIfNeed(names, "yinyangfish")
    end
    if player:getMark("@!!companion") > 0 then
      table.insertIfNeed(names, "companion")
    end
    if #names == 0 then return end
    return UI.ComboBox { choices = names, all_choices = { "yinyangfish", "companion" } }
  end,
  before_use = function(self, player, use)
    local room = player.room
    if self.interaction.data == "yinyangfish" then
      H.removeHegMark(room, player, "yinyangfish", 1)
    else
      H.removeHegMark(room, player, "companion", 1)
    end
    player:broadcastSkillInvoke("ol_heg__chunlao")
  end,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("analeptic")
    c.skillName = chunlao.name
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@!!yinyangfish") > 0 or player:getMark("@!!companion") > 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and (player:getMark("@!!yinyangfish") > 0 or player:getMark("@!!companion") > 0)
  end,
})

return chunlao
