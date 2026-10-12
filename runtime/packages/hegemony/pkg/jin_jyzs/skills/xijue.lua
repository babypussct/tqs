local xijue = fk.CreateSkill{
  name = "heg__xijue",
  related_skills = { "ex__tuxi", "sp__xiaoguo" },
}

Fk:loadTranslationTable{
  ["heg__xijue"] = "袭爵",
  [":heg__xijue"] = "你可以弃置一张牌以发动〖突袭〗或〖骁果〗。",

  ["#heg__xijue_tuxi-invoke"] = "袭爵：你可以弃置一张牌发动〖突袭〗",
  ["#heg__xijue_xiaoguo-invoke"] = "袭爵：你可以移去弃置一张牌对 %dest 发动〖骁果〗",
  ["#heg__xijue_tuxi-choose"] = "突袭：你可以少摸至多%arg张牌，获得等量其他角色各一张手牌",
  ["#heg__xijue_xiaoguo-invokes"] = "骁果：弃一张基本牌，%dest 需弃置一张装备牌并令你摸一张牌，否则你对其造成1点伤害",

  ["$heg__xijue1"] = "承爵于父，安能辱之！",
  ["$heg__xijue2"] = "虎父安有犬子乎？",
}

xijue:addEffect(fk.DrawNCards, {
  anim_type = "control",
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xijue.name) and data.n > 0 and
      table.find(player.room.alive_players, function(p)
        return p ~= player and not p:isKongcheng()
      end) and #player:getCardIds("he") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = xijue.name,
      prompt = "#heg__xijue_tuxi-invoke",
      cancelable = true,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, xijue.name, player, player)

    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and not p:isKongcheng()
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = data.n,
      prompt = "#heg__xijue_tuxi-choose:::"..data.n,
      skill_name = "ex__tuxi",
    })
    if #tos > 0 then
      room:sortByAction(tos)
      player:broadcastSkillInvoke("ex__tuxi")
      room:notifySkillInvoked(player, "ex__tuxi", "control")
      data.n = data.n - #tos
      for _, p in ipairs(tos) do
        if player.dead then break end
        if not p.dead and not p:isKongcheng() then
          local c = room:askToChooseCard(player, {
            target = p,
            flag = "h",
            skill_name = "ex__tuxi",
          })
          room:obtainCard(player, c, false, fk.ReasonPrey, player, "ex__tuxi")
        end
      end
    end
  end,
})
xijue:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xijue.name) and target.phase == Player.Finish and not target.dead and
      not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = xijue.name,
      prompt = "#heg__xijue_xiaoguo-invoke::"..target.id,
      cancelable = true,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, xijue.name, player, player)
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = "sp__xiaoguo",
      pattern = ".|.|.|.|.|basic",
      prompt = "#heg__xijue_xiaoguo-invokes::"..target.id,
      cancelable = true,
    })
    if #card > 0 then
      player:broadcastSkillInvoke("sp__xiaoguo")
      room:notifySkillInvoked(player, "sp__xiaoguo", "offensive")
      if target.dead then return false end
      if #room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = "sp__xiaoguo",
        pattern = ".|.|.|.|.|equip",
        prompt = "#sp__xiaoguo-discard:"..player.id,
        cancelable = true,
      }) > 0 then
        if not player.dead then
          player:drawCards(1, "sp__xiaoguo")
        end
      else
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = "sp__xiaoguo",
        }
      end
    end
  end,
})

return xijue
