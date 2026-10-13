local shuhun = fk.CreateSkill {
  name = "jiange__shuhun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__shuhun"] = "蜀魂",
  [":jiange__shuhun"] = "锁定技，当你造成伤害后，你令随机一名友方角色回复1点体力。",
}

shuhun:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shuhun.name) and
      table.find(player:getFriends(), function (p)
        return p:isWounded()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:tableRandomPick(table.filter(player:getFriends(), function (p)
      return p:isWounded()
    end))
    room:doIndicate(player, {to})
    room:recover{
      who = to,
      num = 1,
      recoverBy = player,
      skill_name = shuhun.name,
    }
  end,
})

return shuhun
