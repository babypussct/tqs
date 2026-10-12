local fenming = fk.CreateSkill {
  name = "os__fenming",
}

Fk:loadTranslationTable{
  ["os__fenming"] = "奋命",
  [":os__fenming"] = "准备阶段，你可以选择一名角色并选择一项：1.弃置其一张牌；2.其进入连环状态；背水：你进入连环状态。",

  ["os__fenming_discard"] = "弃置一名角色一张牌",
  ["os__fenming_chained"] = "令一名角色进入连环状态",
  ["os__fenming_beishui"] = "背水：你进入连环状态",

  ["$os__fenming1"] = "东吴男儿，岂是贪生怕死之辈。",
  ["$os__fenming2"] = "不惜性命，也要保主公周全。",
}

fenming:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(fenming.name) and player.phase == Player.Start and
      table.find(player.room.alive_players, function(p)
        return not p:isNude() or not p.chained
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "os__fenming_active",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    if choice ~= "os__fenming_chained" then
      if to == player then
        room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = fenming.name,
          cancelable = false,
        })
      else
        local card = room:askToChooseCard(player, {
          target = to,
          flag = "he",
          skill_name = fenming.name
        })
        room:throwCard(card, fenming.name, to, player)
      end
      if player.dead or to.dead then return end
    end
    if choice ~= "os__fenming_discard" and not to.chained then
      to:setChainState(true)
    end
    if choice == "os__fenming_beishui" and not player.chained and not player.dead then
      player:setChainState(true)
    end
  end,
})

return fenming
