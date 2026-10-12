local skill = fk.CreateSkill{
  name = "fight_together_skill",
}

local H = require "packages.hegemony.util"

Fk:loadTranslationTable{
  ["fight_together"] = "勠力同心",
  [":fight_together"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：所有大势力角色或所有小势力角色<br/>"..
  "<b>效果</b>：若目标角色：不处于连环状态，其横置；处于连环状态，其摸一张牌。",

  ["#fight_together_skill"] = "选择所有大势力角色或小势力角色，处于连环状态者摸一张牌，不处于连环状态者横置",
  ["big_kingdom"] = "大势力",
  ["small_kingdom"] = "小势力",
}

skill:addEffect("cardskill", {
  prompt = "#fight_together_skill",
  target_num = 1,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if #selected == 0 then
      if not selectable then return end
      if H.isBigKingdomPlayer(to_select) then
        return "big_kingdom"
      end
      if H.isSmallKingdomPlayer(to_select) then
        return "small_kingdom"
      end
    elseif #selected == 1 then
      if H.isBigKingdomPlayer(selected[1]) and H.isBigKingdomPlayer(to_select) then
        if to_select.chained then
          return "draw1"
        else
          return "chained"
        end
      elseif H.isSmallKingdomPlayer(selected[1]) and H.isSmallKingdomPlayer(to_select) then
        if to_select.chained then
          return "draw1"
        else
          return "chained"
        end
      end
    end
  end,
  mod_target_filter = function(self, player, to_select, selected, card, distance_limited)
    if table.every(Fk:currentRoom().alive_players, function(p) return not H.isBigKingdomPlayer(p) end) then return false end
    if #selected == 0 then
      return true
    else
      return H.isBigKingdomPlayer(selected[1]) == H.isBigKingdomPlayer(to_select)
    end
  end,
  target_filter = Util.CardTargetFilter,
  can_use = function(self, player, card)
    return not player:prohibitUse(card) and table.find(Fk:currentRoom().alive_players, function(p)
      return H.isBigKingdomPlayer(p) end)
  end,
  on_use = function(self, room, use)
    if use.tos and #use.tos > 0 then -- 如果一开始的目标被取消了就寄了，还是需要originalTarget
      local player = use.from
      local target = use.tos[1]
      local bigKingdom, smallKingdom = H.isBigKingdomPlayer(target), H.isSmallKingdomPlayer(target)
      if bigKingdom then
        for _, p in ipairs(room:getAlivePlayers()) do
          if H.isBigKingdomPlayer(p) and p ~= target and not player:isProhibited(p, use.card) then
            use:addTarget(p)
          end
        end
      end
      if smallKingdom then
        for _, p in ipairs(room:getAlivePlayers()) do
          if H.isSmallKingdomPlayer(p) and p ~= target and not player:isProhibited(p, use.card) then
            use:addTarget(p)
          end
        end
      end
    end
  end,
  on_effect = function(self, room, cardEffectEvent)
    local to = cardEffectEvent.to
    if to.chained then
      to:drawCards(1, "fight_together")
    else
      to:setChainState(true)
    end
  end,
})

skill:addTest(function(room, me)
  local comp2 = room.players[2]
  local card = Fk:cloneCard("fight_together")
  if table.find(Fk:currentRoom().alive_players, function(p)
    return H.isBigKingdomPlayer(p)
  end) then
    lu.assertIsTrue(me:canUseTo(card, comp2))
  end
  FkTest.runInRoom(function()
    comp2:setChainState(true)
    room:useCard {
      from = me,
      card = card,
      tos = { comp2 },
    }
  end)
  if H.isSmallKingdomPlayer(comp2) then
    for _, p in ipairs(room.alive_players) do
      if H.isSmallKingdomPlayer(p) then
        lu.assertIsTrue(p.chained)
      end
    end
  end
  if H.isBigKingdomPlayer(comp2) then
    for _, p in ipairs(room.alive_players) do
      if H.isBigKingdomPlayer(p) then
        lu.assertIsTrue(p.chained)
      end
    end
  end
  lu.assertEquals(comp2:getHandcardNum(), 1)
end)

return skill
