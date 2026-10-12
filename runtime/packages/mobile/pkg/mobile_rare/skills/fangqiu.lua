local fangqiu = fk.CreateSkill {
  name = "fangqiu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["fangqiu"] = "方遒",
  [":fangqiu"] = "限定技，当你执行<a href='wolongyance'>“卧龙演策”</a>。后，你可以展示你的“卧龙演策”预测，若如此做，本次“卧龙演策”的预测全部验证后，执行效果的值均+1；"..
  "若预测牌数大于3且全部正确，重置此技能。",
  ["#fangqiu-invoke"] = "方遒：是否令本次“卧龙演策”预测公开？全部验证后执行的效果+1",

  ["$fangqiu1"] = "一举可成之事，何必再增变数。",
  ["$fangqiu2"] = "破敌便在此刻，吾等勿负良机。",
  ["$fangqiu3"] = "哈哈哈哈，果不出我所料。",
}
local U = require "packages.utility.utility"

fangqiu:addEffect(fk.AfterSkillEffect, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fangqiu.name) and
      player:usedSkillTimes(fangqiu.name, Player.HistoryGame) == 0 and
      (data.skill.name == "yance" or data.skill.name == "#yance_2_trig") and
      U.getPrivateMark(player,"yance") ~= {}
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = fangqiu.name,
      prompt = "#fangqiu-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "fangqiu_trigger", 1)
    U.showPrivateMark(player,"yance")
  end,
})

return fangqiu
