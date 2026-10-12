local mobileFengji = fk.CreateSkill {
  name = "mobile__fengji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__fengji"] = "丰积",
  [":mobile__fengji"] = "锁定技，回合开始时，若你的手牌数不小于你上个回合结束后的数量，你摸三张牌且你本回合手牌上限等于你的体力上限。",

  ["@mobile__fengji"]= "丰积",

  ["$mobile__fengji1"] = "巡土田之宜，尽凿溉之利。",
  ["$mobile__fengji2"] = "养耆育孤，视民如伤，以丰定徐州。",
}

mobileFengji:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileFengji.name
    if target == player and player:hasSkill(skillName) then
      local num = player:getMark("@mobile__fengji")
      if num == 0 then num = player:getMark(skillName) end
      return num ~= 0 and player:getHandcardNum() >= tonumber(num)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, mobileFengji.name)
  end,
})

mobileFengji:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player  --不判断技能拥有者以适配偷技能的情况
  end,
  on_refresh = function(self, event, target, player, data)
     ---@type string
     local skillName = mobileFengji.name
    local num = (player:getHandcardNum() > 0) and player:getHandcardNum() or "0"
    if player:hasSkill(skillName, true) then
      player.room:setPlayerMark(player, "@mobile__fengji", num)
    else
      player.room:setPlayerMark(player, skillName, num)
    end
  end,
})

mobileFengji:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:usedSkillTimes(mobileFengji.name, Player.HistoryTurn) > 0 then
      return player.maxHp
    end
  end,
})

return mobileFengji
