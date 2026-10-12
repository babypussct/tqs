
local mingren = fk.CreateSkill({
  name = "os_mou__mingren",
  derived_piles = { "$os_mou__duty" },
})

Fk:loadTranslationTable{
  ["os_mou__mingren"] = "明任",
  [":os_mou__mingren"] = "游戏开始时，你摸三张牌，然后将一张手牌扣置于你的武将牌上，称为“任”。结束阶段，你可以用手牌替换“任”。",

  ["$os_mou__duty"] = "任",
  ["#os_mou__mingren-put"] = "明任：请将一张手牌置于武将牌上",
  ["#os_mou__mingren-exchange"] = "明任：你可以用一张手牌替换“任”（%arg）",

  ["$os_mou__mingren1"] = "父不爱无益之子，君不蓄无用之臣！",
  ["$os_mou__mingren2"] = "老夫蒙国重恩，敢不捐躯以报！",
}

mingren:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mingren.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, mingren.name)
    if not player:isKongcheng() then
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        skill_name = mingren.name,
        cancelable = false,
        prompt = "#os_mou__mingren-put",
      })
      player:addToPile("$os_mou__duty", card, false, mingren.name)
    end
  end,
})

mingren:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(mingren.name) and
      target == player and
      player.phase == Player.Finish and
      not player:isKongcheng() and
      #player:getPile("$os_mou__duty") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = mingren.name,
      prompt = "#os_mou__mingren-exchange:::" .. Fk:getCardById(player:getPile("$os_mou__duty")[1]):toLogString()
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCards({
      ids = event:getCostData(self).cards,
      from = player,
      to = player,
      toArea = Player.Special,
      moveReason = fk.ReasonExchange,
      specialName = "$os_mou__duty",
      skillName = mingren.name,
      proposer = player,
    }, {
      ids = player:getPile("$os_mou__duty"),
      from = player,
      to = player,
      toArea = Player.Hand,
      moveReason = fk.ReasonExchange,
      skillName = mingren.name,
      proposer = player,
    })
  end,
})

return mingren
