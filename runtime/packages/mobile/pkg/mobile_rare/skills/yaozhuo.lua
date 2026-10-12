local yaozhuo = fk.CreateSkill {
  name = "changshi__yaozhuo",
}

Fk:loadTranslationTable{
  ["changshi__yaozhuo"] = "谣诼",
  [":changshi__yaozhuo"] = "出牌阶段限一次，你可以与一名角色拼点。若你：赢，跳过其下个摸牌阶段；没赢：你弃置两张牌。",

  ["#changshi__yaozhuo"] = "谣诼：与一名角色拼点，若赢，跳过其下个摸牌阶段；若没赢，你弃两张牌",
  ["@@changshi__yaozhuo"] = "谣诼",

  ["$changshi__yaozhuo1"] = "上蔽天听，下诓朝野！",
}

yaozhuo:addEffect("active", {
  anim_type = "control",
  prompt = "#changshi__yaozhuo",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(yaozhuo.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({ target }, yaozhuo.name)
    if pindian.results[target].winner == player then
      if not target.dead then
        room:setPlayerMark(target, "@@changshi__yaozhuo", 1)
      end
    elseif not player.dead then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = yaozhuo.name,
        cancelable = false,
      })
    end
  end,
})
yaozhuo:addEffect(fk.EventPhaseChanging, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@changshi__yaozhuo") > 0 and data.phase == Player.Draw
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@changshi__yaozhuo", 0)
    data.skipped = true
  end,
})

return yaozhuo
