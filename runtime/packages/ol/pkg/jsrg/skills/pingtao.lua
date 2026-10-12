local pingtao = fk.CreateSkill {
  name = "ol__pingtao",
}

Fk:loadTranslationTable{
  ["ol__pingtao"] = "平讨",
  [":ol__pingtao"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.交给你一张牌，然后你本回合使用的下一张【杀】可以多指定一个目标；"..
  "2.你视为对其使用一张【杀】（有次数限制）。",

  ["#ol__pingtao"] = "平讨：令一名角色选择交给你一张牌或视为你对其使用【杀】",
  ["#ol__pingtao-card"] = "平讨：交给 %src 一张牌，或点“取消”其视为对你使用【杀】",
  ["@@ol__pingtao-turn"] = "平讨",
  ["#ol__pingtao-choose"] = "平讨：你可以为%arg额外指定至多%arg2个目标",

  ["$ol__pingtao1"] = "二贼作乱日久，该以时进讨！",
  ["$ol__pingtao2"] = "王师天兵已至，贼徒还不速降！",
}

pingtao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol__pingtao",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(pingtao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= player then
      if player:canUseTo(Fk:cloneCard("slash"), to_select) then
        return true
      else
        return not to_select:isNude()
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      skill_name = pingtao.name,
      include_equip = true,
      cancelable = player:canUseTo(Fk:cloneCard("slash"), target),
      prompt = "#ol__pingtao-card:"..player.id,
    })
    if #card > 0 then
      room:addPlayerMark(player, "@@ol__pingtao-turn", 1)
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, pingtao.name, nil, false, target)
    else
      room:useVirtualCard("slash", nil, player, target, pingtao.name, false)
    end
  end,
})


pingtao:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and player:getMark("@@ol__pingtao-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@@ol__pingtao-turn")
    room:setPlayerMark(player, "@@ol__pingtao-turn", 0)
    if #data:getExtraTargets({bypass_distances = false}) > 0 then
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = n,
        targets = data:getExtraTargets({bypass_distances = true}),
        skill_name = pingtao.name,
        prompt = "#ol__pingtao-choose:::"..data.card:toLogString()..":"..n,
        cancelable = true,
      })
      if #tos > 0 then
        for _, p in ipairs(tos) do
          data:addTarget(p)
        end
      end
    end
  end,
})

return pingtao
