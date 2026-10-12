local pingkou = fk.CreateSkill{
  name = "m_ex__pingkou",
}

Fk:loadTranslationTable{
  ["m_ex__pingkou"] = "平寇",
  [":m_ex__pingkou"] = "回合结束时，你可以对至多X名其他角色各造成1点伤害（X为你本回合跳过的阶段数），若如此做，你从牌堆中随机获得一张装备牌。",

  ["#m_ex__pingkou-choose"] = "平寇：你可以对至多%arg名角色各造成1点伤害，然后随机获得1张装备",

  ["$m_ex__pingkou1"] = "等候多时，为的便是今日之胜。",
  ["$m_ex__pingkou2"] = "一鼓作气，击败疲敝之敌！",
}

pingkou:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pingkou.name) and table.find(data.phase_table, function(phase)
      return phase.who == player and phase.skipped
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = #table.filter(data.phase_table, function(phase)
      return phase.who == player and phase.skipped
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = x,
      targets = room:getOtherPlayers(player, false),
      skill_name = pingkou.name,
      prompt = "#m_ex__pingkou-choose:::" .. x,
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
    local tos = event:getCostData(self).tos
    for _, p in ipairs(tos) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = pingkou.name,
        }
      end
    end
    if player.dead then return false end
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|equip")
    if #cards > 0 then
      player.room:obtainCard(player, cards[1], true, fk.ReasonJustMove, player, pingkou.name)
    end
  end,
})

return pingkou
