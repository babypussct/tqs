local xiaoguo = fk.CreateSkill {
  name = "hs__xiaoguo",
}

Fk:loadTranslationTable {
  ["hs__xiaoguo"] = "骁果",
  [":hs__xiaoguo"] = "其他角色的结束阶段，你可以弃置一张手牌对其造成1点伤害，然后其可以弃置一张装备区内的牌并回复1点体力。",

  ["#hs__xiaoguo-invoke"] = "骁果：你可以弃置一张手牌，对%dest 造成1点伤害",
  ["#hs__xiaoguo-discard"] = "骁果：你可以弃置装备区的一张牌，回复1点体力",

  ["$hs__xiaoguo1"] = "三军听我号令，不得撤退！",
  ["$hs__xiaoguo2"] = "看我先登城头，立下首功！",
}

xiaoguo:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xiaoguo.name) and target.phase == Player.Finish
    and not player:isKongcheng() and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = xiaoguo.name,
      cancelable = true,
      pattern = ".|.|.|hand|.|.|.",
      prompt = "#hs__xiaoguo-invoke::"..target.id,
      skip = true
    })
    if #card > 0 then
      event:setCostData(self, { tos = { target }, cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, xiaoguo.name, player, player)
    room:damage({
      from = player,
      to = target,
      damage = 1,
      skillName = xiaoguo.name,
    })
    if target.dead then return end
    if #room:askToDiscard(target, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = xiaoguo.name,
          cancelable = true,
          pattern = ".|.|.|equip|.|equip",
          prompt = "#hs__xiaoguo-discard",
        }) > 0 then
      if not player.dead then
        room:recover({
          who = target,
          num = 1,
          skillName = xiaoguo.name,
        })
      end
    end
  end,
})

return xiaoguo