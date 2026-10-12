local xiangchen = fk.CreateSkill {
  name = "xiangchen",
}

Fk:loadTranslationTable{
  ["xiangchen"] = "相谶",
  [":xiangchen"] = "出牌阶段限一次，你可以选择一名角色并随机出现与其势力和初始体力值相同的武将的三个技能（限定技、觉醒技、主公技除外），"..
    "你从中选择一个获得（以此法获得的技能存在三个时改为摸一张牌），"..
    "你的回合结束时，你失去以此法获得的技能；你或你上次发动〖相谶〗的目标角色体力值变化后，你可以发动此技能。",

  ["#xiangchen"] = "相谶：选择一名角色，从与其势力和初始体力值相同的武将技能中选择一个获得",
  ["#xiangchen-choice"] = "相谶：获得其中一个技能",

  ["$xiangchen1"] = "将军目藏北斗，奈何，呵呵，潞涿无毛。",
  ["$xiangchen2"] = "品貌知命途，一语解百忧。",
}

local U = require "packages.utility.utility"

xiangchen:addEffect("active", {
  anim_type = "special",
  prompt = "#xiangchen",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:setPlayerMark(player, xiangchen.name, target)
    local skills = table.filter(player:getTableMark("xiangchen_skills"), function (s)
      return player:hasSkill(s, true)
    end)
    if #skills > 2 then
      player:drawCards(1, xiangchen.name)
    else
      local all_list = {}
      for name, general in pairs(Fk.generals) do
        if Fk:canUseGeneral(name) and
          general.kingdom == target.kingdom and general.hp == Fk.generals[target.general].hp then
          local g_skills = table.filter(general:getSkillNameList(), function (skill)
            return not player:hasSkill(skill, true) and
              not table.find({ Skill.Limited, Skill.Wake, Skill.Lord }, function (tag)
                return Fk.skills[skill]:hasTag(tag)
              end)
          end)
          if #g_skills > 0 then
            table.insert(all_list, {name, g_skills})
          end
        end
      end
      if #all_list > 0 then
        all_list = room:tableRandomPick(all_list, 3)
        local generals = table.map(all_list, function (v) return v[1] end)
        local g_skills = table.map(all_list, function (v) return room:tableRandomPick(v[2], 1) end) -- 抽1个技能
        local skill = U.askToChooseGeneralSkills(player, {
          skill_name = xiangchen.name, prompt = "#xiangchen-choice",
          min_num = 1, max_num = 1, cancelable = false,
          generals = generals, skills = g_skills,
        })[1]
        table.insert(skills, skill)
        room:setPlayerMark(player, "xiangchen_skills", skills)
        room:addTableMarkIfNeed(player, "all_xiangchen_skills", skill)
        room:handleAddLoseSkills(player, skill)
      end
    end
  end,
})

xiangchen:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("xiangchen_skills") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:removeTableMark(player, "xiangchen_skills", data.skill.name)
  end,
})

xiangchen:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  audio_index = 0,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(xiangchen.name) and player:getMark("xiangchen_skills") ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-"..table.concat(player:getMark("xiangchen_skills"), "|-"))
    room:setPlayerMark(player, "xiangchen_skills", 0)
  end,
})

local spec = {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      skill_name = xiangchen.name,
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      prompt = "#xiangchen",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local skill = Fk.skills[xiangchen.name]
    skill:onUse(room, {
      from = player,
      tos = event:getCostData(self).tos,
    })
  end
}

xiangchen:addEffect(fk.HpChanged, {
  anim_type = "special",
  can_trigger = function (self, event, target, player, data)
    return (target == player or target == player:getMark(xiangchen.name)) and player:hasSkill(xiangchen.name) and
      data.num <= 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

xiangchen:addEffect(fk.HpRecover, {
  anim_type = "special",
  can_trigger = function (self, event, target, player, data)
    return (target == player or target == player:getMark(xiangchen.name)) and player:hasSkill(xiangchen.name)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return xiangchen
