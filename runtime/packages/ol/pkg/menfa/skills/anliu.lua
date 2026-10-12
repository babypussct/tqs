
local anliu = fk.CreateSkill {
  name = "anliu",
}

Fk:loadTranslationTable{
  ["anliu"] = "暗流",
  [":anliu"] = "你受到伤害后，你可以令至多X名角色各弃置一张牌，然后你摸X张牌（X为与你手牌数相同的角色数且至多为5）。",

  ["#anliu-choose"] = "暗流：你可以令至多%arg名角色各弃置一张牌，然后你摸与你手牌数相同角色数张牌",

  ["$anliu1"] = "",
  ["$anliu2"] = "",
}

anliu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(anliu.name) and
      table.find(player.room.alive_players, function (p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isNude()
    end)
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if p:getHandcardNum() == player:getHandcardNum() then
        n = n + 1
      end
    end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = n,
      prompt = "#anliu-choose:::"..n,
      skill_name = anliu.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos or {}
    for _, p in ipairs(tos) do
      room:askToDiscard(p, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = anliu.name,
        cancelable = false,
      })
    end
    if not player.dead then
      local n = 0
      for _, p in ipairs(room.alive_players) do
        if p:getHandcardNum() == player:getHandcardNum() then
          n = n + 1
        end
      end
      player:drawCards(n, anliu.name)
    end
  end,
})

return anliu
