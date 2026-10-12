local duodao = fk.CreateSkill{
  name = "m_ex__duodao",
}

Fk:loadTranslationTable{
  ["m_ex__duodao"] = "夺刀",
  [":m_ex__duodao"] = "当你受到伤害后，你可以获得伤害来源装备区里的武器牌。",

  ["#m_ex__duodao-invoke"] = "夺刀：你可以获得 %dest 装备区的武器牌",

  ["$m_ex__duodao1"] = "避其锋芒，夺其兵刃！",
  ["$m_ex__duodao2"] = "好兵器啊！哈哈哈！",
}

duodao:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duodao.name) and data.from and #data.from:getEquipments(Card.SubtypeWeapon) > 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = duodao.name,
      prompt = "#m_ex__duodao-invoke::"..data.from.id
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.from:getEquipments(Card.SubtypeWeapon), true, fk.ReasonPrey, data.from, duodao.name)
  end
})

return duodao
