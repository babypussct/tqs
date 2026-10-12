
local chibi = fk.CreateSkill {
  name = "chibi",
}

Fk:loadTranslationTable{
  ["chibi"] = "斥避",
  [":chibi"] = "当其他角色使用牌指定距离其大于1的角色为目标时，你可以与其拼点，若你：赢，你令此牌无效并获得此牌；" ..
  "没赢，你成为此牌的额外目标，且此技能本回合失效。",

  ["#chibi-invoke"] = "斥避：你可以与 %dest 拼点，若赢则此%arg无效且你获得之，若没赢则成为额外目标",

  ["$chibi1"] = "凉州鄙夫，安敢立马君前！",
  ["$chibi2"] = "退！退！退！",
}

chibi:addEffect(fk.TargetSpecifying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(chibi.name) and
      data.to:compareDistance(target, 1, ">") and player:canPindian(target)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = chibi.name,
      prompt = "#chibi-invoke::" .. target.id .. ":".. data.card:toLogString(),
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = chibi.name
    local room = player.room
    local pindian = player:pindian({ target }, skillName)
    if not player:isAlive() then
      return false
    end

    if pindian.results[target].winner == player then
      data:cancelAllTarget()
      if room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player, data.card, true, fk.ReasonPrey, player, skillName)
      end
    else
      if table.contains(data:getExtraTargets({ bypass_distances = true, bypass_times = true }), player) then
        room:doIndicate(target, player)
        data:addTarget(player)
      end
      room:invalidateSkill(player, skillName, "-turn")
    end
  end,
})

return chibi
