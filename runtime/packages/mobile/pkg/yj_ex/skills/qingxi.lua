
local qingxi = fk.CreateSkill {
  name = "m_ex__qingxi",
}

Fk:loadTranslationTable{
  ["m_ex__qingxi"] = "倾袭",
  [":m_ex__qingxi"] = "每回合限一次，当你对其他角色造成伤害时，你可以令其选择一项："..
  "1.弃置Y张手牌（Y为4-你与其距离，且至少为1）；2.令此伤害+1。",

  ["#m_ex__qingxi-invoke"] = "倾袭：你可以对 %dest 发动“倾袭”，令其选择弃牌或伤害+1",

  ["$m_ex__qingxi1"] = "弟兄们，统统给我上！",
  ["$m_ex__qingxi2"] = "我虎豹骑不可有败绩！",
}

qingxi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingxi.name) and
      data.to ~= player and not data.to.dead and
      player:usedSkillTimes(qingxi.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = qingxi.name,
      prompt = "#m_ex__qingxi-invoke::"..data.to.id,
    }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.max(player:distanceTo(data.to), 1)
    if #room:askToDiscard(data.to, {
      min_num = n,
      max_num = n,
      include_equip = false,
      skill_name = qingxi.name,
      prompt = "#qingxi-discard:::" .. n,
    }) == 0
    then
      data:changeDamage(1)
    end
  end,
})

return qingxi
