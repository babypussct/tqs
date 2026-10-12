local saoting = fk.CreateSkill {
  name = "os__saoting",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable {
  ["os__saoting"] = "扫庭",
  [":os__saoting"] = "转换技，阳：你可以将一张伤害牌当【决斗】使用；阴：你可以将一张伤害牌当【酒】使用。" ..
  "若你以此法使用牌指定了已受伤角色为目标，你摸一张牌。",

  ["#os__saoting-yang"] = "扫庭：你可以将一张伤害牌当【决斗】使用，若目标已受伤，你摸一张牌",
  ["#os__saoting-yin"] = "扫庭：你可以将一张伤害牌当【酒】使用，若目标已受伤，你摸一张牌",

  ["$os__saoting1"] = "若不扫平群寇，何可为江东之主！", -- 决斗
  ["$os__saoting2"] = "尽诛宵小妖邪，吾必不死不休！", -- 酒
}

saoting:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "duel,analeptic",
  mute = true,
  prompt = function (self, player, cards, targets)
    return "#os__saoting-" .. player:getSwitchSkillState(saoting.name, false, true)
  end,
  handly_pile = true,
  filter_pattern = function (self, player)
    local cards = table.filter(table.connect(player:getCardIds("he"), player:getHandlyIds()), function(c)
      return Fk:getCardById(c).damage_type ~= nil
    end)
    return {
      min_num = 1,
      max_num = 1,
      pattern = tostring(Exppattern{ id = cards }),
    }
  end,
  view_as = function (self, player, cards)
    if #cards ~= 1 then return end
    local name = player:getSwitchSkillState(saoting.name) == fk.SwitchYang and "duel" or "analeptic"
    local card = Fk:cloneCard(name, nil, nil, saoting.name, cards)
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    room:notifySkillInvoked(player, saoting.name, "offensive")
    player:broadcastSkillInvoke(saoting.name, use.card.name == "duel" and 1 or 2)
    use.extra_data = use.extra_data or {}
    use.extra_data.osSaotingUser = player.id
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

saoting:addEffect(fk.TargetSpecified, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and not player.dead and (data.extra_data or {}).osSaotingUser == player.id and
      data.firstTarget and table.find(data:getAllTargets(), function (to)
        return to:isWounded()
      end)
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, saoting.name)
  end,
})

return saoting
