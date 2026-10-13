local longwei = fk.CreateSkill {
  name = "jiange__longwei",
}

Fk:loadTranslationTable{
  ["jiange__longwei"] = "龙威",
  [":jiange__longwei"] = "当友方角色进入濒死状态时，你可以减1点体力上限，令其回复1点体力。",

  ["#jiange__longwei-invoke"] = "龙威：是否减1点体力上限，令 %dest 回复1点体力？",
}

longwei:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(longwei.name) and target:isFriend(player) and target.dying
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = longwei.name,
      prompt = "#jiange__longwei-invoke::" .. target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if target:isWounded() and not target.dead then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = longwei.name,
      }
    end
  end,
})

return longwei
