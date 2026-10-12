
local shensu = fk.CreateSkill({
  name = "m_heg__shensu",
})

Fk:loadTranslationTable{
  ["m_heg__shensu"] = "神速",
  [":m_heg__shensu"] = "你可以做出如下选择：1.跳过判定阶段和摸牌阶段；2.跳过出牌阶段。每选择一项，你视为使用一张无距离限制的普通【杀】。",

  ["#m_heg__shensu1-choose"] = "神速：跳过判定阶段和摸牌阶段，视为使用无距离限制的【杀】",
  ["#m_heg__shensu2-choose"] = "神速：跳过出牌阶段，视为使用无距离限制的【杀】",

  ["$m_heg__shensu1"] = "",
  ["$m_heg__shensu2"] = "",
}

shensu:addEffect(fk.EventPhaseChanging, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shensu.name) and not data.skipped then
      if data.phase == Player.Judge then
        if not player:canSkip(Player.Draw) then return end
      elseif data.phase == Player.Play then
      else
        return
      end
      return table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canUseTo(Fk:cloneCard("slash"), p, { bypass_distances = true, bypass_times = true })
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local slash = Fk:cloneCard("slash")
    local max_num = slash.skill:getMaxTargetNum(player, slash)
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:canUseTo(slash, p, { bypass_distances = true, bypass_times = true })
    end)
    if data.phase == Player.Judge then
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = max_num,
        targets = targets,
        skill_name = shensu.name,
        prompt = data.phase == Player.Judge and "#m_heg__shensu1-choose" or "#m_heg__shensu2-choose",
        cancelable = true,
      })
      if #tos > 0 then
        room:sortByAction(tos)
        event:setCostData(self, { tos = tos })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.skipped = true
    if data.phase == Player.Judge then
      player:skip(Player.Draw)
    end
    room:useVirtualCard("slash", nil, player, event:getCostData(self).tos, shensu.name, true)
  end,
})

shensu:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    local player = ai.player
    local card = Fk:cloneCard("slash")
    card.skillName = shensu.name
    local max_num = card.skill:getMaxTargetNum(player, card)
    return ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 0,
      max_num = max_num,
      skill_name = shensu.name,
      benefit_func = function (logic, p)
        logic:useCard({
          from = player,
          tos = { p },
          card = card,
          extraUse = true,
        })
      end,
      basic_benefit = -ai:getBenefitOfEvents(function(logic)
        if true then
          logic:drawCards(ai.player, 2, "phase_draw")
        end
      end),
    })
  end,
})

return shensu
