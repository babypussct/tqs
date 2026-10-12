local liyong = fk.CreateSkill{
  name = "liyong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["liyong"] = "厉勇",
  [":liyong"] = "锁定技，当你于出牌阶段使用的【杀】被【闪】抵消后，你本阶段使用下一张【杀】指定目标后，目标非锁定技失效直到回合结束，"..
  "此【杀】不可被响应且对目标角色造成伤害+1；此【杀】造成伤害后，若目标角色未死亡，你失去1点体力。",

  ["@@liyong-phase"] = "厉勇",

  ["$liyong1"] = "贼众百万，吾亦不放在眼里。",
  ["$liyong2"] = "吾，以一敌千，放马过来吧！",
}

liyong:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(liyong.name) and data.card.trueName == "slash" and data.firstTarget and
      player:getMark("@@liyong-phase") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@liyong-phase", 0)
    data.extra_data = data.extra_data or {}
    data.extra_data.liyong = player
    data.use.disresponsiveList = data.use.disresponsiveList or {}
    for _, p in ipairs(data.use.tos) do
      if not p.dead then
        room:addPlayerMark(p, MarkEnum.UncompulsoryInvalidity.."-turn", 1)
        table.insertIfNeed(data.use.disresponsiveList, p)
      end
    end
  end,
})
liyong:addEffect(fk.CardEffectCancelledOut, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(liyong.name) and
      data.card.trueName == "slash" and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@liyong-phase", 1)
  end,
})

liyong:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target == player and data.card and data.card.trueName == "slash" then
      if player.room.logic:damageByCardEffect() then
        local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if use_event == nil then return end
        local use = use_event.data
        if use.extra_data and use.extra_data.liyong then
          return true
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(1)
  end,
})
liyong:addEffect(fk.Damage, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if data.card and data.card.trueName == "slash" then
      if player.room.logic:damageByCardEffect() then
        local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if use_event == nil then return end
        local use = use_event.data
        if use.extra_data and use.extra_data.liyong then
          return use.extra_data.liyong == player and not data.to.dead and not player.dead
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, 1, liyong.name)
  end,
})

return liyong
