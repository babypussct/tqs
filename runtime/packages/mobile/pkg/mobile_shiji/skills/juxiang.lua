local juxiang = fk.CreateSkill {
  name = "juxiangz",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["juxiangz"] = "拒降",
  [":juxiangz"] = "限定技，当一名其他角色的濒死结算结束后，你可对其造成1点伤害。",

  ["#juxiangz-invoke"] = "拒降：你可以对 %dest 造成1点伤害！",

  ["$juxiangz1"] = "今非秦项之际，如若受之，徒增逆意！",
  ["$juxiangz2"] = "兵有形同而势异者，此次乞降断不可受！",
}

juxiang:addEffect(fk.AfterDying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(juxiang.name) and not target.dead and
      player:usedSkillTimes(juxiang.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = juxiang.name,
      prompt = "#juxiangz-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = juxiang.name,
    }
  end,
})

return juxiang
