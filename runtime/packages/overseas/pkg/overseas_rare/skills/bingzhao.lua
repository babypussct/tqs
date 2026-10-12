local osBingzhao = fk.CreateSkill {
  name = "os__bingzhao",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["os__bingzhao"] = "秉诏",
  [":os__bingzhao"] = "主公技，游戏开始时，你选择一个其他势力，该势力有“傀”的角色受到伤害后，可令你因〖骨疽〗额外摸一张牌。",

  ["#os__bingzhao-choose"] = "秉诏：选择一个其他势力，该势力有“傀”的角色受到伤害后，可令你因〖骨疽〗额外摸一张牌",
  ["@os__bingzhao"] = "秉诏",
}

osBingzhao:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    return
      player:hasSkill(osBingzhao.name) and
      table.find(player.room.alive_players, function(p) return p.kingdom ~= player.kingdom end)
  end,
  on_cost = function(self, event, target, player)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    table.removeOne(kingdoms, player.kingdom)
    local choice = player.room:askToChoice(
      player,
      {
        choices = kingdoms,
        skill_name = osBingzhao.name,
        prompt = "#os__bingzhao-choose",
      }
    )
    event:setCostData(self, choice)
    return true
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "@" .. osBingzhao.name, event:getCostData(self))
  end,
})

osBingzhao:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@" .. osBingzhao.name, 0)
end)

return osBingzhao
