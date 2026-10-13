local tianjiang = fk.CreateSkill {
  name = "jiange__tianjiang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__tianjiang"] = "天将",
  [":jiange__tianjiang"] = "锁定技，当友方角色每回合首次使用【杀】造成伤害后，其摸一张牌。",
}

tianjiang:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target and player:hasSkill(tianjiang.name) and data.card and data.card.trueName == "slash" and
      target:isFriend(player) then
      local room = player.room
      local damage_events = room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data
        return damage.from == player and damage.card ~= nil and damage.card.trueName == "slash"
      end, Player.HistoryTurn)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, tianjiang.name)
  end,
})

return tianjiang
