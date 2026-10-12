
local jianweic = fk.CreateSkill {
  name = "jianweic",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jianweic"] = "坚卫",
  [":jianweic"] = "锁定技，你的起始手牌数+4。摸牌阶段，若你手牌数小于2，你多摸四张牌。",

  ["$jianweic1"] = "",
  ["$jianweic2"] = "",
}

jianweic:addEffect(fk.DrawInitialCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianweic.name)
  end,
  on_use = function(self, event, target, player, data)
    data.num = data.num + 4
  end,
})

jianweic:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianweic.name) and
      player:getHandcardNum() < 2
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 4
  end,
})

return jianweic
