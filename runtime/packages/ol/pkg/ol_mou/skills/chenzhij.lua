local chenzhij = fk.CreateSkill {
  name = "chenzhij",
}

Fk:loadTranslationTable {
  ["chenzhij"] = "沉智",
  [":chenzhij"] = "你每轮受到第X次以后的伤害时，你弃置一张牌防止之（X为游戏轮数且至多为3）。" ..
  "每轮结束时，若你本轮未发动此技能，则你可以复原一名角色的一个限定技（每局游戏限一次）。",

  ["#chenzhij-invoke"] = "沉智：你需弃置一张牌，防止你受到的伤害",
  ["#chenzhij-choose"] = "沉智：你可以复原一名角色的一个限定技",
  ["#chenzhij-choice"] = "沉智：选择重置 %dest 一个限定技",

  ["$chenzhij1"] = "沉得住气，才守得住最后的底牌。",
  ["$chenzhij2"] = "这桌上留到最后的人，一定是我！",
}

local U = require "packages.utility.utility"

chenzhij:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(chenzhij.name) and
        table.find(player:getCardIds("he"), function(id)
          return not player:prohibitDiscard(id)
        end) then
      local nums = #player.room.logic:getActualDamageEvents(4,
        function(e)
          return e.data.to == player
        end, Player.HistoryRound)
      return nums >= math.min(player.room:getBanner("RoundCount") or 1, 3)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = chenzhij.name,
      cancelable = false,
      prompt = "#chenzhij-invoke",
    })
    data.prevented = true
  end,
})

chenzhij:addEffect(fk.RoundEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chenzhij.name) and
        player:usedSkillTimes(chenzhij.name, Player.HistoryRound) == 0 and
        player:usedEffectTimes(self.name, Player.HistoryGame) == 0 then
      local targets = {}
      for _, p in ipairs(player.room.alive_players) do
        if table.find(p:getSkillNameList(), function(s)
              return Fk.skills[s]:hasTag(Skill.Limited) and p:usedSkillTimes(s, Player.HistoryGame) > 0
            end) then
          table.insert(targets, p)
        end
      end
      if #targets > 0 then
        event:setCostData(self, { extra_data = targets })
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = event:getCostData(self).extra_data,
      min_num = 1,
      max_num = 1,
      prompt = "#chenzhij-choose",
      skill_name = chenzhij.name,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local skills = table.filter(to:getSkillNameList(), function(s)
      return Fk.skills[s]:hasTag(Skill.Limited) and to:usedSkillTimes(s, Player.HistoryGame) > 0
    end)
    local skill = skills[1]
    if #skills > 1 then
      skill = U.askToChooseSkills(player, {
        skill_name = chenzhij.name,
        skills = skills,
        prompt = "#chenzhij-choice::" .. to.id,
      })[1]
    end
    to:setSkillUseHistory(skill, 0, Player.HistoryGame)
  end,
})

return chenzhij
