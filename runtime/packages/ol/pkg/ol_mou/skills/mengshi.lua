local mengshi = fk.CreateSkill {
  name = "mengshi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["mengshi"] = "盟势",
  [":mengshi"] = "限定技，结束阶段，你可以失去X点体力（X为两者体力之差），令两名其他角色交换体力值。每个回合结束时，你摸一张牌并回复1点体力，" ..
      "直到其中一名角色死亡。",

  ["#mengshi-choose"] = "盟势：选择两名体力不同角色交换体力值，你失去其体力值之差的体力",
  ["@@mengshi"] = "盟势",
  ["@@mengshi-target"] = "盟势目标",

  ["$mengshi1"] = "商人趋利，察，虽万难必蹈。",
  ["$mengshi2"] = "商人择良，用，虽一布必慎。",
}

mengshi:addAuxActiveSkill("mengshi_select", {
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected > 0 and to_select.hp == selected[1].hp then
      return false
    end
    return #selected < 2 and to_select ~= player
  end,
})

mengshi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mengshi.name) and player.phase == Player.Finish and
        player:usedEffectTimes(self.name, Player.HistoryGame) == 0 and
        #player.room:getOtherPlayers(player, false) > 1 and player.hp > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(
      player,
      {
        skill_name = "mengshi_select",
        prompt = "#mengshi-choose",
      }
    )
    if success and dat and #(dat.targets or {}) == 2 then
      event:setCostData(self, { tos = dat.targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos or {}
    room:setPlayerMark(player, "@@mengshi", tos)
    room:setPlayerMark(tos[1], "@@mengshi-target", tos[2])
    room:setPlayerMark(tos[2], "@@mengshi-target", tos[1])
    local n = tos[1].hp - tos[2].hp
    if n == 0 then return end
    local from, to
    if tos[1].hp > tos[2].hp then
      from = tos[1]
      to = tos[2]
    else
      n = -n
      from = tos[2]
      to = tos[1]
    end
    room:loseHp(player, n, mengshi.name)
    if not from.dead then
      room:loseHp(from, n, mengshi.name)
    end
    if not to.dead and to:isWounded() then
      room:recover {
        who = to,
        num = n,
        recoverBy = player,
        skillName = mengshi.name,
      }
    end
  end,
})

mengshi:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@mengshi") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(mengshi.name)
    room:notifySkillInvoked(player, self.name, "support")
    player:drawCards(1, mengshi.name)
    if not player.dead then
      room:recover {
        who = player,
        num = 1,
        recoverBy = player,
        skillName = mengshi.name,
      }
    end
  end,
})

mengshi:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return table.contains(player:getTableMark("@@mengshi"), target)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@mengshi", 0)
    for _, p in ipairs(player.room.alive_players) do
      if p:getMark("@@mengshi-target") == player then
        player.room:setPlayerMark(p, "@@mengshi-target", 0)
      end
    end
  end,
})

return mengshi
