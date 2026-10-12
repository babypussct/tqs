
local dandao = fk.CreateSkill{
  name = "dandao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dandao"] = "耽道",
  [":dandao"] = "锁定技，每名角色首次判定后，你的体力上限+1。",

  ["$dandao1"] = "吾志在学，不在仕。",
  ["$dandao2"] = "愿为学海之舟，耻为樊笼之雀。",
}

dandao:addEffect(fk.FinishJudge, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(dandao.name) then
      local judge_event = player.room.logic:getEventsOfScope(GameEvent.Judge, 1, function (e)
        return e.data.who == target
      end, Player.HistoryGame)
      return #judge_event == 1 and judge_event[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:changeMaxHp(player, 1)
  end,
})

return dandao