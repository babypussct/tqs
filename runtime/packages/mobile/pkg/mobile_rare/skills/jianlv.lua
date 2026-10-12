local jianlv = fk.CreateSkill {
  name = "jianlv",
}

Fk:loadTranslationTable{
  ["jianlv"] = "兼虑",
  [":jianlv"] = "当你一次性弃置至少X张牌后（X为你发动过本技能的次数+1），你可以对一名其他角色造成1点伤害。然后若其死亡，" ..
  "你选择一项：1.令本技能视为未发动过；2.对一名其他角色造成1点伤害。",

  ["#jianlv-choose"] = "兼虑：你可对一名其他角色造成1点伤害，然后若其死亡，你执行一项额外效果",
  ["jianlv_refresh"] = "令本技能视为未发动过",
  ["jianlv_damage"] = "对一名其他角色造成1点伤害",
  ["#jianlv-damage"] = "兼虑：请选择一名其他角色，对其造成1点伤害",
  ["@[jianlvNum]-noclear"] = "兼虑",

  ["$jianlv1"] = "今观曹魏之兵，更胜当年十倍。",
  ["$jianlv2"] = "蜀汉若灭，恐唇亡齿寒啊。",
  ["$jianlv3"] = "卫护江东，以全节义。",
}

jianlv:addEffect(fk.AfterCardsMove, {
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(jianlv.name) then
      return false
    end

    local discardNum = 0
    table.forEach(data, function (move)
      if move.moveReason == fk.ReasonDiscard and move.proposer == player then
        discardNum = discardNum + #move.moveInfo
      end
    end)

    return
      discardNum > player:usedSkillTimes(jianlv.name, Player.HistoryGame) and
      table.find(player.room.alive_players, function(p) return p ~= player end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(player, false),
        skill_name = jianlv.name,
        prompt = "#jianlv-choose",
      }
    )

    if #tos == 1 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    ---@type string
    local skillName = jianlv.name
    local room = player.room

    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = skillName,
    }

    if player:isAlive() and not to:isAlive() then
      local choices = { "jianlv_refresh", "jianlv_damage" }
      local targets = room:getOtherPlayers(player, false)
      if #targets == 0 then
        table.remove(choices, 2)
      end

      local choice = room:askToChoice(
        player,
        {
          choices = choices,
          all_choices = { "jianlv_refresh", "jianlv_damage" },
          skill_name = skillName,
        }
      )

      if choice == "jianlv_damage" then
        local tos = room:askToChoosePlayers(
          player,
          {
            min_num = 1,
            max_num = 1,
            targets = targets,
            skill_name = jianlv.name,
            prompt = "#jianlv-damage",
            cancelable = false,
          }
        )

        if #tos == 1 then
          room:doIndicate(player, tos)
          room:damage{
            from = player,
            to = tos[1],
            damage = 1,
            skillName = skillName,
          }
        end
      else
        player:clearSkillHistory(jianlv.name)
      end
    end
  end,
})

jianlv:addAcquireEffect(function (self, player)
  player.room:setPlayerMark(player, "@[jianlvNum]-noclear", player.id)
end)

jianlv:addLoseEffect(function (self, player, isDeath)
  if not isDeath then
    player.room:setPlayerMark(player, "@[jianlvNum]-noclear", 0)
  end
end)

Fk:addQmlMark({
  name = "jianlvNum",
  qml_path = "",
  how_to_show = function (name, value)
    local owner = Fk:currentRoom():getPlayerById(value)
    if not owner then
      return " "
    end

    return tostring(owner:usedSkillTimes(jianlv.name, Player.HistoryGame) + 1)
  end,
})

return jianlv
