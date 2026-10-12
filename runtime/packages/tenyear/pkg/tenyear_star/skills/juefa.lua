
local juefa = fk.CreateSkill {
  name = "juefa",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["juefa"] = "绝伐",
  [":juefa"] = "限定技，出牌阶段，你可以将〖维谷〗中“移动场上一张牌”改为“对一名角色造成2点伤害”直到你的下个回合结束。"..
  "若如此做，当你于此期间通过〖维谷〗杀死角色后，你将手牌和体力值调整至体力上限；若于此效果结束时你未杀死过角色，你失去所有体力。",

  ["#juefa"] = "绝伐：令“维谷”可以造成2点伤害直到你下回合结束",
  ["@@juefa"] = "绝伐",

  ["$juefa1"] = "天意高难问，人事尽可为！",
  ["$juefa2"] = "我本无根客，更何惜此头！",
}

juefa:addEffect("active", {
  anim_type = "offensive",
  prompt = "#juefa",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(juefa.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event then
      room:setPlayerMark(effect.from, "@@juefa", turn_event.id)
    else
      room:setPlayerMark(effect.from, "@@juefa", 1)
    end
  end,
})

juefa:addEffect(fk.Deathed, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return data.killer == player and player:getMark("@@juefa") > 0 and
      data.damage and data.damage.skillName == "weigu"
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(juefa.name)
    room:notifySkillInvoked(player, self.name, "drawcard")
    if player.maxHp > player:getHandcardNum() then
      player:drawCards(player.maxHp - player:getHandcardNum(), juefa.name)
      if player.dead then return end
    end
    if player:isWounded() then
      room:recover{
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = juefa.name,
      }
    end
  end,

  can_refresh = function (self, event, target, player, data)
    return data.killer == player and player:getMark("@@juefa") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, juefa.name, 1)
  end,
})

juefa:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@@juefa") ~= 0 and
      player:getMark("@@juefa") ~= player.room.logic:getCurrentEvent().id
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@juefa", 0)
    if player:getMark(juefa.name) > 0 then
      room:setPlayerMark(player, juefa.name, 0)
    elseif player.hp > 0 then
      player:broadcastSkillInvoke(juefa.name)
      room:notifySkillInvoked(player, self.name, "negative")
      room:loseHp(player, player.hp, juefa.name, player)
    end
  end,
})

return juefa
