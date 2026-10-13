local skill = fk.CreateSkill {
  name = "#taigong_tactics_skill",
  attached_equip = "taigong_tactics",
}

Fk:loadTranslationTable{
  ["#taigong_tactics_skill"] = "太公阴符",
  ["#taigong_tactics-choose"] = "太公阴符：你可以横置或重置一名角色",
  ["#taigong_tactics-recast"] = "太公阴符：你可以重铸一张手牌",
}

skill:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = skill.name,
      prompt = "#taigong_tactics-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    to:setChainState(not to.chained)
  end,
})

skill:addEffect(fk.EventPhaseEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Play and
      not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = self.name,
      prompt = "#taigong_tactics-recast",
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recastCard(event:getCostData(self).cards, player, skill.name)
  end,
})

return skill
