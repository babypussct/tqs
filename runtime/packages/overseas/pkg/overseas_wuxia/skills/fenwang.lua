local fenwang = fk.CreateSkill {
  name = "os__fenwang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__fenwang"] = "焚亡",
  [":os__fenwang"] = "锁定技，当你受到属性伤害时，你须弃置一张手牌，否则此伤害+1。"..
  "当你对其他角色造成普通伤害时，若你的手牌数不小于其手牌数，此伤害+1。",

  ["#os__fenwang-discard"] = "焚亡：弃置一张手牌，否则此伤害+1",

  ["$os__fenwang1"] = "洛阳逢此大难，吾，亦难脱身。",
  ["$os__fenwang2"] = "大火之下，黑影，已无所遁形！",
}

fenwang:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  audio_index = 1,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fenwang.name) and data.damageType ~= fk.NormalDamage
  end,
  on_use = function(self, event, target, player, data)
    if #player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = fenwang.name,
      cancelable = true,
      prompt = "#os__fenwang-discard",
    }) == 0 then
      data:changeDamage(1)
    end
  end,
})

fenwang:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  audio_index = 2,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to ~= player and player:hasSkill(fenwang.name) and
      data.damageType == fk.NormalDamage and player:getHandcardNum() >= data.to:getHandcardNum()
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return fenwang
