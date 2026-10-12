local qingjue = fk.CreateSkill {
  name = "qingjue",
}

Fk:loadTranslationTable{
  ["qingjue"] = "请决",
  [":qingjue"] = "每轮限一次，一名其他角色使用牌指定一名体力值小于其的其他角色为唯一目标时，若没有角色处于濒死状态，你可以摸一张牌，与使用者拼点，"..
  "若你赢或你不是此牌合法目标，取消此牌；若你没赢且是此牌合法目标，此牌目标转移为你。",

  ["#qingjue-invoke"] = "请决：%src 对 %dest 使用%arg，你可以摸一张牌与 %src 拼点，若赢则取消之，若没赢则转移给你",

  ["$qingjue1"] = "兵者，凶器也，宜不得已而用之。",
  ["$qingjue2"] = "民安土重迁，易以顺行，难以逆动。",
  ["$qingjue3"] = "鼓之以道德，征之以仁义，才可得百姓之心。",
}

qingjue:addEffect(fk.TargetSpecifying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qingjue.name) and target ~= player and not data.cancelled and
      data:isOnlyTarget(data.to) and data.to ~= player and target.hp > data.to.hp and
      not table.find(player.room.alive_players, function(p)
        return p.dying
      end) and
      player:usedSkillTimes(qingjue.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = qingjue.name,
      prompt = "#qingjue-invoke:"..target.id..":"..data.to.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, qingjue.name)
    if player.dead or target.dead or not player:canPindian(target) then return end
    local pindian = player:pindian({target}, qingjue.name)
    data:cancelAllTarget()
    if pindian.results[target].winner == player then
    else
      if target:canUseTo(data.card, player, {bypass_distances = true, bypass_times = true}) then
        data:addTarget(player)
      end
    end
  end,
})

return qingjue
