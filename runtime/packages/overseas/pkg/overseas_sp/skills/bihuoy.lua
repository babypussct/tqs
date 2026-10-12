local os__bihuoy = fk.CreateSkill {
  name = "os__bihuoy",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__bihuoy"] = "避祸",
  [":os__bihuoy"] = "限定技，一名角色脱离濒死状态时，你可以令其摸X张牌，然后除其以外的角色本轮计算与其的距离时+X（X为存活角色数且至少为3）。",

  ["#os__bihuoy-invoke"] = "避祸：你可以令 %dest 摸%arg张牌且本轮所有角色至其距离+%arg",
  ["@os__bihuoy-round"] = "避祸",

  ["$os__bihuoy1"] = "曹操因利而动，主公可谋大利而降。",
  ["$os__bihuoy2"] = "避祸保身，唯此计也，别无二法。",
}

os__bihuoy:addEffect(fk.AfterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      target:isAlive() and
      player:hasSkill(os__bihuoy.name) and
      player:usedSkillTimes(os__bihuoy.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = os__bihuoy.name,
      prompt = "#os__bihuoy-invoke::" .. target.id .. ":" .. math.max(3, #player.room.alive_players)
    })then
      event:setCostData(self, { tos = {target} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.max(3, #room.alive_players)
    target:drawCards(n, os__bihuoy.name)
    room:setPlayerMark(target, "@os__bihuoy-round", n)
  end,
})

os__bihuoy:addEffect("distance", {
  correct_func = function(self, from, to)
    return to:getMark("@os__bihuoy-round")
  end,
})

return os__bihuoy
