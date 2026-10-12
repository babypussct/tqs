local dianyi = fk.CreateSkill {
  name = "os__dianyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__dianyi"] = "典仪",
  [":os__dianyi"] = "锁定技，回合结束时，若你本回合：造成过伤害，你须弃置所有手牌；未造成过伤害，你将手牌摸至或弃置至四张。",

  ["$os__dianyi1"] = "旧仪废弛，兴造制度。",
  ["$os__dianyi2"] = "礼仪卒度，笑语卒获。",
}

dianyi:addEffect(fk.TurnEnd, {
  mute = true,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(dianyi.name)
    if #room.logic:getActualDamageEvents(1, function(e)
      return e.data.from == target
    end, Player.HistoryTurn) > 0 then
      room:notifySkillInvoked(player, dianyi.name, "negative")
      player:throwAllCards("h", dianyi.name)
    else
      local num = 4 - player:getHandcardNum()
      if num > 0 then
        room:notifySkillInvoked(player, dianyi.name, "drawcard")
        player:drawCards(num, dianyi.name)
      elseif num < 0 then
        room:notifySkillInvoked(player, dianyi.name, "negative")
        num = -num
        room:askToDiscard(player, {
          min_num = num,
          max_num = num,
          include_equip = false,
          skill_name = dianyi.name,
          cancelable = false,
        })
      end
    end
  end,
})

return dianyi
