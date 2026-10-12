local dulie = fk.CreateSkill {
  name = "dulie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dulie"] = "笃烈",
  [":dulie"] = "锁定技，当你成为体力值大于你的角色使用【杀】的目标时，你判定，若结果为<font color='red'>♥</font>，取消之。",

  ["$dulie1"] = "素来言出必践，成吾信义昭彰！",
  ["$dulie2"] = "小信如若不成，大信将以何立？",
}

dulie:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dulie.name) and data.card.trueName == "slash" and
      data.from.hp > player.hp and not data.cancelled
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = dulie.name,
      pattern = ".|.|heart",
    }
    room:judge(judge)
    if judge:matchPattern() then
      data:cancelCurrentTarget()
    end
  end,
})

return dulie
