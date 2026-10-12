local liantao = fk.CreateSkill{
  name = "liantao",
}

Fk:loadTranslationTable{
  ["liantao"] = "连讨",
  [":liantao"] = "出牌阶段开始时，你可令一名其他角色选择一种颜色，然后你展示所有手牌，"..
    "并依次将此颜色的手牌当【决斗】对其使用直到有一方进入濒死状态，然后你摸X张牌（X为你以此法对目标角色造成的伤害数）。"..
    "若该角色没有因此受到伤害，你摸一张牌，本回合手牌上限+1且不能使用【杀】。",

  ["#liantao-choose"] = "连讨：选择一名其他角色，将一种颜色的手牌当【决斗】对其使用！",
  ["#liantao-choice"] = "连讨：选择一种颜色，%src 将此颜色手牌当【决斗】对你使用！",
  ["#liantao-duel"] = "连讨：选择一张%arg手牌当【决斗】对 %dest 使用",

  ["$liantao1"] = "沙场百战疾，争衡天下间。",
  ["$liantao2"] = "征战无休，决胜千里。",
}

liantao:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liantao.name) and player.phase == Player.Play and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = liantao.name,
      prompt = "#liantao-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = room:askToChoice(to, {
      choices = {"red", "black"},
      skill_name = liantao.name,
      prompt = "#liantao-choice:"..player.id,
    })
    player:showCards(player:getCardIds("h"))
    local events, damage
    local breakloop, x = false, 0
    local event_id = room.logic.current_event_id
    while not (player.dead or player:isKongcheng() or to.dead) do
      local duel = Fk:cloneCard("duel")
      duel.skillName = liantao.name
      local cards = table.filter(player:getCardIds("h"), function(id)
        duel.subcards = {}
        duel:addSubcard(id)
        return duel:getColorString() == choice and player:canUseTo(duel, to)
      end)
      if #cards == 0 then break end
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = liantao.name,
        pattern = tostring(Exppattern{ id = cards }),
        prompt = "#liantao-duel::"..to.id..":"..choice,
        cancelable = false,
      })
      local use = room:useVirtualCard("duel", card, player, to, liantao.name)
      if not use or player.dead then return end
      events = room.logic.event_recorder[GameEvent.Damage] or Util.DummyTable
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id <= event_id then break end
        damage = e.data
        if damage.dealtRecorderId and damage.from == player and damage.to == to and damage.card == use.card then
          x = x + damage.damage
        end
      end
      if target.dead then break end
      events = room.logic.event_recorder[GameEvent.Dying] or Util.DummyTable
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id <= event_id then break end
        if e.data.who == player or e.data.who == to then
          breakloop = true
          break
        end
      end
      if breakloop then break end
      event_id = room.logic.current_event_id
    end
    if x > 0 then
      room:drawCards(player, x, liantao.name)
    else
      room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 1)
      room:setPlayerMark(player, "liantao_prohibit-turn", 1)
      room:drawCards(player, 1, liantao.name)
    end
  end,
})
liantao:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("liantao_prohibit-turn") > 0 and card.trueName == "slash"
  end,
})

return liantao
