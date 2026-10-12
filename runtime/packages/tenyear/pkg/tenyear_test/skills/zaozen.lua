
local zaozen = fk.CreateSkill {
  name = "zaozen",
  attached_skill_name = "zaozen&",
}

Fk:loadTranslationTable{
  ["zaozen"] = "遭谮",
  [":zaozen"] = "其他角色出牌阶段限一次，其可以弃置一张非基本牌，然后令你视为对一名角色使用一张【杀】，"..
  "若此【杀】造成伤害，本回合你视为所有【杀】的使用者；若此【杀】未造成伤害，你视为对当前回合角色依次使用两张【杀】。",

  ["@@zaozen-turn"] = "遭谮",

  ["$zaozen1"] = "",
  ["$zaozen2"] = "",
}

zaozen:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return player:getMark("@@zaozen-turn") > 0 and data.card.trueName == "slash"
  end,
  on_refresh = function (self, event, target, player, data)
    data.from = player
  end,
})

return zaozen
