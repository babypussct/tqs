local shenchong = fk.CreateSkill {
  name = "ol__shenchong",
  tags = { Skill.Limited },
  related_skills = { "ol_feiyang", "ol_bahu" },
}

Fk:loadTranslationTable{
  ["ol__shenchong"] = "甚宠",
  [":ol__shenchong"] = "限定技，准备阶段，你可以令一名其他角色获得〖飞扬〗和〖跋扈〗，若如此做，当你死亡时，杀死你的角色弃置所有牌，"..
  "因此获得技能的角色失去所有技能。",

  ["#ol__shenchong-choose"] = "甚宠：你可令一名其他角色获得〖飞扬〗和〖跋扈〗！",

  ["$ol__shenchong1"] = "天子近前，岂曰无人？赏！",
  ["$ol__shenchong2"] = "诸臣皆为己利，唯汝独讨朕心！",
}

shenchong:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Start and
      player:hasSkill(shenchong.name) and
      player:usedSkillTimes(shenchong.name, Player.HistoryGame) == 0 and
      table.find(player.room.alive_players, function (p)
        return p ~= player
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        targets = player.room:getOtherPlayers(player, false),
        skill_name = shenchong.name,
        prompt = "#ol__shenchong-choose",
        no_indicate = true,
      }
    )

    if #tos == 1 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]

    room:addTableMarkIfNeed(player, shenchong.name, to.id)
    room:handleAddLoseSkills(to, "ol_feiyang|ol_bahu")
  end,
})

shenchong:addEffect(fk.Death, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark(shenchong.name) ~= 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = table.map(player:getTableMark(shenchong.name), Util.Id2PlayerMapper)
    tos = table.filter(tos, function(p)
      return not p.dead
    end)
    if data.killer and not data.killer.dead then
      table.insertIfNeed(tos, data.killer)
    end
    room:sortByAction(tos)
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.killer and not data.killer.dead then
      data.killer:throwAllCards("he", shenchong.name)
    end
    local tos = table.map(player:getTableMark(shenchong.name), Util.Id2PlayerMapper)
    tos = table.filter(tos, function(p)
      return not p.dead
    end)
    for _, p in ipairs(tos) do
      if not p.dead then
        local skills = p:getSkillNameList()
        room:handleAddLoseSkills(p, "-"..table.concat(skills, "|-"))
      end
    end
  end,
})

return shenchong
