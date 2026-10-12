
local niaoxiang = fk.CreateSkill{
  name = "m_heg__niaoxiang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__niaoxiang"] = "鸟翔",
  [":m_heg__niaoxiang"] = "<a href='m_heg_summon'>阵法技</a>，锁定技，你使用的红色【杀】需两张【闪】才能抵消；"..
  "你围攻一名角色时，改为【杀】均可触发此效果。",

  ["$m_heg__niaoxiang1"] = "此战，必是有死无生！",
  ["$m_heg__niaoxiang2"] = "抢占先机，占尽优势！",
}

local H = require "packages.hegemony.util"

niaoxiang:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(niaoxiang.name) and
      data.card.trueName == "slash" then
      if data.card.color == Card.Red then
        return true
      elseif player:hasShownSkill(niaoxiang.name) then
        return table.find(player.room.alive_players, function (p)
          return H.inSiegeRelation(player, player, p)
        end)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data:setResponseTimes(2)
  end
})

return niaoxiang
