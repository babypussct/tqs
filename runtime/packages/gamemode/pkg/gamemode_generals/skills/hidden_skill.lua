local hidden_skill = fk.CreateSkill {
  name = "hidden_skill&"
}

local U = require "packages.utility.utility"

Fk:loadTranslationTable{
  ["hidden_skill&"] = "隐匿",
  [":hidden_skill&"] = "若你为隐匿将，防止你改变体力上限。当你扣减体力后，或你回合开始时，你解除隐匿状态。",
}

hidden_skill:addEffect(fk.PreparingGeneral, {
  global = true,
  mute = true,
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    if target == player and (data.results.general == data.general and data.results.deputy == data.deputyGeneral) then
      local room = player.room
      if not room:isGameMode("role_mode") then return false end
      local general = data.general
      local deputy = data.deputyGeneral
      local skills = Fk.generals[general]:getSkillNameList()
      if Fk.generals[deputy] then
        table.insertTable(skills, Fk.generals[deputy]:getSkillNameList())
      end
      if table.find(skills, function (s) return Fk.skills[s]:hasTag(Skill.Hidden) end) then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room.logic:recordInitialGeneral(player)
    room:setPlayerMark(player, "__hidden_general", data.general)
    if Fk.generals[data.deputyGeneral] then
      room:setPlayerMark(player, "__hidden_deputy", data.deputyGeneral)
      data.results.deputy = nil
    end
    data.results.general = "hiddenone"
    data:attachSkill(hidden_skill.name)
  end,
})

hidden_skill:addEffect(fk.HpChanged, {
  priority = 0.001,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and
      (player:getMark("__hidden_general") ~= 0 or player:getMark("__hidden_deputy") ~= 0) and
      data.num < 0
  end,
  on_trigger = function (self, event, target, player, data)
    U.GeneralAppear(player, "HpChanged")
  end,
})

hidden_skill:addEffect(fk.TurnStart, {
  priority = 0.001,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and
      (player:getMark("__hidden_general") ~= 0 or player:getMark("__hidden_deputy") ~= 0)
  end,
  on_trigger = function (self, event, target, player, data)
    U.GeneralAppear(player, "TurnStart")
  end,
})

hidden_skill:addEffect(fk.BeforeMaxHpChanged, {
  priority = 0.001,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and
      (player:getMark("__hidden_general") ~= 0 or player:getMark("__hidden_deputy") ~= 0)
  end,
  on_trigger = function (self, event, target, player, data)
    data.prevented = true
  end,
})

return hidden_skill
