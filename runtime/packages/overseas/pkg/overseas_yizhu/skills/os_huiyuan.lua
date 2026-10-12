local osHuiyuan = fk.CreateSkill {
  name = "os__huiyuan"
}

Fk:loadTranslationTable{
  ["os__huiyuan"] = "回援",
  [":os__huiyuan"] = "当你于出牌阶段使用牌结算结束后，若此阶段你未获得过此类型的牌，你可选择一名角色并展示其一张手牌，" ..
  "若与你使用的牌类型：相同，你获得此牌，不同：你弃置其此牌，其摸一张牌。若<a href='os__guerrilla'>游击</a>：你对其造成1点伤害。",

  ["#os__huiyuan-ask"] = "回援：你可展示一名角色的一张手牌，若为 %arg：你获得此牌，不为：你弃置其此牌，其摸一张牌",

  ["$os__huiyuan1"] = "起渤海之兵，襄吾兄成事！",
  ["$os__huiyuan2"] = "发一州之力，随手足之势！",
}

osHuiyuan:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if
      target == player and
      player:hasSkill(osHuiyuan.name) and
      player.phase == Player.Play and
      table.find(player.room.alive_players, function(p) return not p:isKongcheng() end)
    then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        local cardType = data.card.type
        for _, move in ipairs(e.data) do
          if move.toArea == Card.PlayerHand and move.to == player then
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if Fk:getCardById(id).type == cardType then
                return true
              end
            end
          end
        end
      end, Player.HistoryPhase) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = table.filter(room.alive_players, function(p) return not p:isKongcheng() end)
    local targets = room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        targets = availableTargets,
        prompt = "#os__huiyuan-ask:::" .. data.card:getTypeString(),
        skill_name = osHuiyuan.name,
      }
    )
    if #targets > 0 then
      event:setCostData(self, targets[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osHuiyuan.name
    local room = player.room
    local targetPlayer = event:getCostData(self)
    local id = room:askToChooseCard(
      player,
      {
        target = targetPlayer,
        flag = "h",
        skill_name = skillName,
      }
    )
    if Fk:getCardById(id).type == data.card.type then
      if targetPlayer ~= player then
        room:obtainCard(player, id, true, fk.ReasonPrey, player, skillName)
      end
    else
      room:throwCard(id, skillName, targetPlayer, player)
      targetPlayer:drawCards(1, skillName)
    end
    if player:inMyAttackRange(targetPlayer) and not targetPlayer:inMyAttackRange(player) then
      room:damage{
        from = player,
        to = targetPlayer,
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

return osHuiyuan
