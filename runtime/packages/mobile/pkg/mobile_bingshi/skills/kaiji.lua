local kaiji = fk.CreateSkill {
  name = "kaiji",
}

Fk:loadTranslationTable{
  ["kaiji"] = "开济",
  [":kaiji"] = "准备阶段，你可以令至多X名角色各摸一张牌，若有角色因此获得非基本牌，你摸一张牌" ..
  "（X为进入过濒死状态的存活角色数，且至少为1）。",

  ["#kaiji-choose"] = "开济：令至多%arg名角色各摸一张牌",

  ["$kaiji1"] = "储谷畜帛，反民於朴。",
  ["$kaiji2"] = "欲绝侈靡，务崇节俭。",
}

kaiji:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kaiji.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    room.logic:getEventsOfScope(GameEvent.Dying, 1, function (e)
      if not e.data.who.dead then
        table.insertIfNeed(targets, e.data.who)
      end
    end, Player.HistoryGame)
    local x = math.max(#targets, 1)
    local tos = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = x,
      prompt = "#kaiji-choose:::" .. x,
      skill_name = kaiji.name,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local yes = false
    local tos = event:getCostData(self).tos or {}
    for _, p in ipairs(tos) do
      if p:isAlive() then
        local cards = p:drawCards(1, kaiji.name)
        if #cards > 0 and
          table.find(cards, function (id)
            return Fk:getCardById(id).type ~= Card.TypeBasic
          end) then
          yes = true
        end
      end
    end
    if yes and not player.dead then
      player:drawCards(1, kaiji.name)
    end
  end,
})

return kaiji
