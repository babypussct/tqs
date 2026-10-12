local skill = fk.CreateSkill{
  name = "alliance_feast_skill",
}

local H = require "packages.hegemony.util"

Fk:loadTranslationTable{
  ["alliance_feast"] = "联军盛宴",
  [":alliance_feast"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：有势力的你和除你的势力外的一个势力的所有角色<br/>"..
  "<b>效果</b>：若目标角色：为你，你选择一项：1.回复X点体力；2.摸X张牌（X为该势力存活角色数）；不为你，其摸一张牌并重置武将牌。",

  ["alliance_feast_skill"] = "联军盛宴",
  ["alliance_feast_draw"] = "摸%arg张牌",
  ["alliance_feast_recover"] = "回复%arg点体力",
  ["#alliance_feast_skill"] = "选择一个其他势力的所有角色，你选择回复体力或摸牌，这些角色各摸一张牌并重置",
  ["#alliance_feast"] = "你选择回复%arg点体力或摸%arg张牌，目标势力角色各摸一张牌并重置",
}

skill:addEffect("cardskill", {
  prompt = function (self, player, selected_cards, selected_targets, extra_data)
    if #selected_targets == 0 then
      return "#alliance_feast_skill"
    elseif #selected_targets == 1 then
      local num = #table.filter(Fk:currentRoom().alive_players, function (p)
        return H.compareKingdomWith(p, selected_targets[1])
      end)
      return "#alliance_feast:::"..num
    end
  end,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if #selected == 0 then
      return
    else
      if H.compareKingdomWith(to_select, selected[1]) then
        return "draw1"
      else
        return
      end
    end
  end,
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card, extra_data)
    if to_select == player then return true end
    if to_select.kingdom == "unknown" then return false end
    if #selected == 0 then
      return H.compareKingdomWith(to_select, player, true)
    end
    local target = selected[1]
    return H.compareKingdomWith(to_select, target)
  end,
  target_filter = function(self, player, to_select, selected, _, card, extra_data)
    return #selected == 0 and to_select ~= player and Util.CardTargetFilter(self, player, to_select, selected, _, card, extra_data)
  end,
  can_use = function(self, player, card)
    return not (player:prohibitUse(card) or player:isProhibited(player, card)) and player.kingdom ~= "unknown"
  end,
  on_use = function(self, room, use)
    local card = use.card
    local player = use.from
    local kingdom
    if use.tos and #use.tos > 0 then
      if not player:isProhibited(player, card) then
        use:addTarget(use.from)
      end
      for _, _p in ipairs(use.tos) do
        if _p ~= use.from then
          kingdom = H.getKingdom(_p)
          for _, p in ipairs(room:getAlivePlayers()) do
            if H.compareKingdomWith(p, _p) and p ~= _p and player:canUseTo(use.card, p) then
              use:addTarget(p)
            end
          end
          break
        end
      end
    elseif not player:isProhibited(player, card) then
      use.tos = { use.from }
    end
    use.extra_data = use.extra_data or {}
    use.extra_data.AFTargetKingdom = kingdom
  end,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if from == to then
      local num = H.getSameKingdomPlayersNum(room, nil, (effect.extra_data or {}).AFTargetKingdom)
      local choices = { "alliance_feast_recover:::"..num, "alliance_feast_draw:::"..num }
      local choice =  room:askToChoice(from, {
        choices = choices,
        skill_name = skill.name,
      })
      if choice:startsWith("alliance_feast_recover") then
        room:recover{
          who = from,
          recoverBy = from,
          card = effect.card,
          num = num,
          skillName = skill.name,
        }
      else
        from:drawCards(num, skill.name)
      end
    else
      to:drawCards(1, skill.name)
      if to.chained then
        to:setChainState(false)
      end
    end
  end,
})

return skill
