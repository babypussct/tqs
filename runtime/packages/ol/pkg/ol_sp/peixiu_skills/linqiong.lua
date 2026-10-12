local linqiong = fk.CreateSkill {
  name = "peixiu_linqiong",
}

Fk:loadTranslationTable {
  ["peixiu_linqiong"] = "临邛",
  [":peixiu_linqiong"] = "你获得此技能后，可以令任意名角色同时弃置一张牌。",

  ["#peixiu_linqiong-choose"] = "临邛：令任意名角色同时弃置一张牌",
}

linqiong:addEffect(fk.EventAcquireSkill, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(linqiong.name) and data.skill.name == linqiong.name and
      table.find(player.room.alive_players, function (p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isNude()
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #targets,
      skill_name = linqiong.name,
      cancelable = true,
      prompt = "#peixiu_linqiong-choose",
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos or {}
    local result = room:askToJointCards(player, {
      players = targets,
      min_num = 1,
      max_num = 1,
      include_equip = true,
      cancelable = false,
      skill_name = linqiong.name,
      prompt = "#AskForDiscard:::1:1",
      will_throw = true,
    })
    local moves = {}
    for _, p in ipairs(targets) do
      if #result[p] > 0 then
        table.insert(moves, {
          ids = result[p],
          from = p,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = p,
          skillName = linqiong.name,
        })
      end
    end
    if #moves == 0 then return end
    room:moveCards(table.unpack(moves))
  end
})

return linqiong
