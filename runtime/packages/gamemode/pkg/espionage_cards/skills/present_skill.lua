local skill = fk.CreateSkill {
  name = "present_skill&",
}

Fk:loadTranslationTable{
  ["present_skill&"] = "赠予",
  [":present_skill&"] = "出牌阶段，你可以从手牌中将一张有“赠”标记的牌正面向上赠予其他角色。若此牌不是装备牌，则进入该角色手牌区；若此牌是装备牌，"..
  "则进入该角色装备区且替换已有装备。",

  ["#present_skill&"] = "将一张有“赠”标记的牌赠予其他角色",
}

local U = require "packages.utility.utility"

skill:addEffect("active", {
  anim_type = "support",
  prompt = "#present_skill&",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@present") > 0 end)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("@@present") > 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    U.presentCard(effect.from, effect.tos[1], effect.cards[1], skill.name)
  end,
})

return skill
