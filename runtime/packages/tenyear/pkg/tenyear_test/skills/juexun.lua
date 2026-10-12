
local juexun = fk.CreateSkill{
  name = "juexun",
}

Fk:loadTranslationTable{
  ["juexun"] = "绝殉",
  [":juexun"] = "每回合限一次，你失去手牌后，若手牌数不为全场最多，你可以重置〖燃缕〗，"..
  "然后可以对自己造成1点火焰伤害，若你的体力值不为全场最多，令处于横置状态的其他角色下次受到属性伤害+1。",

  ["#juexun-invoke"] = "绝殉：你可以重置“燃缕”",
  ["#juexun-damage"] = "绝殉：你可以对自己造成1点火焰伤害",
  ["@@juexun"] = "受到属性伤害+1",

  ["$juexun1"] = "",
  ["$juexun2"] = "",
}

juexun:addEffect(fk.AfterCardsMove, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(juexun.name) and
      player:usedSkillTimes(juexun.name, Player.HistoryTurn) == 0 and
      table.find(player.room.alive_players, function (p)
        return p:getHandcardNum() > player:getHandcardNum()
      end) then
      for _, move in ipairs(data) do
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
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = juexun.name,
      prompt = "#juexun-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "ranlv", 0)
    if room:askToSkillInvoke(player, {
      skill_name = juexun.name,
      prompt = "#juexun-damage",
    }) then
      room:damage{
        from = player,
        to = player,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = juexun.name,
      }
      if table.find(room.alive_players, function (p)
        return p.hp > player.hp
      end) then
        for _, p in ipairs(room:getOtherPlayers(player, false)) do
          if p.chained then
            room:setPlayerMark(p, "@@juexun", 1)
          end
        end
      end
    end
  end,
})

juexun:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.damage ~= fk.NormalDamage and player:getMark("@@juexun") > 0
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(1)
    player.room:setPlayerMark(player, "@@juexun", 0)
  end,
})

return juexun
