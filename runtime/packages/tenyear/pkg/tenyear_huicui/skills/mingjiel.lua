local mingjie = fk.CreateSkill {
  name = "mingjiel",
}

Fk:loadTranslationTable{
  ["mingjiel"] = "明节",
  [":mingjiel"] = "游戏开始，你选择一名其他角色，你与其获得对方因为弃牌阶段弃置的牌，"..
  "你或其的阶段被跳过时各摸两张牌并可以令对方防止下次受到的伤害。所选角色阵亡时，你立即阵亡。",

  ["#mingjiel-choose"] = "明节：选择一名其他角色",
  ["@@mingjiel"] = "明节",
  ["#mingjiel-defensive"] = "明节：是否令 %dest 防止下次受到的伤害？",

  ["$mingjiel1"] = "今国破家亡，妾岂牵此羊！",
  ["$mingjiel2"] = "锦官花谢，当以颈血溅之。",
}

mingjie:addEffect(fk.GameStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mingjie.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = room:getOtherPlayers(player, false)
    if #tos > 0 then
      tos = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 1,
        prompt = "#mingjiel-choose",
        skill_name = mingjie.name,
        cancelable = false,
      })
    end
    --所有角色可见
    room:setPlayerMark(player, mingjie.name, tos[1])
    room:setPlayerMark(tos[1], "@@mingjiel", 1)
  end,
})

mingjie:addEffect(fk.EventPhaseChanging, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(mingjie.name) then
      local to = player:getMark(mingjie.name)
      if to == 0 or to.dead then return end
      --只计算额定阶段
      if (target == player or target == to) and data.reason == "game_rule" then
        local mark = player:getTableMark("mingjie_phases-turn")
        local phases = {}
        local current_turn = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
        if current_turn then
          for i = 1, current_turn.data.phase_index, 1 do
            local phase_data = current_turn.data.phase_table[i]
            local phase = phase_data.phase
            if phase_data.reason == "game_rule" and phase_data.skipped and not table.contains(mark, phase) then
              table.insertIfNeed(phases, phase)
            end
          end
        end
        if #phases > 0 then
          event:setCostData(self, { extra_data = phases })
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local phases = event:getCostData(self).extra_data
    local mark = player:getTableMark("mingjie_phases-turn")
    table.insertTable(mark, phases)
    room:setPlayerMark(player, "mingjie_phases-turn", mark)

    --神秘设定，在这里恢复娴辅的选项
    mark = player:getTableMark("xianful")
    for _, phase in ipairs(phases) do
      table.removeOne(mark, phase)
    end
    room:setPlayerMark(player, "xianful", mark)

    local x = #phases * 2
    --固定你先摸牌
    player:drawCards(x, mingjie.name)
    --摸2途中失去技能了如何？
    local to = player:getMark(mingjie.name)
    if to ~= 0 and not to.dead then
      to:drawCards(x, mingjie.name)
    end
    if not (player.dead or target.dead) then
      local dest = (target == player) and to or player
      --标记不可见
      mark = player:getTableMark("mingjiel_defensive")
      if not table.contains(mark, dest) and room:askToSkillInvoke(target, {
        skill_name = mingjie.name,
        prompt = "#mingjiel-defensive::"..dest.id,
      }) then
        table.insert(mark, dest)
        room:setPlayerMark(player, "mingjiel_defensive", mark)
      end
    end
  end,
})

mingjie:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mingjie.name) and table.contains(player:getTableMark("mingjiel_defensive"), target)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:removeTableMark(player, "mingjiel_defensive", target)
    data:preventDamage()
  end,
})

--同立世
mingjie:addEffect(fk.BeforeCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(mingjie.name) then
      local src = player:getMark(mingjie.name)
      if src == 0 or src.dead then return end
      local current = player.room.current
      if current.phase ~= Player.Discard then return end
      if current == src then
        src = player
      elseif current ~= player then
        return
      end
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == current and move.toArea == Card.DiscardPile and
          move.moveReason == fk.ReasonDiscard and move.skillName == "phase_discard" then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insert(cards, info.cardId)
            end
          end
        end
      end
      if #cards > 0 then
        event:setCostData(self, { cards = cards, tos = { src } })
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local handcards = room.current:getCardIds("h")
    local cards = table.filter(event:getCostData(self).cards, function(id)
      return table.contains(handcards, id)
    end)
    if #cards > 0 then
      local to = event:getCostData(self).tos[1]
      room:obtainCard(to, cards, false, (to == player) and fk.ReasonPrey or fk.ReasonGive, player, mingjie.name)
    end
  end,
})

mingjie:addEffect(fk.Death, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mingjie.name) and player:getMark(mingjie.name) == target
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:killPlayer({
      who = player,
    })
  end,
})

mingjie:addLoseEffect(function(self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "mingjiel_defensive", 0)
  local to = player:getMark(mingjie.name)
  if to ~= 0 then
    room:setPlayerMark(player, mingjie.name, 0)
    if table.every(room.alive_players, function(p)
      return p:getMark(mingjie.name) ~= to
    end) then
      room:setPlayerMark(to, "@@mingjiel", 0)
    end
  end
end)

mingjie:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    local ret = ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 1,
      max_num = 1,
      skill_name = self.skill_name,
      benefit_func = function (logic, p)
        logic.benefit = ai:needHelp(p)
      end,
    })
    return ret
  end,
})

return mingjie
