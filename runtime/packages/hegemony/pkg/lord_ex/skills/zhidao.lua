local zhidao = fk.CreateSkill {
  name = "ld__zhidao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ld__zhidao"] = "雉盗",
  [":ld__zhidao"] = "锁定技，出牌阶段开始时，你选择一名其他角色，直到回合结束："..
  "你与其距离视为1，你不能使用牌指定除你与其以外的角色为目标，然后当你于出牌阶段内第一次对其造成伤害后，你获得其区域内的一张牌。",

  ["@@ld__zhidao-turn"] = "雉盗",
  ["#ld__zhidao-choose"] = "雉盗：选择一名其他角色，本回合你使用牌仅能指定你或其为目标",

  ["$ld__zhidao1"] = "一朝得势，自当尽诸其力！",
  ["$ld__zhidao2"] = "本王要的，没有得不到的！",
}

zhidao:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhidao.name) and player.phase == Player.Play and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#ld__zhidao-choose",
      skill_name = zhidao.name,
      cancelable = false,
    })[1]
    room:addTableMarkIfNeed(to, "@@ld__zhidao-turn", player)
  end,
})

zhidao:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhidao.name) and
      player.phase == Player.Play and table.contains(data.to:getTableMark("@@ld__zhidao-turn"), player) and
      not data.to:isAllNude() then
      local damage_events = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == player and e.data.to == data.to
      end, Player.HistoryPhase)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = "hej",
      skill_name = zhidao.name,
    })
    room:obtainCard(player, card, false, fk.ReasonPrey)
  end,
})

zhidao:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    if from and card and from:usedSkillTimes(zhidao.name, Player.HistoryTurn) > 0 then
      return to ~= from and not table.contains(to:getTableMark("@@ld__zhidao-turn"), from)
    end
  end,
})

zhidao:addEffect("distance", {
  fixed_func = function(self, from, to)
    if table.contains(to:getTableMark("@@ld__zhidao-turn"), from) then
      return 1
    end
  end,
})

return zhidao
