local skill = fk.CreateSkill {
  name = "glittery_armor_skill&",
}

Fk:loadTranslationTable{
  ["glittery_armor_skill&"] = "烂银甲",
  [":glittery_armor_skill&"] = "你可以将一张手牌当【闪】使用或打出。",

  ["#glittery_armor_skill&"] = "烂银甲：你可以将一张手牌当【闪】使用或打出。",
}

skill:addEffect("viewas", {
  prompt = "#glittery_armor_skill&",
  pattern = "jink",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("jink")
    c.skillName = "glittery_armor"
    c:addSubcards(cards)
    return c
  end,
})

skill:addEffect(fk.DamageInflicted, {
  priority = 0.1,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and data.card.trueName == "slash" and
      table.find(player:getEquipments(Card.SubtypeArmor), function(id)
        return Fk:getCardById(id).name == "glittery_armor"
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local cards = table.filter(player:getEquipments(Card.SubtypeArmor), function(id)
      return Fk:getCardById(id).name == "glittery_armor"
    end)
    player.room:throwCard(cards, skill.name, player, player)
  end,
})

skill:addAI(nil, "vs_skill", "glittery_armor_skill")

return skill
