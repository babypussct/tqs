local mingren = fk.CreateSkill {
  name = "ol__mingren",
  derived_piles = "ol__luzhi_duty",
}

Fk:loadTranslationTable{
  ["ol__mingren"] = "明任",
  [":ol__mingren"] = "游戏开始时，你摸两张牌，然后将一张手牌置于武将牌上，称为“任”。结束阶段，你可以用一张手牌替换“任”。",

  ["ol__luzhi_duty"] = "任",
  ["#ol__mingren-put"] = "明任：请将一张手牌置为“任”",
  ["#ol__mingren-exchange"] = "明任：你可以用一张手牌替换“任”",

  ["$ol__mingren1"] = "此等重任，非先生而不可为。",
  ["$ol__mingren2"] = "唯才是举，便得而用之。",
}

mingren:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mingren.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, mingren.name)
    if not player:isKongcheng() and player:hasSkill(mingren.name, true) then
      local card = room:askToCards(player,{
        min_num = 1,
        max_num = 1,
        skill_name = mingren.name,
        cancelable = false,
        prompt = "#ol__mingren-put",
      })
      if #card > 0 then
        player:addToPile("ol__luzhi_duty", card, true, mingren.name, player)
      end
    end
  end,
})

mingren:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mingren.name) and player.phase == Player.Finish and
      not player:isKongcheng() and #player:getPile("ol__luzhi_duty") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player,{
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = mingren.name,
      prompt = "#ol__mingren-exchange",
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:swapCardsWithPile(player, event:getCostData(self).cards, player:getPile("ol__luzhi_duty"), mingren.name, "ol__luzhi_duty")
  end,
})

return mingren
