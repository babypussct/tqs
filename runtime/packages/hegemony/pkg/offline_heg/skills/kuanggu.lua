local kuanggu = fk.CreateSkill{
  name = "ofl_heg__kuanggu",
}

Fk:loadTranslationTable{
  ["ofl_heg__kuanggu"] = "狂骨",
  [":ofl_heg__kuanggu"] = "当造成或受到1点伤害时，你可以摸一张牌；你使用仅指定唯一目标的伤害牌可以额外指定至多X个目标（X为你已损失体力值+1）。",

  ["#ofl_heg__kuanggu-choose"] = "狂骨：你可以为此%arg额外指定至多%arg2个目标",

  ["$ofl_heg__kuanggu1"] = "哈哈哈哈哈哈，赢你还不容易？",
  ["$ofl_heg__kuanggu2"] = "哼！也不看看我是何人！",
}

local spec = {
  anim_type = "drawcard",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuanggu.name)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, kuanggu.name)
  end,
}
kuanggu:addEffect(fk.DamageCaused, spec)
kuanggu:addEffect(fk.DamageInflicted, spec)

kuanggu:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuanggu.name) and
      data.card.is_damage_card and #data.tos == 1 and #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = player:getLostHp() + 1,
      targets = data:getExtraTargets(),
      skill_name = kuanggu.name,
      prompt = "#ofl_heg__kuanggu-choose:::"..data.card:toLogString()..":"..player:getLostHp() + 1,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
  end,
})

return kuanggu
