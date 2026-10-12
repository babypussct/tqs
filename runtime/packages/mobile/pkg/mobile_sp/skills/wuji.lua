local wuji = fk.CreateSkill {
  name = "mobile__wuji",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["mobile__wuji"] = "武继",
  [":mobile__wuji"] = "限定技，出牌阶段，你可以修改〖雪恨〗（使用“雪恨”牌后摸一张牌）直到本阶段结束；若你本阶段因〖雪恨〗获得至少两张牌，"..
  "你改为永久修改〖雪恨〗。",

  ["#mobile__wuji"] = "武继：本阶段修改“雪恨”，使用“雪恨”牌后摸一张牌！",

  ["$mobile__wuji1"] = "父兄的武艺，我已经学成了！",
  ["$mobile__wuji2"] = "青龙偃月刀，与我共战沙场吧！",
}

wuji:addEffect("active", {
  anim_type = "offensive",
  prompt = "#mobile__wuji",
  card_num = 0,
  mtarget_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(wuji.name, Player.HistoryGame) == 0 and
      player:hasSkill("mobile__xuehen", true)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:setPlayerMark(player, "mobile__xuehen-phase", 1)
  end,
})

return wuji
