local danshou = fk.CreateSkill {
  name = "m_ex__danshou",
}

Fk:loadTranslationTable{
  ["m_ex__danshou"] = "胆守",
  [":m_ex__danshou"] = "其他角色的结束阶段，若你本回合未成为过其使用牌的目标，你摸一张牌；否则你可以弃置X张牌，对其造成1点伤害（X为你本回合成为其使用牌的目标的次数）。",

  ["@m_ex__danshou_count-turn"] = "胆守",
  ["#m_ex__danshou-discard"] = "胆守：你可以弃置%arg张牌来对%dest造成1点伤害",

  ["$m_ex__danshou1"] = "此城危难，我必当竭尽全力！",
  ["$m_ex__danshou2"] = "大丈夫屈伸有道，不在一时胜负。",
}

danshou:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and target ~= player and player:hasSkill(danshou.name) and
    #player:getCardIds("he") >= player:getMark("@m_ex__danshou_count-turn")
  end,
  on_cost = function(self, event, target, player, data)
    local x = player:getMark("@m_ex__danshou_count-turn")
    if x == 0 then
      return true
    else
      local cards = player.room:askToDiscard(player, {
        min_num = x,
        max_num = x,
        include_equip = true,
        skill_name = danshou.name,
        cancelable = true,
        pattern = ".",
        prompt = "#m_ex__danshou-discard::"..target.id..":"..x,
        skip = true,
      })
      if #cards == x then
        event:setCostData(self, {tos = {target}, cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self)
    if dat then
      room:notifySkillInvoked(player, danshou.name, "offensive", {target.id})
      player:broadcastSkillInvoke(danshou.name, 1)
      room:throwCard(dat.cards, danshou.name, player)
      if not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = danshou.name,
        }
      end
    else
      room:notifySkillInvoked(player, danshou.name, "drawcard")
      player:broadcastSkillInvoke(danshou.name, 2)
      player:drawCards(1, danshou.name)
    end
  end,
})

danshou:addEffect(fk.TargetConfirmed, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(danshou.name, true) and
    (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and
    data.from ~= player and player.room:getCurrent() == data.from
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@m_ex__danshou_count-turn")
  end,
})

danshou:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@m_ex__danshou_count-turn", 0)
end)

return danshou
