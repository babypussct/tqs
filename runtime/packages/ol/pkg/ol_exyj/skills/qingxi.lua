local qingxi = fk.CreateSkill {
  name = "ol_ex__qingxi",
}

Fk:loadTranslationTable{
  ["ol_ex__qingxi"] = "倾袭",
  [":ol_ex__qingxi"] = "当你使用【杀】造成伤害时，你可以选择一项：1.令目标弃置你攻击范围张牌；"..
  "2.令此【杀】伤害+1。若你的装备区有武器牌，则改为其依次执行这两项，然后弃置你装备区的武器牌。",

  ["#ol_ex__qingxi-invoke"] = "倾袭：是否对 %dest 发动“倾袭”？",
  ["ol_ex__qingxi_discard"] = "弃置%arg张牌",
  ["ol_ex__qingxi_damage"] = "伤害+1",

  ["$ol_ex__qingxi1"] = "策马倾出，奔袭破敌。",
  ["$ol_ex__qingxi2"] = "尽遣骁锐，倾袭敌军。",
}

qingxi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingxi.name) and
      data.card and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if #player:getEquipCards(Card.SubtypeWeapon) > 0 then
      if room:askToSkillInvoke(player, {
        skill_name = qingxi.name,
        prompt = "#ol_ex__qingxi-invoke::"..data.to.id,
      }) then
        event:setCostData(self, { tos = { data.to } })
        return true
      end
    else
      local choice = room:askToChoice(player, {
        skill_name = qingxi.name,
        prompt = "#ol_ex__qingxi-invoke::"..data.to.id,
        choices = { "ol_ex__qingxi_discard:::"..player:getAttackRange(), "ol_ex__qingxi_damage" },
        cancelable = true,
      })
      if choice ~= "Cancel" then
        event:setCostData(self, { tos = { data.to }, choice = choice })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getEquipCards(Card.SubtypeWeapon) > 0 then
      room:askToDiscard(data.to, {
        min_num = player:getAttackRange(),
        max_num = player:getAttackRange(),
        include_equip = true,
        skill_name = qingxi.name,
        cancelable = false,
      })
      data:changeDamage(1)
      room:throwCard(player:getEquipCards(Card.SubtypeWeapon), qingxi.name, player, player)
      return
    end
    local choice = event:getCostData(self).choice
    if choice == "ol_ex__qingxi_damage" then
      data:changeDamage(1)
    else
      room:askToDiscard(data.to, {
        min_num = player:getAttackRange(),
        max_num = player:getAttackRange(),
        include_equip = true,
        skill_name = qingxi.name,
        cancelable = false,
      })
    end
  end,
})

return qingxi
