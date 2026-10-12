
local xiaoguo = fk.CreateSkill{
  name = "nos__xiaoguo",
}

Fk:loadTranslationTable{
  ["nos__xiaoguo"] = "骁果",
  [":nos__xiaoguo"] = "其他角色的结束阶段，你可以弃置一张基本牌，然后除非该角色弃置一张装备牌，否则你对其造成1点伤害。",

  ["#nos__xiaoguo-invoke"] = "骁果：弃一张基本牌，%dest 需弃置一张装备牌，否则你对其造成1点伤害",
  ["#nos__xiaoguo-discard"] = "骁果：弃置一张装备牌，否则 %src 对你造成1点伤害",

  ["$nos__xiaoguo1"] = "三军听我号令，不得撤退！",
  ["$nos__xiaoguo2"] = "看我先登城头，立下首功！",
}

xiaoguo:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish
      and not player:isKongcheng() and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = xiaoguo.name,
      cancelable = true,
      pattern = ".|.|.|.|.|basic",
      prompt = "#nos__xiaoguo-invoke::" .. target.id,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, xiaoguo.name, player, player)
    if target.dead then return end
    if #room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = xiaoguo.name,
      cancelable = true,
      pattern = ".|.|.|.|.|equip",
      prompt = "#nos__xiaoguo-discard:" .. player.id,
    }) == 0 then
      room:damage {
        from = player,
        to = target,
        damage = 1,
        skillName = xiaoguo.name,
      }
    end
  end,
})

return xiaoguo
