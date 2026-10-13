local jizhen = fk.CreateSkill {
  name = "jiange__jizhen",
}

Fk:loadTranslationTable{
  ["jiange__jizhen"] = "激阵",
  [":jiange__jizhen"] = "结束阶段，你可以令所有友方已受伤角色各摸一张牌。",

  ["#jiange__jizhen-invoke"] = "激阵：是否令所有友方已受伤角色各摸一张牌？",
}

jizhen:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jizhen.name) and player.phase == Player.Finish and
      table.find(player:getFriends(), function (p)
        return p:isWounded()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = jizhen.name,
      prompt = "#jiange__jizhen-invoke",
    }) then
      local tos = table.filter(player:getFriends(), function (p)
        return p:isWounded()
      end)
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player:getFriends(), function (p)
      return p:isWounded()
    end)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        p:drawCards(1, jizhen.name)
      end
    end
  end,
})

return jizhen
