local dragonPhoenixSkill = fk.CreateSkill{
  name = "#dragon_phoenix_skill",
  attached_equip = "dragon_phoenix",
}
dragonPhoenixSkill:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(dragonPhoenixSkill.name) then return end
    if target == player and data.card and data.card.trueName == "slash" then
      return not data.to:isNude()
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = dragonPhoenixSkill.name, prompt = "#dragon_phoenix-slash::" .. data.to.id})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    -- room:setEmotion(player, "./packages/hegemony/image/anim/dragon_phoenix")
    room:askToDiscard(data.to, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = dragonPhoenixSkill.name,
      cancelable = false,
      prompt = "#dragon_phoenix-invoke",
    })
  end,
})
dragonPhoenixSkill:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dragonPhoenixSkill.name) and data.damage and data.damage.from == player and
      not target:isKongcheng() and player.room.logic:damageByCardEffect() and data.damage.card.trueName == "slash"
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = dragonPhoenixSkill.name, prompt = "#dragon_phoenix-dying::" .. target.id})
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    -- room:setEmotion(player, "./packages/hegemony/image/anim/dragon_phoenix")
    local card = room:askToChooseCard(player, {
    target = target,
    flag = "h",
    skill_name = dragonPhoenixSkill.name,
  })
    room:obtainCard(player, card, false, fk.ReasonPrey)
  end
})

Fk:loadTranslationTable{
  ["#dragon_phoenix_skill"] = "飞龙夺凤",
  ["#dragon_phoenix-slash"] = "飞龙夺凤：你可令 %dest 弃置一张牌",
  ["#dragon_phoenix-dying"] = "飞龙夺凤：你可获得 %dest 一张手牌",
  ["#dragon_phoenix-invoke"] = "受到“飞龙夺凤”影响，你需弃置一张牌",
}

return dragonPhoenixSkill
