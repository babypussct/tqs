local kuangfeng = fk.CreateSkill {
  name = "aux_kuangfeng",
}

--鉴于狂风标记多处引用（如剑阁天侯孔明，各种diy），当房间出现多个狂风技能时会重复增伤
--因此除神诸葛亮本体外，其他狂风标记技能均在增加标记时将此技能add到房间即可
Fk:loadTranslationTable{
  ["aux_kuangfeng"] = "狂风",
  ["@@kuangfeng"] = "狂风",
}

kuangfeng:addEffect(fk.DamageInflicted, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player.room:hasSkill("kuangfeng") then
      return target == player and player:getMark("@@kuangfeng") > 0 and data.damageType == fk.FireDamage
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return kuangfeng
