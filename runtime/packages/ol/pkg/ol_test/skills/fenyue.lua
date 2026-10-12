local fenyue = fk.CreateSkill {
  name = "fenyue",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["fenyue"] = "奋钺",
  [":fenyue"] = "转换技，每回合结束时，若本回合你受到过伤害，或有角色受到过属性伤害，你可以：阳：摸两张牌；阴：使用一张牌。",

  ["#fenyue_yang-invoke"] = "奋钺：你可以摸两张牌",
  ["#fenyue_yin-invoke"] = "奋钺：你可以使用一张牌",

  ["$fenyue1"] = "",
  ["$fenyue2"] = "",
}

fenyue:addEffect(fk.TurnEnd, {
  anim_type = "switch",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(fenyue.name) and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.damageType ~= fk.NormalDamage or e.data.to == player
      end, Player.HistoryTurn) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(fenyue.name) == fk.SwitchYang then
      if room:askToSkillInvoke(player, {
        skill_name = fenyue.name,
        prompt = "#fenyue_yang-invoke",
      }) then
        event:setCostData(self, nil)
        return true
      end
    else
      local use = room:askToUseCard(player, {
        skill_name = fenyue.name,
        pattern = ".",
        prompt = "#fenyue_yin-invoke",
        cancelable = true,
        extra_data = {
          bypass_times = true,
        }
      })
      if use then
        use.extraUse = true
        event:setCostData(self, { extra_data = use })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event:getCostData(self) then
      player.room:useCard(event:getCostData(self).extra_data)
    else
      player:drawCards(2, fenyue.name)
    end
  end,
})

return fenyue
