local cuorui = fk.CreateSkill {
  name = "v11__cuorui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["v11__cuorui"] = "挫锐",
  [":v11__cuorui"] = "锁定技，当你登场时，你摸X-2张牌（X为你的备用武将数）；你跳过登场后的第一个判定阶段。",

  ["$v11__cuorui1"] = "区区乌合之众，如何困得住我？！",
  ["$v11__cuorui2"] = "今日就让你见识见识老牛的厉害！",
}

local U = require "packages.gamemode.pkg.1v1_generals.1v1_util"

cuorui:addEffect(U.Debut, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cuorui.name) and
      #player.room:getBanner(player.role == "lord" and "@&firstGenerals" or "@&secondGenerals") - 2 > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(#room:getBanner(player.role == "lord" and "@&firstGenerals" or "@&secondGenerals") - 2, cuorui.name)
  end,
})

cuorui:addEffect(fk.EventPhaseChanging, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cuorui.name) and data.phase == Player.Judge and
      player:usedEffectTimes(self.name, Player.HistoryGame) == 0 and not data.skipped
  end,
  on_use = function(self, event, target, player, data)
    data.skipped = true
  end,
})

return cuorui
