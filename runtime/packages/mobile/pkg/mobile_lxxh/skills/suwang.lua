local suwang = fk.CreateSkill {
  name = "suwang",
  derived_piles = "$suwang",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("2v2_mode") then
      return "suwang_2v2"
    else
      return "suwang_role_mode"
    end
  end,
}

Fk:loadTranslationTable{
  ["suwang"] = "宿望",
  [":suwang"] = "一名角色的回合结束时，若其于此回合内使用牌时指定过你为目标且你未受到过伤害（若为2v2模式，则改为受到过的伤害值不大于1），" ..
  "则你将牌堆顶一张牌置于你的武将牌上，称为“宿望”；摸牌阶段，若你有“宿望”，则你可以改为获得你的所有“宿望”，然后你可令一名其他角色摸两张牌。",

  [":suwang_role_mode"] = "一名角色的回合结束时，若其于此回合内使用牌时指定过你为目标且你未受到过伤害，" ..
  "则你将牌堆顶一张牌置于你的武将牌上，称为“宿望”；摸牌阶段，若你有“宿望”，则你可以改为获得你的所有“宿望”，然后你可令一名其他角色摸两张牌。",
  [":suwang_2v2"] = "一名角色的回合结束时，若其于此回合内使用牌时指定过你为目标且你受到过的伤害值不大于1，" ..
  "则你将牌堆顶一张牌置于你的武将牌上，称为“宿望”；摸牌阶段，若你有“宿望”，则你可以改为获得你的所有“宿望”，然后你可令一名其他角色摸两张牌。",

  ["$suwang"] = "宿望",
  ["#suwang-invoke"] = "宿望：是否改为获得“宿望”牌，然后可以令一名其他角色摸两张牌",
  ["#suwang-choose"] = "宿望：你可以令一名其他角色摸两张牌",

  ["$suwang1"] = "国治吏和，百姓自存怀化之心。",
  ["$suwang2"] = "居上处事，当极绥怀之人。",
}

suwang:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(suwang.name) and player:getMark("suwang_aimed-turn") > 0 then
      local room = player.room
      if room:isGameMode("2v2_mode") then
        local n = 0
        room.logic:getActualDamageEvents(1, function(e)
          local damage = e.data
          if damage.to == player then
            n = n + damage.damage
          end
          return n > 1
        end)
        return n < 2
      else
        return #room.logic:getActualDamageEvents(1, function(e)
          return e.data.to == player
        end) == 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:addToPile("$suwang", player.room:getNCards(1), false, suwang.name, player)
  end,
})
suwang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(suwang.name) and player.phase == Player.Draw and #player:getPile("$suwang") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = suwang.name,
      prompt = "#suwang-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    room:obtainCard(player, player:getPile("$suwang"), false, fk.ReasonPrey, player, suwang.name)
    if player.dead or #room:getOtherPlayers(player, false) == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = suwang.name,
      prompt = "#suwang-choose",
      cancelable = true,
    })
    if #to > 0 then
      to[1]:drawCards(2, suwang.name)
      return true
    end
  end,
})
suwang:addEffect(fk.CardUsing, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player.room.current == player and #data.tos > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(data.tos) do
      if p:getMark("suwang_aimed-turn") == 0 then
        room:setPlayerMark(p, "suwang_aimed-turn", 1)
      end
    end
  end,
})

return suwang
