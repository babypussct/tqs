
local bawei = fk.CreateSkill{
  name = "m_heg__bawei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__bawei"] = "霸威",
  [":m_heg__bawei"] = "锁定技，本轮受到过你伤害的角色不能响应你同势力角色使用的牌。",

  ["$m_heg__bawei1"] = "还敢反抗，尔已忘我之威乎？",
  ["$m_heg__bawei2"] = "哼，贼心不死，必有后惩也！",
  ["$m_heg__bawei3"] = "不降者杀，复叛者尽屠其族！",
  ["$m_heg__bawei4"] = "为我手下败将，便休想再逞英雄！",
}

local H = require "packages.hegemony.util"

bawei:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target and H.compareKingdomWith(target, player) and player:hasSkill(bawei.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == player
      end, Player.HistoryRound) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room.logic:getActualDamageEvents(1, function (e)
      if e.data.from == player then
        data:setDisresponsive(e.data.to)
      end
    end, Player.HistoryRound)
  end,
})

return bawei
