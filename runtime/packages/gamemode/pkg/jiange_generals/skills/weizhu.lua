local weizhu = fk.CreateSkill {
  name = "jiange__weizhu",
}

Fk:loadTranslationTable{
  ["jiange__weizhu"] = "卫主",
  [":jiange__weizhu"] = "当友方角色受到伤害时，你可以弃置一张手牌，防止此伤害。",

  ["#jiange__weizhu-invoke"] = "卫主：你可以弃置一张手牌，防止 %dest 受到的伤害",
}

weizhu:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, _, target, player, data)
    return player:hasSkill(weizhu.name) and target:isFriend(player) and not player:isKongcheng()
  end,
  on_cost  = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = weizhu.name,
      cancelable = true,
      prompt = "#jiange__weizhu-invoke::"..target.id,
      skip = true
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use  = function(self, event, target, player, data)
    data:preventDamage()
    player.room:throwCard(event:getCostData(self).cards, weizhu.name, player, player)
  end,
})

return weizhu
