local osMingren = fk.CreateSkill {
  name = "os__mingren",
  derived_piles = "os__duty",
}

Fk:loadTranslationTable{
  ["os__mingren"] = "明任",
  [":os__mingren"] = "①游戏开始时，你摸一张牌，将一张手牌置于武将牌上，称为“任”。②出牌阶段开始和结束时，你可用一张手牌替换“任”。",

  ["os__duty"] = "任",
  ["#os__mingren-exchange"] = "明任：你可用一张手牌替换“任”",
  ["#os__mingren-put"] = "明任：请将一张手牌置于武将牌上",

  ["$os__mingren1"] = "吾之任，君之明举！",
  ["$os__mingren2"] = "得义真所救，吾任之必尽瘁以报。",
}

osMingren:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osMingren.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osMingren.name
    local room = player.room
    player:drawCards(1, skillName)
    if not player:isKongcheng() then
      local cids = room:askToCards(
        player,
        {
          min_num = 1,
          max_num = 1,
          skill_name = skillName,
          cancelable = false,
          prompt = "#os__mingren-put",
        }
      )
      if #cids > 0 then
        player:addToPile("os__duty", cids[1], true, skillName, player)
      end
    end
  end,
})

local spec = {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Play and
      player:hasSkill(osMingren.name) and
      not player:isKongcheng() and
      #player:getPile("os__duty") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local cids = player.room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = osMingren.name,
        prompt = "#os__mingren-exchange",
      }
    )
    if #cids > 0 then
      event:setCostData(self, cids[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local skillName = osMingren.name
    local room = player.room
    player:addToPile("os__duty", event:getCostData(self), true, skillName)
    room:moveCardTo(
      player:getPile("os__duty")[1],
      Player.Hand,
      player,
      fk.ReasonJustMove,
      skillName,
      "os__duty",
      false,
      player
    )
  end,
}

osMingren:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = spec.can_trigger,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

osMingren:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = spec.can_trigger,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return osMingren
