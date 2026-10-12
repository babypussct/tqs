local qiao = fk.CreateSkill{
  name = "ty_heg__qiao",
}
local H = require "packages.hegemony.util"
qiao:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiao.name) and
      not data.from:isNude() and player:usedSkillTimes(qiao.name, Player.HistoryTurn) < 2
      and not H.compareKingdomWith(data.from, player)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = qiao.name,
      prompt = "#ty_heg__qiao-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askToChooseCard(player, {
      target = data.from,
      flag = "he",
      skill_name = qiao.name,
    })
    room:throwCard(id, qiao.name, data.from, player)
    if not player.dead then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = qiao.name,
        cancelable = false,
      })
    end
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__qiao"] = "气傲",
  [":ty_heg__qiao"] = "每回合限两次，当你成为与你势力不同或未确定势力角色使用牌的目标后，你可弃置其一张牌，然后你弃置一张牌。",

  ["#ty_heg__qiao-invoke"] = "气傲：你可以弃置 %dest 一张牌，然后你弃置一张牌",

  ["$ty_heg__qiao1"] = "吾六十何为不受兵邪？",
  ["$ty_heg__qiao2"] = "芝性骄傲，吾独不为屈。",
}

return qiao
