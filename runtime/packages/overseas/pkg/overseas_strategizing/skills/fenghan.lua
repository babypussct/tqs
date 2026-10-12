local fenghan = fk.CreateSkill {
  name = "os__fenghan",
}

Fk:loadTranslationTable{
  ["os__fenghan"] = "锋悍",
  [":os__fenghan"] = "每回合限一次，当你使用【杀】或伤害锦囊牌指定目标后，你可以令至多X名角色摸一张牌（X为目标数）。",

  ["#os__fenghan-choose"] = "锋悍：你可以令至多%arg名角色各摸一张牌",
}

fenghan:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fenghan.name) and
      data.card.is_damage_card and data.firstTarget and player:usedSkillTimes(fenghan.name, Player.HistoryTurn) < 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local num = #data.use.tos
    local tos = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = num,
      prompt = "#os__fenghan-ask:::" .. num,
      skill_name = fenghan.name,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        p:drawCards(1, fenghan.name)
      end
    end
  end,
})

return fenghan
