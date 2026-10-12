
local chongqiq = fk.CreateSkill{
  name = "os__chongqiq",
}

Fk:loadTranslationTable{
  ["os__chongqiq"] = "冲骑",
  [":os__chongqiq"] = "每回合限一次，当你使用【杀】指定目标后，你可以弃置目标角色一张牌。"..
  "<a href='os__guerrilla'>游击</a>：此【杀】伤害+1。",

  ["#os__chongqiq-invoke"] = "冲骑：你可以弃置 %dest 一张牌",
}

chongqiq:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chongqiq.name) and
      data.card.trueName == "slash" and not data.to:isNude() and player:usedSkillTimes(chongqiq.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = chongqiq.name,
      prompt = "#os__chongqiq-invoke::"..data.to.id,
    }) then
      event:setCostData(self, { tos = {data.to} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = "he",
      skill_name = chongqiq.name,
    })
    room:throwCard(card, chongqiq.name, data.to, player)
    if player:inMyAttackRange(data.to) and not data.to:inMyAttackRange(player) then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

return chongqiq
