local jianji = fk.CreateSkill {
  name = "mobile__jianji",
}

Fk:loadTranslationTable{
  ["mobile__jianji"] = "间计",
  [":mobile__jianji"] = "出牌阶段限一次，你可以秘密选择一张手牌，并令两名角色进行拼点，赢的角色视为对没赢的角色使用一张无距离限制【杀】。"..
  "此次拼点中，这些角色可以秘密选择改为用你选择的牌进行拼点，然后若此牌为【杀】，你对选择用此牌拼点的角色造成1点伤害。",

  ["#mobile__jianji"] = "间计：选择一张手牌，令两名角色拼点，赢者视为对对方使用【杀】",
  ["#mobile__jianji-invoke"] = "间计：是否改为用 %src 秘密选择的牌进行拼点？",

  ["$mobile__jianji1"] = "今日不可力战，需以计图谋。",
  ["$mobile__jianji2"] = "刘备易取，但恐吕布相救，故需以间计图之。",
  ["$mobile__jianji3"] = "先擒刘备，后图吕布，则徐州可得也。",
}

jianji:addEffect("active", {
  anim_type = "offensive",
  prompt = "#mobile__jianji",
  card_num = 1,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(jianji.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards == 1 and #selected < 2 then
      if #selected == 0 then
        return true
      else
        return selected[1]:canPindian(to_select)
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target1 = effect.tos[1]
    local target2 = effect.tos[2]
    local card = Fk:getCardById(effect.cards[1])
    local pindian = {
      from = target1,
      tos = {target2},
      reason = jianji.name,
      fromCard = nil,
      results = {},
      extra_data = {
        proposer = player,
        mobile__jianji_card = card,
      },
    }
    room:pindian(pindian)
    local winner = pindian.results[target2].winner
    if winner ~= nil then
      local loser = target1 == winner and target2 or target1
      if not loser.dead then
        room:useVirtualCard("slash", nil, winner, loser, jianji.name, true)
      end
    end
    if card.trueName == "slash" then
      if pindian.fromCard and pindian.fromCard:getEffectiveId() == card.id and not target1.dead then
        room:damage{
          from = player,
          to = target1,
          damage = 1,
          skillName = jianji.name,
        }
      end
      if pindian.results[target2].toCard and pindian.results[target2].toCard:getEffectiveId() == card.id and not target2.dead then
        room:damage{
          from = player,
          to = target2,
          damage = 1,
          skillName = jianji.name,
        }
      end
    end
  end,
})

jianji:addEffect(fk.StartPindian, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.reason == jianji.name and data.extra_data and data.extra_data.mobile__jianji_card then
      if player == data.from then
        return data.fromCard == nil
      elseif table.contains(data.tos, player) then
        return not (data.results[player] and data.results[player].toCard)
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = jianji.name,
      prompt = "#mobile__jianji-invoke:"..data.extra_data.proposer.id,
    }) then
      if player == data.from then
        data.fromCard = data.extra_data.mobile__jianji_card
      elseif table.contains(data.tos, player) then
        data.results[player] = data.results[player] or {}
        data.results[player].toCard = data.extra_data.mobile__jianji_card
      end
    end
  end,
})

return jianji
