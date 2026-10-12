local dawu = fk.CreateSkill {
  name = "aux_dawu",
}

--便于大雾标记多处引用（如剑阁天侯孔明，各种diy）
--在增加标记时将此技能add到房间即可
Fk:loadTranslationTable{
  ["aux_dawu"] = "大雾",
  ["@@dawu"] = "大雾",
}

dawu:addEffect(fk.DamageInflicted, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@dawu") > 0 and data.damageType ~= fk.ThunderDamage
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end
})

return dawu
