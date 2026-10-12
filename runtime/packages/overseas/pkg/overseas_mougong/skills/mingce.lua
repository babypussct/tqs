
local mouMingce = fk.CreateSkill({
  name = "os_mou__mingce",
})

Fk:loadTranslationTable{
  ["os_mou__mingce"] = "明策",
  [":os_mou__mingce"] = "出牌阶段各限一次，你可以将一张牌交给一名其他角色，然后其选择一项：（每阶段第二次发动时摸牌数-1）"..
  "1.失去1点体力，令你摸三张牌并获得1个“策”标记；2.摸两张牌。<br>"..
  "出牌阶段开始时，若你拥有“策”标记，你可以选择一名其他角色，对其造成X点伤害并移去所有“策”标记（X为你拥有的“策”标记数）。",

  ["#os_mou__mingce"] = "明策：交给一名角色一张牌，其选择失去体力令你摸%arg张牌，或其摸%arg2张牌",
  ["os_mou__mingce_losehp"] = "失去1点体力，令 %src 摸%arg张牌并获得“策”标记",
  ["#os_mou__mingce-choose"] = "明策：移去所有“策”标记，对一名其他角色造成 %arg 点伤害",
  ["@os_mou__mingce"] = "策",
  ["@os_mou__mingce-phase"] = "明策已选",

  ["$os_mou__mingce1"] = "既有可乘之隙，何必失此良机？",
  ["$os_mou__mingce2"] = "今敌军远来疲惫，将军可速战之。",
}

mouMingce:addEffect("active", {
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = function(self, player)
    local nums = player:usedEffectTimes(self.name, Player.HistoryPhase) == 1 and {1, 2} or {2, 3}
    return "#os_mou__mingce:::" .. nums[2] .. ":" .. nums[1]
  end,
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) < 2 and not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local skillName = mouMingce.name
    local player = effect.from
    local target = effect.tos[1]
    room:obtainCard(target, effect.cards[1], false, fk.ReasonGive, player, skillName)
    if player.dead or target.dead then return end
    local nums = player:usedEffectTimes(self.name, Player.HistoryPhase) == 2 and {1, 2} or {2, 3}
    local choices = {"os_mou__mingce_losehp:" .. player.id .. "::" .. nums[2], "draw" .. nums[1]}
    if player:getMark("@os_mou__mingce-phase") ~= 0 then
      table.remove(choices, player:getMark("@os_mou__mingce-phase"))
    end
    local choice = room:askToChoice(target, { choices = choices, skill_name = skillName })
    if player:getMark("@os_mou__mingce-phase") == 0 then
      room:setPlayerMark(player, "@os_mou__mingce-phase", table.indexOf(choices, choice))
    else
      room:setPlayerMark(player, "@os_mou__mingce-phase", 0)
    end
    if choice:startsWith("draw") then
      target:drawCards(nums[1], skillName)
    else
      room:loseHp(target, 1, skillName)
      if not player.dead then
        player:drawCards(nums[2], skillName)
        room:addPlayerMark(player, "@os_mou__mingce")
      end
    end
  end,
})

mouMingce:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mouMingce.name) and player.phase == Player.Play and player:getMark("@os_mou__mingce") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#os_mou__mingce-choose:::" .. player:getMark("@os_mou__mingce"),
        skill_name = mouMingce.name,
        cancelable = true
      }
    )

    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = mouMingce.name
    player:broadcastSkillInvoke(skillName)
    local to = event:getCostData(self)
    room:damage { from = player, to = to, damage = player:getMark("@os_mou__mingce"), skillName = skillName }
    room:setPlayerMark(player, "@os_mou__mingce", 0)
  end,
})

return mouMingce
