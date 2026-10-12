local luanchou = fk.CreateSkill {
  name = "luanchou",
  related_skills = { "gonghuan" },
}

Fk:loadTranslationTable{
  ["luanchou"] = "鸾俦",
  [":luanchou"] = "出牌阶段限一次，你可以移除场上所有“姻”标记并选择两名角色，令其获得“姻”。有“姻”的角色视为拥有技能〖共患〗。",

  ["#luanchou"] = "鸾俦：令两名角色获得“姻”标记并获得技能〖共患〗",
  ["@@luanchou"] = "姻",

  ["$luanchou1"] = "愿汝永结鸾俦，以期共盟鸳蝶。",
  ["$luanchou2"] = "夫妻相濡以沫，方可百年偕老。",
}

luanchou:addEffect("active", {
  anim_type = "support",
  prompt = "#luanchou",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(luanchou.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  on_use = function(self, room, effect)
    for _, p in ipairs(room:getAlivePlayers()) do
      if table.contains(effect.tos, p) then
        room:setPlayerMark(p, "@@luanchou", 1)
        room:handleAddLoseSkills(p, "gonghuan")
      elseif p:hasSkill("gonghuan", true) then
        room:setPlayerMark(p, "@@luanchou", 0)
        room:handleAddLoseSkills(p, "-gonghuan")
      end
    end
  end,
})

return luanchou
