
local xieshu = fk.CreateSkill {
  name = "ty__xieshu",
  dynamic_desc = function (self, player, lang)
    if player:getMark(self.name) > 0 then
      return "ty__xieshu_update"
    end
  end,
}

Fk:loadTranslationTable {
  ["ty__xieshu"] = "挟术",
  [":ty__xieshu"] = "每回合限一次，你使用牌指定其他角色为目标后，你可以令此牌对其中一个目标无效并获得其一张牌。",

  [":ty__xieshu_update"] = "你使用牌指定其他角色为目标后，你可以令此牌对其中一个目标无效并获得其一张牌。",

  ["#ty__xieshu-choose"] = "挟术：你可以令%arg对其中一个目标无效并获得其一张牌",

  ["$ty__xieshu1"] = "",
  ["$ty__xieshu2"] = "",
}

xieshu:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xieshu.name) and
      data.firstTarget and
      table.find(data.use.tos, function(p)
        return p ~= player
      end) and
      (player:usedSkillTimes(xieshu.name, Player.HistoryTurn) == 0 or player:getMark(xieshu.name) > 0)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(data.use.tos)
    table.removeOne(targets, player)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__xieshu-choose:::"..data.card:toLogString(),
      skill_name = xieshu.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    data:setNullified(to)
    if not to:isNude() then
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = xieshu.name,
      })
      room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, xieshu.name, nil, false, player)
    end
  end,
})

return xieshu
