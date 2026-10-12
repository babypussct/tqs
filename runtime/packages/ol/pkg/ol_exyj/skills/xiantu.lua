local xiantu = fk.CreateSkill {
  name = "ol_ex__xiantu",
}

Fk:loadTranslationTable{
  ["ol_ex__xiantu"] = "献图",
  [":ol_ex__xiantu"] = "其他角色出牌阶段开始时，你可以摸至多两张牌，然后交给其等量的牌。此阶段结束时，若其于此阶段内"..
  "造成的伤害小于你以此法交给其的牌数，你失去1点体力。",

  ["#ol_ex__xiantu-invoke"] = "献图：你可以摸至多两张牌并交给 %dest 等量的牌",
  ["#ol_ex__xiantu-give"] = "献图：请交给 %dest %arg张牌",
  ["@ol_ex__xiantu-phase"] = "献图",

  ["$ol_ex__xiantu1"] = "既入汉中，皇叔得川乃是天意。",
  ["$ol_ex__xiantu2"] = "入川在即，皇叔何拒吾等仁义之谏？",
}

xiantu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xiantu.name) and target.phase == Player.Play and
      not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = room:askToNumber(player, {
      skill_name = xiantu.name,
      prompt = "#ol_ex__xiantu-invoke::"..target.id,
      min = 1,
      max = 2,
      cancelable = true,
    })
    if n then
      event:setCostData(self, { tos = { target }, choice = n })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).choice
    player:drawCards(n, xiantu.name)
    if player:isNude() or target.dead then return end
    local cards = room:askToCards(player, {
      skill_name = xiantu.name,
      include_equip = true,
      min_num = n,
      max_num = n,
      prompt = "#ol_ex__xiantu-give::"..target.id..":"..n,
      cancelable = false,
    })
    room:setPlayerMark(player, "@ol_ex__xiantu-phase", #cards)
    room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, xiantu.name, nil, false, player)
  end,
})

xiantu:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player and target.phase == Player.Play and
      player:getMark("@ol_ex__xiantu-phase") > 0 and
      not player.dead then
      local n = 0
      player.room.logic:getActualDamageEvents(1, function(e)
        if e.data.from == target then
          n = n + e.data.damage
        end
      end, Player.HistoryPhase)
      return n < player:getMark("@ol_ex__xiantu-phase")
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, xiantu.name, player)
  end,
})

return xiantu
