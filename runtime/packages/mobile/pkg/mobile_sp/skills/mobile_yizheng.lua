local mobileYizheng = fk.CreateSkill {
  name = "mobile__yizheng",
}

Fk:loadTranslationTable{
  ["mobile__yizheng"] = "义争",
  [":mobile__yizheng"] = "出牌阶段限一次，你可以与一名体力值不大于你的角色拼点。若你：赢，跳过其下个摸牌阶段；没赢，你减1点体力上限。",

  ["@@mobile__yizheng"] = "义争",

  ["$mobile__yizheng1"] = "一人劫天子，一人质公卿，此可行邪？",
  ["$mobile__yizheng2"] = "诸军举事，当上顺天心，奈何如是！",
}

mobileYizheng:addEffect("active", {
  anim_type = "control",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(mobileYizheng.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return
      #selected < 1 and
      player.id ~= to_select and
      player.hp >= to_select.hp and
      player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local from = effect.from
    local to = effect.tos[1]
    local pindian = from:pindian({ to }, mobileYizheng.name)
    if pindian.results[to].winner == from then
      room:setPlayerMark(to, "@@mobile__yizheng", 1)
    else
      room:changeMaxHp(from, -1)
    end
  end,
})

mobileYizheng:addEffect(fk.EventPhaseChanging, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.phase == Player.Draw and
      not data.skipped and
      player:getMark("@@mobile__yizheng") > 0
  end,
  on_cost = Util.TrueFunc,
  on_trigger = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@mobile__yizheng", 0)
    data.skipped = true
  end,
})

return mobileYizheng
