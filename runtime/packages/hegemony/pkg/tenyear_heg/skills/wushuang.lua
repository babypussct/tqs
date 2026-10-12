local wushuang = fk.CreateSkill {
  name = "ty_heg_lvlingqi__wushuang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty_heg_lvlingqi__wushuang"] = "无双",
  [":ty_heg_lvlingqi__wushuang"] = "锁定技，当你使用【杀】指定目标后，其使用【闪】抵消此【杀】的方式改为需连续使用两张【闪】；"..
  "当你使用【决斗】指定目标后，或当你成为【决斗】的目标后，你令其打出【杀】响应此【决斗】的方式改为需连续打出两张【杀】。",

  ["$ty_heg_lvlingqi__wushuang1"] = "猛将策良骥，长戟破敌营。",
  ["$ty_heg_lvlingqi__wushuang2"] = "杀气腾剑戟，严风卷戎装。",
}

---@type TrigSkelSpec<AimFunc>
local spec = {
  on_use = function(self, event, target, player, data)
    local to = (event == fk.TargetConfirmed and data.card.trueName == "duel") and data.from or data.to
    data:setResponseTimes(2, to)
  end,
}

wushuang:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wushuang.name) and
      table.contains({ "slash", "duel" }, data.card.trueName)
  end,
  on_use = spec.on_use
})

wushuang:addEffect(fk.TargetConfirmed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wushuang.name) and data.card.trueName == "duel"
  end,
  on_use = spec.on_use
})

return wushuang
