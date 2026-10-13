local cesuan = fk.CreateSkill {
  name = "cesuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["cesuan"] = "策算",
  [":cesuan"] = "锁定技，当你受到伤害时，你防止此伤害，若你的体力：小于体力上限，你减1点体力上限；不小于体力上限，你减1点体力上限，摸一张牌。",
}

cesuan:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    if player.hp < player.maxHp then
      room:changeMaxHp(player, -1)
    else
      room:changeMaxHp(player, -1)
      if not player.dead then
        player:drawCards(1, cesuan.name)
      end
    end
  end,
})

return cesuan
