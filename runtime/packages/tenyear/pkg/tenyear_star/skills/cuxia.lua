local cuxia = fk.CreateSkill {
  name = "cuxia",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["cuxia"] = "促狭",
  [":cuxia"] = "锁定技，当其他角色对你使用牌时，若其体力值大于你或本轮对你造成过伤害，其随机弃置一张手牌；若均满足，你摸一张牌。",

  ["$cuxia1"] = "本将纵横幽冀，不知何为敌手！",
  ["$cuxia2"] = "兀那长须贼将，脸红什么！",
}

cuxia:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      player:hasSkill(cuxia.name) and
      table.contains(data.tos, player) and
      (
        target.hp > player.hp or
        table.contains(player:getTableMark("cuxia_record-round-nolear"), target.id)
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local allChecked = target.hp > player.hp and
      table.contains(player:getTableMark("cuxia_record-round-nolear"), target.id)

    if target:isAlive() then
      local toThrow = table.filter(target:getCardIds("h"), function(id)
        return not target:prohibitDiscard(id)
      end)

      if #toThrow > 0 then
        room:throwCard(room:tableRandomPick(toThrow), cuxia.name, target, target)
      end
    end

    if allChecked and player:isAlive() then
      player:drawCards(1, cuxia.name)
    end
  end,
})

cuxia:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return
      target ~= player and
      player:hasSkill(cuxia.name, true) and
      data.to == player and
      not table.contains(player:getTableMark("cuxia_record-round-nolear"), target.id)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "cuxia_record-round-nolear", target.id)
  end,
})

cuxia:addAcquireEffect(function(self, player, isStart)
  if not isStart then
    local room = player.room
    room.logic:getActualDamageEvents(1, function(e)
      local damage = e.data
      if damage.to == player and damage.from and damage.from ~= player then
        room:addTableMarkIfNeed(player, "cuxia_record-round-nolear", damage.from.id)
      end
    end, Player.HistoryRound)
  end
end)

return cuxia
