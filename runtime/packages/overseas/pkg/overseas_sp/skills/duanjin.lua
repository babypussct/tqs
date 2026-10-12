local duanjin = fk.CreateSkill {
  name = "os__duanjin",
}

Fk:loadTranslationTable{
  ["os__duanjin"] = "断津",
  [":os__duanjin"] = "当你使用一张基本牌结算完毕后，你可以弃置一名其他角色的一张牌。",

  ["#os__duanjin-choose"] = "断津：你可以弃置一名其他角色一张牌",

  ["$os__duanjin1"] = "如此若瓮中捉鳖，孙权十万之众可破也。",
  ["$os__duanjin2"] = "张将军夜袭敌营，吾引兵断其归路。",
}

---@param room AbstractRoom
---@param player Player
---@param friend string
---@return boolean
local function HeyuFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
    not not table.find(room.alive_players, function (p)
      return p.role == player.role and (p.general:endsWith(friend) or p.deputyGeneral:endsWith(friend))
    end)
end

duanjin:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duanjin.name) and
      data.card.type == Card.TypeBasic and
      table.find(player.room.alive_players, function(p) return p ~= player and not p:isNude() end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return p ~= player and not p:isNude() end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = duanjin.name,
      prompt = "#os__duanjin-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = duanjin.name,
    })
    room:throwCard(card, duanjin.name, to, player)
    if HeyuFriend(player.room, player, "thoroughbred__yuejin") and player:hasSkill("lidian__heyu") and
      room:getCardArea(card) == Card.DiscardPile then
        room:notifySkillInvoked(player, "lidian__heyu")
        player:addSkillUseHistory("lidian__heyu", 1)
        room:obtainCard(player, card, true, fk.ReasonPrey, player, "lidian__heyu")
    end
  end,
})

return duanjin
