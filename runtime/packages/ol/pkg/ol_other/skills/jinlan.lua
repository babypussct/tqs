local jinlan = fk.CreateSkill{
  name = "nos__jinlan",
}

Fk:loadTranslationTable{
  ["nos__jinlan"] = "尽览",
  [":nos__jinlan"] = "出牌阶段限一次，你可以将手牌摸至X张（X为存活角色中技能最多角色的技能数）。",

  ["#nos__jinlan"] = "尽览：你可以将手牌摸至%arg张",

  ["$nos__jinlan1"] = "",
  ["$nos__jinlan2"] = "",
}

jinlan:addEffect("active", {
  anim_type = "drawcard",
  prompt = function(self, player)
    local n = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      local tmp = #p:getSkillNameList()
      if tmp > n then
        n = tmp
      end
    end
    return "#nos__jinlan:::"..n
  end,
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(jinlan.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function (p)
        return player:getHandcardNum() < #p:getSkillNameList()
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local n = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      local tmp = #p:getSkillNameList()
      if tmp > n then
        n = tmp
      end
    end
    player:drawCards(n - player:getHandcardNum(), jinlan.name)
  end,
})

return jinlan
