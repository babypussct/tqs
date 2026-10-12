local duanjin = fk.CreateSkill {
  name = "duanjin",
}

Fk:loadTranslationTable{
  ["duanjin"] = "断津",
  [":duanjin"] = "当你使用一张基本牌结算完毕后，你可以弃置一名本回合使用过牌的其他角色的一张牌。",

  ["#duanjin-choose"] = "断津：你可以弃置其中一名角色一张牌",

  ["$duanjin1"] = "此桥乃吴军退路要害，断之则已握胜机。",
  ["$duanjin2"] = "分兵毁桥，阻援绝路，必可全胜而归。",
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
    if target == player and player:hasSkill(duanjin.name) and
      data.card.type == Card.TypeBasic then
      local targets = {}
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        if e.data.from ~= player and not e.data.from:isNude() then
          table.insertIfNeed(targets, e.data.from)
        end
      end, Player.HistoryTurn)
      if #targets > 0 then
        event:setCostData(self, { extra_data = targets })
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = event:getCostData(self).extra_data,
      skill_name = duanjin.name,
      prompt = "#duanjin-choose",
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
