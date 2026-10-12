local mobileLiechi = fk.CreateSkill {
  name = "mobile__liechi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__liechi"] = "烈斥",
  [":mobile__liechi"] = "锁定技，当你进入濒死状态时，伤害来源弃置一张牌。",

  ["$mobile__liechi1"] = "吴狗，可敢和我一战！",
  ["$mobile__liechi2"] = "快滚，不要枉做了刀下亡魂！",
}

mobileLiechi:addEffect(fk.EnterDying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mobileLiechi.name) and data.damage and data.damage.from and data.damage.from:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, { data.damage.from })
    room:askToDiscard(
      data.damage.from,
      {
        min_num  = 1,
        max_num = 1,
        include_equip = true,
        skill_name = mobileLiechi.name,
        cancelable = false,
      }
    )
  end,
})

return mobileLiechi
