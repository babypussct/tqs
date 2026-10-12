local yimie = fk.CreateSkill{
  name = "yimie",
}

Fk:loadTranslationTable{
  ["yimie"] = "夷灭",
  [":yimie"] = "每回合限一次，当你对其他角色造成伤害时，你可以失去1点体力，令此伤害值+X（X为其体力值减去伤害值）。伤害结算后，其回复X点体力。",

  ["#yimie-invoke"] = "夷灭：你可以失去1点体力，令你对 %dest 造成的伤害增加至其体力值！",

  ["$yimie1"] = "汝大逆不道，当死无赦！",
  ["$yimie2"] = "斩草除根，灭其退路！",
}

yimie:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  times = function (_, player)
    return 1 - player:usedSkillTimes(yimie.name, Player.HistoryTurn)
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yimie.name) and
      data.to ~= player and data.to.hp > data.damage and
      player:usedSkillTimes(yimie.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yimie.name,
      prompt = "#yimie-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = data.to.hp - data.damage
    local damage_event = room.logic:getCurrentEvent():findParent(GameEvent.Damage, true)
    if damage_event then
      damage_event:addCleaner(function()
        if not data.to.dead then
          room:recover{
            who = data.to,
            num = x,
            skillName = yimie.name,
          }
        end
      end)
    end
    data:changeDamage(x)
    room:loseHp(player, 1, yimie.name)
  end,
})

yimie:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    local data = ai.room.logic:getCurrentEvent().data._data
    if data.to.shield == 0 and
      not table.find(data.to:getHandlyIds(), function (id)
        return table.contains({ "peach", "analeptic" }, Fk:getCardById(id).trueName)
      end) and
      not table.find(data.to:getFriends(), function (p)
        return table.find(p:getHandlyIds(), function (id)
          return Fk:getCardById(id).trueName == "peach"
        end)
      end) then
      return ai:getBenefitOfEvents(function(logic)
        logic:loseHp(ai.player, 1, self.skill_name)
        logic:changeDamage(data, data.to.hp - data.damage)
      end) >= 0
    end
  end,
})

return yimie
