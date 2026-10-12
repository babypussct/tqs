local liance = fk.CreateSkill {
  name = "liance",
}

Fk:loadTranslationTable{
  ["liance"] = "敛策",
  [":liance"] = "每轮限一次，当你的手牌数变化后，若为全场最少，你可以将手牌摸至体力上限，然后本回合下次有角色造成伤害时，此伤害+1。",

  ["#liance-invoke"] = "敛策：你可以将手牌摸至体力上限，本回合下次伤害+1",

  ["$liance1"] = "持军合势，贼聚而不出，哎，惟险势可图。",
  ["$liance2"] = "日晦月见，此君政缓策，非谨略能安。",
}

liance:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(liance.name) and
      player:getHandcardNum() < player.maxHp and
      table.every(player.room.alive_players, function (p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end) and
      player:usedSkillTimes(liance.name, Player.HistoryRound) == 0 then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          return true
        end
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if room:getCurrent() then
      local n = room:getBanner("liance-turn") or 0
      room:setBanner("liance-turn", n + 1)
    end
    player:drawCards(player.maxHp - player:getHandcardNum(), liance.name)
  end,
})

liance:addEffect(fk.DamageCaused, {
  is_delay_effect = true,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.room:getBanner("liance-turn")
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { mute = not player:hasSkill(liance.name, true) })
    return true
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(player.room:getBanner("liance-turn"))
    player.room:setBanner("liance-turn", nil)
  end,
})

return liance
