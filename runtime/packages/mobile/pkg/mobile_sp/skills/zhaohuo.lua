local zhaohuo = fk.CreateSkill{
  name = "zhaohuo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhaohuo"] = "招祸",
  [":zhaohuo"] = "锁定技，当其他角色进入濒死状态时，若你的体力上限大于1，你将体力上限减至1点，然后你摸等同于体力上限减少数张牌。",

  ["$zhaohuo1"] = "我获罪于天，致使徐州之民，受此大难！",
  ["$zhaohuo2"] = "如此一来，徐州危矣……",
}

zhaohuo:addEffect(fk.EnterDying, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhaohuo.name) and target ~= player and player.maxHp > 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player.maxHp - 1
    room:changeMaxHp(player, -n)
    if not player.dead then
      player:drawCards(n, zhaohuo.name)
    end
  end,
})

return zhaohuo
