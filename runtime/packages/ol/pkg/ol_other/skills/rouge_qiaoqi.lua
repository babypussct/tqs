local qiaoqi = fk.CreateSkill {
  name = "rouge_qiaoqi",
  mode_skill = true,
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["rouge_qiaoqi"] = "巧器",
  [":rouge_qiaoqi"] = "锁定技，你每回合使用的第一张普通锦囊牌额外结算一次。",
}

local RougeUtil = require "packages.ol.pkg.ol_gamemode.rougelike1v1.util"

qiaoqi:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and RougeUtil.hasTalent(player, qiaoqi.name) and
      data.card:isCommonTrick() then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == player and e.data.card:isCommonTrick()
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_use = function(self, event, target, player, data)
    RougeUtil.sendTalentLog(player, qiaoqi.name)
    data.additionalEffect = (data.additionalEffect or 0) + 1
  end,
})

return qiaoqi
