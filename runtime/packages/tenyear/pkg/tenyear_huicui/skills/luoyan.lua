local luoyan = fk.CreateSkill {
  name = "ty__luoyan",
  tags = { Skill.Compulsory },
  related_skills = { "m_ex__tianxiang", "liuli" },
}

Fk:loadTranslationTable{
  ["ty__luoyan"] = "落雁",
  [":ty__luoyan"] = "锁定技，若你的武将牌上有“舞”，你视为拥有技能<a href=':m_ex__tianxiang'>〖天香〗</a>和<a href='liuli'>〖流离〗</a>。",
}

luoyan:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(luoyan.name, true) and player.phase == Player.Discard then
      for _, move in ipairs(data) do
        if move.specialName == "ty__dance" then
          return true
        end
        for _, info in ipairs(move.moveInfo) do
          if info.fromSpecialName == "ty__dance" then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("ty__dance") == 0 and (player:hasSkill("m_ex__tianxiang", true) or player:hasSkill("liuli", true)) then
      room:handleAddLoseSkills(player, "-m_ex__tianxiang|-liuli", "ty__xingwu", true, false)
    end
    if #player:getPile("ty__dance") > 0 and not (player:hasSkill("m_ex__tianxiang", true) and player:hasSkill("liuli", true)) then
      room:handleAddLoseSkills(player, "m_ex__tianxiang|liuli", "ty__xingwu", true, false)
    end
  end,
})

return luoyan
