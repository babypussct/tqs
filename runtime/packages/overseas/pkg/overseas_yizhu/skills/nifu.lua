local nifu = fk.CreateSkill {
  name = "os__nifu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__nifu"] = "匿伏",
  [":os__nifu"] = "锁定技，每名角色的回合结束时，你将手牌摸或弃至四张。",

  ["$os__nifu1"] = "春风融冷霜，藏冬之柔蓟可以亭亭矣。",
  ["$os__nifu2"] = "君看枯木裹雪霜，春来一一焕荣光！",
}

nifu:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(nifu.name) and player:getHandcardNum() ~= 4
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(nifu.name)
    local room = player.room
    local n = player:getHandcardNum() - 4
    if n < 0 then
      room:notifySkillInvoked(player, nifu.name, "drawcard")
      player:drawCards(-n, nifu.name)
    else
      room:notifySkillInvoked(player, nifu.name, "negative")
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = nifu.name,
        cancelable = false,
      })
    end
  end,
})

return nifu
