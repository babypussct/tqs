local zhendu = fk.CreateSkill {
  name = "zhendu",
}

Fk:loadTranslationTable{
  ["zhendu"] = "鸩毒",
  ["#zhendu-invoke"] = "鸩毒：你可以弃置一张手牌视为 %dest 使用一张【酒】，然后你对其造成1点伤害",
  [":zhendu"] = "其他角色的出牌阶段开始时，你可弃置一张手牌，其视为使用一张【酒】，然后你对其造成1点伤害。",
  ["$zhendu1"] = "怪只怪你，不该生有皇子！",
  ["$zhendu2"] = "后宫之中，岂有你的位置！"
}

zhendu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Play and player:hasSkill(zhendu.name) and target ~= player
      and not player:isKongcheng() and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = zhendu.name,
      cancelable = true,
      pattern = ".|.|.|hand",
      prompt = "#zhendu-invoke::" .. target.id,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, zhendu.name, player, player)
    if not target.dead and target:canUseTo(Fk:cloneCard("analeptic"), target) then
      room:useVirtualCard("analeptic", nil, target, target, zhendu.name, false)
      if target.dead then return end
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = zhendu.name,
      }
    end
  end,
})

return zhendu
