local wuyanc = fk.CreateSkill {
  name = "wuyanc",
}

Fk:loadTranslationTable {
  ["wuyanc"] = "妩艳",
  [":wuyanc"] = "出牌阶段，或当你受到伤害后，你可以选择一名男性角色，令其可以对你选择的一名其他角色使用一张手牌。" ..
  "若其使用了牌，你摸两张牌；若其未使用牌或未造成伤害，此技能本阶段失效，然后你可以令其失去1点体力。",

  ["#wuyanc"] = "妩艳：选择一名男性角色和另一名角色，其可以对后者使用一张牌",
  ["#wuyanc-use"] = "妩艳：对 %dest 使用一张牌，若使用则 %src 摸两张牌",
  ["#wuyanc-loseHp"] = "妩艳：是否令 %dest 失去1点体力？",

  ["$wuyanc1"] = "家父被那黑厮打的，呜呜呜~",
  ["$wuyanc2"] = "将军~您可要为奴家做主~",
}

wuyanc:addEffect("active", {
  anim_type = "control",
  prompt = "#wuyanc",
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 then
      return to_select:isMale()
    else
      return to_select ~= player
    end
  end,
  target_tip = function(self, _, to_select, selected, _, _, selectable, _)
    if not selectable then return end
    if #selected == 0 or (#selected > 0 and selected[1] == to_select) then
      return "use_from"
    else
      return "use_to"
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local to = effect.tos[2]
    local use = room:askToPlayCard(target, {
      cards = target:getHandlyIds(),
      skill_name = wuyanc.name,
      prompt = "#wuyanc-use:" .. player.id .. ":" .. to.id,
      extra_data = {
        bypass_times = true,
        exclusive_targets = { to.id },
        extraUse = true,
        bypass_distances = true
      },
      skip = true,
    })
    if use then
      if use.card.skill:getMinTargetNum(target) == 0 then
        use.tos = { to }
      end
      room:useCard(use)
      if player.dead then return end
      player:drawCards(2, wuyanc.name)
      if player.dead then return end
    end
    if not use or not use.damageDealt then
      room:invalidateSkill(player, wuyanc.name, "-phase")
      if not target.dead and room:askToSkillInvoke(player, {
            skill_name = wuyanc.name,
            prompt = "#wuyanc-loseHp::" .. target.id,
          }) then
        room:doIndicate(player, { target })
        room:loseHp(target, 1, wuyanc.name)
      end
    end
  end,
})

wuyanc:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wuyanc.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = wuyanc.name,
      prompt = "#wuyanc",
      cancelable = true,
      skip = true,
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local tos = event:getCostData(self).tos
    local skill = Fk.skills[wuyanc.name]
    skill:onUse(player.room, {
      from = player,
      tos = tos,
    })
  end,
})

return wuyanc
