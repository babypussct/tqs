local qingtao = fk.CreateSkill {
  name = "os__qingtao",
}

Fk:loadTranslationTable{
  ["os__qingtao"] = "清滔",
  [":os__qingtao"] = "摸牌阶段结束时，你可以重铸一张牌，然后若此牌为【酒】或非基本牌，你摸一张牌。"..
  "若你本回合未发动此技能，你可以于此回合的结束阶段发动此技能。",

  ["#os__qingtao-ask"] = "清滔：你可以重铸一张牌，若为【酒】或非基本牌，你摸一张牌",

  ["$os__qingtao1"] = "君子当如滔流，循道而不失其行。",
  ["$os__qingtao2"] = "探赜索隐，钩深致远。日月在躬，隐之弥曜。",
}

local spec = {
  on_cost = function(self, event, target, player)
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = qingtao.name,
      prompt = "#os__qingtao-ask",
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = event:getCostData(self).cards
    local card = Fk:getCardById(event:getCostData(self).cards[1])
    room:recastCard(cards, player, qingtao.name)
    if player:isAlive() then
      if card.name == "analeptic" or card.type ~= Card.TypeBasic then
        player:drawCards(1, qingtao.name)
      end
    end
  end,
}

qingtao:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(qingtao.name) and player.phase == Player.Draw
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

qingtao:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(qingtao.name) and player.phase == Player.Finish and
      player:usedSkillTimes(qingtao.name, Player.HistoryTurn) == 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return qingtao
