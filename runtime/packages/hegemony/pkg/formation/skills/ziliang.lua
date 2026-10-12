
local ziliang = fk.CreateSkill{
  name = "ziliang",
  tags = { Skill.DeputyPlace },
}

Fk:loadTranslationTable{
  ["ziliang"] = "资粮",
  [":ziliang"] = "副将技，当一名势力与你相同的角色受到伤害后，你可以将一张“田”交给其。",

  ["#ziliang-give"] = "资粮：你可以将一张“田”交给 %dest",

  ["$ziliang1"] = "兵，断不可无粮啊。",
  ["$ziliang2"] = "吃饱了，才有力气为国效力。",
}

local H = require "packages.hegemony.util"

ziliang:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ziliang.name) and H.compareKingdomWith(player, target) and
      not target.dead and #player:getPile("ld__dengai_field") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = ziliang.name,
      pattern = ".|.|.|ld__dengai_field",
      prompt = "#ziliang-give::"..target.id,
      cancelable = true,
      expand_pile = "ld__dengai_field",
    })
    if #card > 0 then
      event:setCostData(self, { tos = { target }, cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, target, fk.ReasonGive, ziliang.name, nil, true, player)
  end,
})

return ziliang
