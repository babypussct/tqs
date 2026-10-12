local lingfa = fk.CreateSkill {
  name = "lingfa",
  related_skills = { "os__zhian", "jianxiong" },
}

Fk:loadTranslationTable{
  ["lingfa"] = "令法",
  [":lingfa"] = "每轮开始时，若当前轮数不大于2，你可令第X项效果本轮对所有其他角色生效（X为当前轮数）：" ..
  "1.使用【杀】时，其需弃置一张牌，否则你对其造成1点伤害；2.使用【桃】结算结束后，其需交给你一张牌，" ..
  "否则你对其造成1点伤害。若当前轮数大于2，则你失去此技能，获得〖治暗〗和〖奸雄〗。",

  ["@lingfa-round-noclear"] = "令法",
  ["#lingfa-invokeOne"] = "令法：你可令其他角色本轮使用【杀】需弃牌，否则受伤",
  ["#lingfa-invokeTwo"] = "令法：你可令其他角色本轮使用【桃】需给你牌，否则受伤",
  ["#lingfa-discard"] = "令法：弃置一张牌，否则受到 %dest 造成的1点伤害",
  ["#lingfa-give"] = "令法：交给 %dest 一张牌，否则受到其造成的1点伤害",

  ["$lingfa1"] = "令行禁止，法外无情。",
  ["$lingfa2"] = "法令如山，岂容尔等造次！",
}

lingfa:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(lingfa.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local roundCount = room:getBanner("RoundCount")
    return
      roundCount > 2 or
      room:askToSkillInvoke(
        player, {
          skill_name = lingfa.name,
          prompt = roundCount == 1 and "#lingfa-invokeOne" or "#lingfa-invokeTwo",
        }
      )
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local round = room:getBanner("RoundCount")
    if round <= 2 then
      local mark = round == 1 and "slash" or "peach"
      room:setPlayerMark(player, "@lingfa-round-noclear", mark)
    else
      room:handleAddLoseSkills(player, "-lingfa|os__zhian|jianxiong")
    end
  end,
})

lingfa:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      player:hasSkill(lingfa.name) and
      player:getMark("@lingfa-round-noclear") == "slash" and
      data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { player } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = lingfa.name
    local room = player.room
    local cids = room:askToDiscard(
      target,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        prompt = "#lingfa-discard::" .. player.id,
      }
    )
    if #cids == 0 then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

lingfa:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      player:hasSkill(lingfa.name) and
      player:getMark("@lingfa-round-noclear") == "peach" and
      data.card.name == "peach"
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { player } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = lingfa.name
    local room = player.room
    local cids = room:askToCards(
      target,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        prompt = "#lingfa-give::" .. player.id,
      }
    )
    if #cids > 0 then
      room:obtainCard(player, cids, false, fk.ReasonGive, target, skillName)
    else
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

return lingfa
