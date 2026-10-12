local anjian = fk.CreateSkill{
  name = "m_ex__anjian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_ex__anjian"] = "暗箭",
  [":m_ex__anjian"] = "锁定技，当你使用【杀】指定一名角色为目标后，若你不在其攻击范围内，你选择一项：1.令其不能响应此【杀】；2.此【杀】对其造成的基础伤害值+1。",

  ["#m_ex__anjian-choice"] = "暗箭：令 %dest 不能响应此【杀】或受到此【杀】伤害+1",
  ["m_ex__anjian_disresponsive"] = "不可响应",
  ["m_ex__anjian_damage"] = "伤害+1",

  ["$m_ex__anjian1"] = "看我一箭索命！",
  ["$m_ex__anjian2"] = "明枪易躲，暗箭难防！",
}

anjian:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(anjian.name) and data.card.trueName == "slash" and
    not (data.to.dead or data.to:inMyAttackRange(player))
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = {"m_ex__anjian_disresponsive", "m_ex__anjian_damage", "Cancel"},
      skill_name = anjian.name,
      prompt = "#m_ex__anjian-choice::"..data.to.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {data.to}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "m_ex__anjian_disresponsive" then
      data.disresponsive = true
    else
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

return anjian
