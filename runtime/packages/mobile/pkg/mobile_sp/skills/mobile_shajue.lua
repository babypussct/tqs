local mobileShajue = fk.CreateSkill {
  name = "mobile__shajue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__shajue"] = "杀绝",
  [":mobile__shajue"] = "锁定技，其他角色进入濒死状态时，若其需要超过一张【桃】或【酒】救回，你获得一个“暴戾”标记且获得使其进入濒死状态的牌。",

  ["$mobile__shajue1"] = "现在才投降？有些太晚了哦。",
  ["$mobile__shajue2"] = "与我们为敌的人，一个都不用留。",
}

mobileShajue:addEffect(fk.EnterDying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and target.hp < 0 and player:hasSkill(mobileShajue.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@mobile__baoli", 1)
    if data.damage and data.damage.card and room:getCardArea(data.damage.card) == Card.Processing then
      room:obtainCard(player, data.damage.card, true, fk.ReasonPrey, player)
    end
  end,
})

return mobileShajue
