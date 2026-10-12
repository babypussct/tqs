local niaoxiang = fk.CreateSkill{
  name = "niaoxiang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["niaoxiang"] = "鸟翔",
  [":niaoxiang"] = "阵法技，若你是围攻角色，此围攻关系中的围攻角色使用【杀】指定被围攻角色为目标后，你令被围攻角色响应此【杀】的方式改为依次使用两张【闪】。",

  ["$niaoxiang1"] = "此战，必是有死无生！",
  ["$niaoxiang2"] = "抢占先机，占尽优势！",
}

local H = require "packages.hegemony.util"

niaoxiang:addEffect("arraysummon", {
  array_type = "siege",
})

niaoxiang:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(niaoxiang.name) and data.card.trueName == "slash"
      and H.inSiegeRelation(target, player, data.to)
      and player:hasShownSkill(niaoxiang.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:setResponseTimes(2)
  end
})

return niaoxiang
