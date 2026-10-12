local quanfeng = fk.CreateSkill {
  name = "quanfeng",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["quanfeng"] = "劝封",
  [":quanfeng"] = "限定技，当一名其他角色死亡后，你可以<a href='memorialize'>追思</a>该角色，"..
  "失去〖弘仪〗，获得其武将牌上的所有技能（主公技除外），加1点体力上限，回复1点体力；"..
  "当你处于濒死状态时，你可以加2点体力上限，回复4点体力。",

  ["#quanfeng1-invoke"] = "劝封：可失去弘仪并获得%dest的所有技能，然后加1点体力上限和体力",
  ["#quanfeng2-invoke"] = "劝封：是否加2点体力上限，回复4点体力",

  ["$quanfeng1"] = "媛容德懿，应追谥之。",
  ["$quanfeng2"] = "景怀之号，方配得上前人之德。",
}

quanfeng:addEffect(fk.Deathed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(quanfeng.name) and
      player:usedSkillTimes(quanfeng.name, Player.HistoryGame) == 0 and
      player:hasSkill("hongyi", true) and
      not table.contains(player.room:getBanner('memorializedPlayers') or {}, target.id)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = quanfeng.name, prompt = "#quanfeng1-invoke::" .. target.id })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local zhuisiPlayers = room:getBanner('memorializedPlayers') or {}
    table.insertIfNeed(zhuisiPlayers, target.id)
    room:setBanner('memorializedPlayers', zhuisiPlayers)

    room:handleAddLoseSkills(player, "-hongyi", nil, true, false)

    local skills = Fk.generals[target.general]:getSkillNameList()
    if target.deputyGeneral ~= "" then
      table.insertTableIfNeed(skills, Fk.generals[target.deputyGeneral]:getSkillNameList())
    end
    skills = table.filter(skills, function(skill_name)
      local skill = Fk.skills[skill_name]
      local sk = skill:getSkeleton()
      return
        not skill:hasTag(Skill.Lord) and
        sk and
        not (#sk.attached_kingdom > 0 and not table.contains(sk.attached_kingdom, player.kingdom))
    end)
    if #skills > 0 then
      room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
    end
    room:changeMaxHp(player, 1)
    if player:isAlive() and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = quanfeng.name,
      })
    end
  end,
})

quanfeng:addEffect(fk.AskForPeaches, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(quanfeng.name) and
      player:usedSkillTimes(quanfeng.name, Player.HistoryGame) == 0 and
      player == target and
      player.dying and
      player.hp < 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = quanfeng.name, prompt = "#quanfeng2-invoke" })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 2)
    if player:isAlive() and player:isWounded() then
      room:recover({
        who = player,
        num = math.min(4, player:getLostHp()),
        recoverBy = player,
        skillName = quanfeng.name,
      })
    end
  end,
})

return quanfeng
