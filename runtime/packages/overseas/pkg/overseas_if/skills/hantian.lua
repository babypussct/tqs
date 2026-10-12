local hantian = fk.CreateSkill {
  name = "os__hantian",
}

Fk:loadTranslationTable{
  ["os__hantian"] = "撼天",
  [":os__hantian"] = "出牌阶段限一次，你可视为使用一张【火攻】，目标须优先展示其本回合获得的牌。" ..
  "你造成的火焰伤害+X（X为受到伤害角色本回合获得牌的次数）。",

  ["os__hantian-active"] = "撼天：视为使用【火攻】，目标须展示其本回合获得的牌",
  ["os__hantian_normal-active"] = "撼天：视为使用【火攻】",

  ["$os__hantian1"] = "撼天焚江，焰吞万里！",
  ["$os__hantian2"] = "此火仅为小诫，再犯必不留情！",
}

hantian:addEffect("viewas", {
  anim_type = "offensive",
  prompt = function (self, player, selected_cards, selected)
    return #selected > 0 and table.find(selected, function(s) return s:getMark("_os__hantian_cards-turn") ~= 0 end)
      and "os__hantian-active" or "os__hantian_normal-active"
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = ".",
  },
  view_as = function(self, player, cards)
    return Fk:cloneCard("fire_attack", nil, nil, hantian.name)
  end,
  before_use = function (self, player, use)
    use.extra_data = use.extra_data or {}
    use.extra_data.osHantianUser = player.id
  end,
  enabled_at_play = function (self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = Util.FalseFunc,
})

hantian:addEffect(fk.PreCardEffect, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(hantian.name) and data.from == player and
      data.card.trueName == "fire_attack" and (data.extra_data or {}).osHantianUser == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    data:changeCardSkill("os__hantian__fire_attack_skill")
  end,
})

hantian:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(hantian.name) and data.damageType == fk.FireDamage and data.to:getMark("_os__hantian_times-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data:changeDamage(data.to:getMark("_os__hantian_times-turn"))
  end,
})

hantian:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(hantian.name) and player.room.current == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      local to = move.to
      local yes = false
      if to and move.toArea == Player.Hand then
        local record = to:getTableMark("_os__hantian_cards-turn")
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.contains(to:getCardIds("h"), id) then
            table.insertIfNeed(record, id)
            yes = true
          end
        end
        if yes then
          room:setPlayerMark(to, "_os__hantian_cards-turn", record)
          room:addPlayerMark(to, "_os__hantian_times-turn")
        end
      end
    end
  end
})

return hantian
