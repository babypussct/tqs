local xiezheng = fk.CreateSkill {
  name = "mobile__xiezheng",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("role_mode") then
      if player:getMark("mobile__xiezheng_update") > 0 then
        return "mobile__xiezheng_role_mode2"
      else
        return "mobile__xiezheng_role_mode"
      end
    elseif Fk:currentRoom():isGameMode("1v2_mode") then
      return "mobile__xiezheng_1v2"
    else
      return "mobile__xiezheng_2v2"
    end
  end,
}

Fk:loadTranslationTable{
  ["mobile__xiezheng"] = "挟征",
  [":mobile__xiezheng"] = "结束阶段，你可以令至多一名角色（若为斗地主模式，改为两名，本局游戏限一次）依次将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】（若为身份模式，优先指定同势力角色为目标），结算后若未造成过伤害，你失去1点体力。",

  [":mobile__xiezheng_role_mode"] = "结束阶段，你可以令一名角色将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】（需优先指定同势力角色为目标），结算后若未造成过伤害，你失去1点体力。",
  [":mobile__xiezheng_role_mode2"] = "结束阶段，你可以令一名角色将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】，结算后若未造成过伤害，你失去1点体力。",
  [":mobile__xiezheng_1v2"] = "每局游戏限一次，结束阶段，你可以令至多两名角色依次将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】，结算后若未造成过伤害，你失去1点体力。",
  [":mobile__xiezheng_2v2"] = "结束阶段，你可以令一名角色将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】，结算后若未造成过伤害，你失去1点体力。",

  ["#mobile__xiezheng-choose"] = "挟征：令至多%arg名角色随机一张手牌置于牌堆顶，你视为使用一张%arg2【兵临城下】！",
  ["#mobile__xiezheng-use"] = "挟征：视为使用一张【兵临城下】！若未造成伤害，你失去1点体力",
  ["mobile__xiezheng_debuff"] = "优先指定同势力角色为目标的",

  ["$mobile__xiezheng1"] = "臣请陛下亲讨乱贼，以昭帝威！",
  ["$mobile__xiezheng2"] = "天子亲征，淮南之乱，不日可平！",
}

xiezheng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player.room:isGameMode("1v2_mode") and player:usedSkillTimes(xiezheng.name, Player.HistoryGame) > 0 then return false end
    return target == player and player:hasSkill(xiezheng.name) and player.phase == Player.Finish and
      table.find(player.room.alive_players, function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng()
    end)
    local num = room:isGameMode("1v2_mode") and 2 or 1
    local debuff = " "
    if room:isGameMode("role_mode") and player:getMark("mobile__xiezheng_update") == 0 then
      debuff = ":mobile__xiezheng_debuff"
    end
    local prompt = "#mobile__xiezheng-choose:::"..num..":"..debuff
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = num,
      targets = targets,
      skill_name = xiezheng.name,
      prompt = prompt,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead and not p:isKongcheng() then
        room:moveCards({
          ids = room:tableRandomPick(p:getCardIds("h"), 1),
          from = p,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = xiezheng.name,
        })
      end
    end
    if player.dead then return end
    local extra_data = {}
    if room:isGameMode("role_mode") and player:getMark("mobile__xiezheng_update") == 0 then
      local must_targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return p.kingdom == player.kingdom
      end)
      if #must_targets > 0 then
        extra_data.must_targets = table.map(must_targets, Util.IdMapper)
      end
    end
    local use = room:askToUseVirtualCard(player, {
      name = "mobile__enemy_at_the_gates",
      skill_name = xiezheng.name,
      prompt = "#mobile__xiezheng-use",
      cancelable = false,
      extra_data = extra_data,
    })
    if use and not player.dead and not (use.extra_data and use.extra_data.mobile__xiezheng_damageDealt) then
      room:loseHp(player, 1, xiezheng.name)
    end
  end,
})
xiezheng:addEffect(fk.CardUseFinished, {
  can_refresh = function (self, event, target, player, data)
    return
      target == player and
      data.card and
      data.card.trueName == "slash" and
      (data.extra_data or {}).useByEnemyAtGate and
      data.damageDealt
  end,
  on_refresh = function (self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent().parent
    while e do
      if e.event == GameEvent.UseCard then
        local use = e.data
        if use.card.name == "mobile__enemy_at_the_gates" and table.contains(use.card.skillNames, xiezheng.name) then
          use.extra_data = use.extra_data or {}
          use.extra_data.mobile__xiezheng_damageDealt = true
          return
        end
      end
      e = e.parent
    end
  end,
})

xiezheng:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    return ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 0,
      max_num = Fk:currentRoom():isGameMode("1v2_mode") and 2 or 1,
      skill_name = self.skill_name,
      benefit_func = function (logic, p)
        logic:moveCardTo(table.random(p:getCardIds("h")), Card.DrawPile, nil, fk.ReasonPut, self.skill_name, nil, false)
      end,
      basic_benefit = ai:getBenefitOfEvents(function(logic)
        local targets = Fk:cloneCard("mobile__enemy_at_the_gates", nil, nil, self.skill_name):getAvailableTargets(ai.player)
        if Fk:currentRoom():isGameMode("role_mode") and ai.player:getMark("mobile__xiezheng_update") == 0 then
          local must_targets = table.filter(targets, function (p)
            return p.kingdom == ai.player.kingdom
          end)
          if #must_targets > 0 then
            targets = must_targets
          end
        end
        if #targets > 0 then
          local ret, benefit = nil, -100000
          for _, p in ipairs(targets) do
            local v = ai:getBenefitOfEvents(function(logic2)
              logic2:useCard{
                from = ai.player,
                tos = { p },
                card = Fk:cloneCard("mobile__enemy_at_the_gates", nil, nil, self.skill_name),
              }
            end)
            if v > benefit then
              ret, benefit = p, v
            end
          end
          if ret then
            logic:useCard{
              from = ai.player,
              tos = { ret },
              card = Fk:cloneCard("mobile__enemy_at_the_gates", nil, nil, self.skill_name),
            }
          end
        end
      end),
    })
  end,
})

return xiezheng
