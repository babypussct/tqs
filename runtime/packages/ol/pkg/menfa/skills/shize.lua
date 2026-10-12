local shize = fk.CreateSkill{
  name = "shize",
  tags = { Skill.Family, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shize"] = "士则",
  [":shize"] = "宗族技，锁定技，你于回合内使用牌首次被响应后，你令一名同族角色攻击范围+1，直到其下次受到伤害。",

  ["#shize-choose"] = "士则：令一名同族角色攻击范围+1",
  ["@shize"] = "士则",
}

local U = require "packages.utility.utility"

local spec = {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shize.name) and player.room:getCurrent() == player and
      data.responseToEvent and data.responseToEvent.from == player and
      player:usedSkillTimes(shize.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return U.FamilyMember(player, p)
    end)
    if #targets > 1 then
      targets = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = shize.name,
        prompt = "#shize-choose",
        cancelable = false,
      })
    end
    room:addPlayerMark(targets[1], "@shize", 1)
  end,
}

shize:addEffect(fk.CardUseFinished, spec)
shize:addEffect(fk.CardRespondFinished, spec)

shize:addEffect("atkrange", {
  correct_func = function(self, from, to)
    return from:getMark("@shize")
  end,
})

shize:addEffect(fk.Damaged, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@shize", 0)
  end,
})

return shize
