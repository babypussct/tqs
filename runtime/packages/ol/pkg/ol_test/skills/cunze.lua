
local cunze = fk.CreateSkill{
  name = "cunze",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["cunze"] = "存择",
  [":cunze"] = "锁定技，所有角色的【桃】双倍计入手牌上限。"..
  "结束阶段，你选择一名角色并摸X张牌（X为其手牌中【桃】的数量）。"..
  "直到你下回合开始，其进入濒死状态时，若为首次，其回复体力至1点，否则本次濒死结算中你不能使用【桃】。",

  ["#cunze-choose"] = "存择：选择一名角色，摸其手牌中【桃】数的牌，其下次进入濒死状态时回复体力至1点",
  ["@@cunze"] = "存择",

  ["$cunze1"] = "",
  ["$cunze2"] = "",
}

cunze:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cunze.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = cunze.name,
      prompt = "#cunze-choose",
      cancelable = true,
    })[1]
    room:addTableMarkIfNeed(to, "@@cunze", player)
    local n = #table.filter(to:getCardIds("h"), function (id)
      return Fk:getCardById(id).trueName == "peach"
    end)
    if n > 0 then
      player:drawCards(n, cunze.name)
    end
  end,
})

cunze:addEffect(fk.EnterDying, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return table.contains(target:getTableMark("@@cunze"), player) and target.hp < 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room:addTableMarkIfNeed(target, cunze.name, player) then
      room:recover{
        who = target,
        num = 1 - target.hp,
        recoverBy = target,
        skillName = cunze.name,
      }
    else
      local dying = room.logic:getCurrentEvent():findParent(GameEvent.Dying)
      if dying then
        room:setPlayerMark(player, "cunze-tmp", target.id)
        dying:addCleaner(function ()
          room:setPlayerMark(player, "cunze-tmp", 0)
        end)
      end
    end
  end,
})

cunze:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return from and to and card and card.trueName == "peach" and from:getMark("cunze-tmp") == to.id
  end,
})

cunze:addEffect("maxcards", {  --FIXME
  correct_func = function (self, player)
    if player.phase == Player.Discard and
      table.find(Fk:currentRoom().alive_players, function (p)
        return p:hasSkill(cunze.name)
      end) then
      local n = 0
      for _, id in ipairs(player:getCardIds("h")) do
        if Fk:getCardById(id).trueName == "peach" then
          local yes = false
          for _, sk in ipairs(Fk:currentRoom().status_skills[MaxCardsSkill] or Util.DummyTable) do
            if sk ~= self and sk:excludeFrom(player, Fk:getCardById(id)) then
              yes = true
              break
            end
          end
          if not yes then
            n = n + 1
          end
        end
      end
      return -n
    end
  end,
})

cunze:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      room:removeTableMark(p, "@@cunze", player)
      room:removeTableMark(p, cunze.name, player)
    end
  end,
})

return cunze
