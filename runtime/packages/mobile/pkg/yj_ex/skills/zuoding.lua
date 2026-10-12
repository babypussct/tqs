
local zuoding = fk.CreateSkill {
  name = "mobile__zuoding",
}

Fk:loadTranslationTable{
  ["mobile__zuoding"] = "佐定",
  [":mobile__zuoding"] = "其他角色于其出牌阶段内使用♠牌指定目标后，若你或此牌有目标未于此阶段内受到过伤害，你可以令其中一名目标摸一张牌。",

  ["$mobile__zuoding1"] = "辅世长民，为臣之本！",
  ["$mobile__zuoding2"] = "飞鸿羽翼，为君展骥！",
}

zuoding:addEffect(fk.TargetSpecified, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zuoding.name) and target ~= player and
      target.phase == Player.Play and data.firstTarget and data.card.suit == Card.Spade and
      table.find(data.use.tos, function(p)
        return not p.dead
      end) and
      table.find(table.connect({ player }, data.use.tos), function (p)
        return #player.room.logic:getActualDamageEvents(1, function (e)
          return e.data.to == p
        end, Player.HistoryPhase) == 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      skill_name = zuoding.name,
      min_num = 1,
      max_num = 1,
      targets = data.use.tos,
      prompt = "#zuoding-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(1, zuoding.name)
  end,
})

return zuoding
