local weiming = fk.CreateSkill {
  name = "weiming",
  tags = { Skill.Quest },
}

Fk:loadTranslationTable{
  ["weiming"] = "威命",
  [":weiming"] = "使命技，出牌阶段开始时，你标记一名未标记过的其他角色。<br>" ..
  "⬤　成功：当你杀死一名未标记的角色后，你将〖血途〗修改至<a href=':xuetu_v2'>二级</a>；<br>" ..
  "⬤　失败：当一名已被标记的角色死亡后，你将〖血途〗修改至<a href=':xuetu_v3'>三级</a>。",

  ["@@weiming"] = "威命",
  ["#weiming-choose"] = "威命：选择1名未被选择过的角色，如其在你杀死其他未被选择过的角色死亡前死亡，则威命失败",

  ["$weiming1"] = "诸位东归洛阳，奉愿随驾以护。",
  ["$weiming2"] = "不遵皇命，视同倡乱之贼。",
  ["$weiming3"] = "布局良久，于今功亏一篑啊。",
}

weiming:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Play and
      player:hasSkill(weiming.name) and
      table.find(
        player.room.alive_players,
        function(p)
          return p ~= player and not table.contains(p:getTableMark("@@weiming"), player.id)
        end
      )
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = weiming.name
    local room = player.room
    player:broadcastSkillInvoke(skillName, 1)
    room:notifySkillInvoked(player, skillName, "offensive")

    local targets = table.filter(
      room.alive_players,
      function(p) return p ~= player and not table.contains(p:getTableMark("@@weiming"), player.id) end
    )
    if #targets == 0 then
      return false
    end

    local to = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#weiming-choose",
        skill_name = skillName,
        cancelable = false,
      }
    )[1]

    local weimingTargets = player.tag["weimingTargets"] or {}
    table.insertIfNeed(weimingTargets, to.id)
    player.tag["weimingTargets"] = weimingTargets

    room:addTableMarkIfNeed(to, "@@weiming", player.id)
  end,
})

weiming:addEffect(fk.Deathed, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(weiming.name) then
      return false
    end

    return
      (
        data.who and
        table.contains(player.tag["weimingTargets"] or {}, data.who.id)
      ) or
      (data.damage and data.damage.from == player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = weiming.name
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      local weimingOwners = p:getTableMark("@@weiming")
      table.removeOne(weimingOwners, player.id)
      room:setPlayerMark(p, "@@weiming", #weimingOwners > 0 and weimingOwners or 0)
    end
    if data.who and table.contains(player.tag["weimingTargets"] or {}, data.who.id) then
      player:broadcastSkillInvoke(skillName, 3)
      room:notifySkillInvoked(player, skillName, "negative")
      room:updateQuestSkillState(player, skillName, true)
      room:handleAddLoseSkills(player, "-xuetu|-xuetu_v2|xuetu_v3")
    else
      player:broadcastSkillInvoke(skillName, 2)
      room:notifySkillInvoked(player, skillName, "offensive")
      room:updateQuestSkillState(player, skillName)
      room:handleAddLoseSkills(player, "-xuetu|-xuetu_v3|xuetu_v2")
    end
    room:invalidateSkill(player, skillName)
  end,
})

return weiming
