local luoyan = fk.CreateSkill {
  name = "ol__luoyan",
  tags = { Skill.Compulsory },
  related_skills = { "m_ex__tianxiang", "liuli" },
}

Fk:loadTranslationTable{
  ["ol__luoyan"] = "落雁",
  [":ol__luoyan"] = "锁定技，若你有“星舞”牌，你视为拥有技能〖天香〗和〖流离〗。",
}

luoyan:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(luoyan.name, true) and player.phase == Player.Discard then
      for _, move in ipairs(data) do
        if move.specialName == "ol__dance" then
          return true
        end
        for _, info in ipairs(move.moveInfo) do
          if info.fromSpecialName == "ol__dance" then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("ol__dance") == 0 and (player:hasSkill("m_ex__tianxiang", true) or player:hasSkill("liuli", true)) then
      room:handleAddLoseSkills(player, "-m_ex__tianxiang|-liuli", "ol__xingwu", true, false)
    end
    if #player:getPile("ol__dance") > 0 and not (player:hasSkill("m_ex__tianxiang", true) and player:hasSkill("liuli", true)) then
      room:handleAddLoseSkills(player, "m_ex__tianxiang|liuli", "ol__xingwu", true, false)
    end
  end,
})

return luoyan
