local tongdu = fk.CreateSkill {
  name = "mobile__tongdu",
}

Fk:loadTranslationTable{
  ["mobile__tongdu"] = "统度",
  [":mobile__tongdu"] = "每回合限一次，当你成为其他角色使用牌的唯一目标时，你可以令一名角色重铸一张牌。",

  ["#mobile__tongdu-choose"] = "统度：你可以令一名角色重铸一张牌",
  ["#mobile__tongdu-card"] = "统度：请重铸一张牌",

  ["$mobile__tongdu1"] = "辎重调拨，乃国之要务，岂可儿戏！",
  ["$mobile__tongdu2"] = "府库充盈，民有余财，主公师出有名矣。",
}

tongdu:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tongdu.name) and data.from ~= player and
      data:isOnlyTarget(player) and player:usedSkillTimes(tongdu.name, Player.HistoryTurn) == 0 and
      table.find(player.room.alive_players, function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = tongdu.name,
      prompt = "#mobile__tongdu-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = tongdu.name,
      prompt = "#mobile__tongdu-card:"..player.id,
      cancelable = false,
    })
    room:recastCard(cards, to, tongdu.name)
  end,
})

return tongdu
