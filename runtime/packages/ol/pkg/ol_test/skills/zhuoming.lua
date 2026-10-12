
local zhuoming = fk.CreateSkill {
  name = "zhuoming",
}

Fk:loadTranslationTable{
  ["zhuoming"] = "濯名",
  [":zhuoming"] = "当你每回合首次造成或受到伤害时，你可以令一名其他角色获得一个“评鉴”技能，直到其发动此技能；"..
  "有角色失去一个“评鉴”技能后，你摸一张牌。",

  ["#zhuoming-choose"] = "濯名：你可以令一名其他角色获得一个“评鉴”技能",

  ["$zhuoming1"] = "",
  ["$zhuoming2"] = "",
}

zhuoming:addEffect(fk.DamageCaused, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuoming.name) and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == player
      end) == 0 and data.damage > 0 and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p:getMark(zhuoming.name) == 0 or not p:hasSkill(p:getMark(zhuoming.name), true)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:getMark(zhuoming.name) == 0 or not p:hasSkill(p:getMark(zhuoming.name), true)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = zhuoming.name,
      prompt = "#zhuoming-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local skills = Fk.skill_skels["shilunx"].pinjian_skills
    skills = table.filter(skills, function (s)
      return not to:hasSkill(s, true)
    end)
    if #skills == 0 then return end
    local skill = room:tableRandomPick(skills)
    room:setPlayerMark(to, zhuoming.name, skill)
    room:handleAddLoseSkills(to, skill)
  end,
})

zhuoming:addEffect(fk.AfterSkillEffect, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.skill:getSkeleton().name == player:getMark(zhuoming.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, zhuoming.name, 0)
    room:handleAddLoseSkills(player, "-"..data.skill:getSkeleton().name)
  end,
})

zhuoming:addEffect(fk.EventLoseSkill, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(zhuoming.name) and
      table.contains(Fk.skill_skels["shilunx"].pinjian_skills, data.skill.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, zhuoming.name)
  end,
})

return zhuoming
