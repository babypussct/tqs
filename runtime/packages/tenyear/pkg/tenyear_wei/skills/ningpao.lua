
local ningpao = fk.CreateSkill {
  name = "ningpao",
}

Fk:loadTranslationTable{
  ["ningpao"] = "凝袍",
  [":ningpao"] = "出牌阶段限一次，你可以弃置至多两张牌，令任意名角色各摸等量张牌，"..
  "直到你的下回合开始，这些角色每回合首次受到伤害时，你可以失去1点体力防止此伤害并发动此技能。",

  ["#ningpao"] = "凝袍：弃至多两张牌，令任意名角色各摸等量张牌",
  ["#ningpao-invoke"] = "凝袍：你可以失去1点体力防止 %dest 受到的伤害，然后发动“凝袍”",

  ["$ningpao1"] = "",
  ["$ningpao2"] = "",
}

ningpao:addEffect("active", {
  anim_type = "support",
  prompt = "#ningpao",
  min_card_num = 1,
  max_card_num = 2,
  min_target_num = 1,
  can_use = function (self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and not player:prohibitDiscard(to_select)
  end,
  target_filter = Util.TrueFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    room:throwCard(effect.cards, ningpao.name, player, player)
    for _, p in ipairs(effect.tos) do
      if not p.dead then
        p:drawCards(#effect.cards, ningpao.name)
      end
    end
    if not player.dead then
      room:setPlayerMark(player, ningpao.name, effect.tos)
    end
  end,
})

ningpao:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(ningpao.name) and
      table.contains(player:getTableMark(ningpao.name), data.to) and
      player.hp > 0 and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ningpao.name,
      prompt = "#ningpao-invoke",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, ningpao.name)
    data:preventDamage()
    if player:isNude() then return end
    room:askToUseActiveSkill(player, {
      skill_name = ningpao.name,
      prompt = "#ningpao",
      cancelable = not table.find(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id)
      end),
    })
  end,
})

ningpao:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, ningpao.name, 0)
  end,
})

return ningpao
