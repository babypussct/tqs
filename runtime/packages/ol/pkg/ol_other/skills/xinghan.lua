local xinghan = fk.CreateSkill {
  name = "ol__xinghan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ol__xinghan"] = "兴汉",
  [":ol__xinghan"] = "限定技，出牌阶段，你可以失去任意个战法，然后你购买的下X个战法不消耗虎符，且你每以此法失去一个战法，"..
  "依次获得以下一个专属战法：<a href=':rouge_dongfeng'>“东风”</a>、<a href=':rouge_qiaoqi'>“巧器”</a>。",

  ["#ol__xinghan"] = "兴汉：失去任意个战法，获得等量专属战法，且购买下等量个战法不消耗虎符",
  ["@ol__xinghan"] = "兴汉",

  ["$ol__xinghan1"] = "三兴之业，试问天下谁可阻？",
  ["$ol__xinghan2"] = "威加海内兮归故乡，今得猛士兮守四方！",
}

local RougeUtil = require "packages.ol.pkg.ol_gamemode.rougelike1v1.util"

xinghan:addEffect("active", {
  anim_type = "special",
  prompt = "#ol__xinghan",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(xinghan.name, Player.HistoryGame) == 0 and
      #player:getTableMark("@[rouge1v1]mark") > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local choices = room:askToChoices(player, {
      min_num = 1,
      max_num = 999,
      choices = player:getTableMark("@[rouge1v1]mark"),
      detailed = true,
      skill_name = xinghan.name,
      prompt = "#ol__xinghan",
      cancelable = true,
    })
    if #choices > 0 then
      room:addPlayerMark(player, "@ol__xinghan", #choices)
      for _, choice in ipairs(choices) do
        room:removeTableMark(player, "@[rouge1v1]mark", choice)
      end
      RougeUtil.attachTalentToPlayer(player, "rouge_dongfeng")
      room:addSkill("rouge_dongfeng")
      if #choices > 1 then
        RougeUtil.attachTalentToPlayer(player, "rouge_qiaoqi")
        room:addSkill("rouge_qiaoqi")
      end
    end
  end,
})

return xinghan
