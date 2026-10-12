
local nigu = fk.CreateSkill {
  name = "nigu",
}

Fk:loadTranslationTable{
  ["nigu"] = "逆固",
  [":nigu"] = "出牌阶段限一次，你可以弃置至少一张花色不同的牌，令攻击范围内的角色同时选择是否交给你一张牌，然后你本回合造成的下X次伤害+1"..
  "（X为选择不交给你牌的角色数）。",

  ["#nigu"] = "逆固：弃置至少一张花色不同的牌，令攻击范围内的角色选择交给你一张牌或你造成伤害+1",
  ["#nigu-give"] = "逆固：交给 %src 一张牌，或点“取消”其本回合造成伤害+1",
  ["@nigu-turn"] = "逆固增伤",

  ["$nigu1"] = "诸卿若不奉我，便是已有反心！",
  ["$nigu2"] = "正值尽忠死战之时，何故生此迟疑！",
  ["$nigu3"] = "天子若有他意，我亦当复改图！",
  ["$nigu4"] = "我令既不得行，我刑当得行也！",
}

nigu:addEffect("active", {
  audio_index = { 1, 2 },
  anim_type = "control",
  prompt = "#nigu",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(nigu.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, player, to_select, selected, selected_targets)
    return not player:prohibitDiscard(to_select) and
      not table.find(selected, function (id)
        return Fk:getCardById(id):compareSuitWith(Fk:getCardById(to_select))
      end)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, nigu.name, player, player)
    if player.dead then return end
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return player:inMyAttackRange(p)
    end)
    if #targets == 0 then return end
    room:doIndicate(player, targets)
    local result = room:askToJointCards(player, {
      players = targets,
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = nigu.name,
      cancelable = true,
      prompt = "#nigu-give:"..player.id,
    })
    local moves = {}
    for _, p in ipairs(targets) do
      if #result[p] > 0 then
        table.insert(moves, {
          ids = result[p],
          from = p,
          to = player,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonGive,
          skillName = nigu.name,
        })
      end
    end

    local diff = #targets - #moves
    if diff > 0 then
      room:addPlayerMark(player, "@nigu-turn", diff)
    end

    if next(moves) then
      room:moveCards(table.unpack(moves))
    end
  end,
})

nigu:addEffect(fk.DamageCaused, {
  audio_index = { 3, 4 },
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@nigu-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:removePlayerMark(player, "@nigu-turn", 1)
    data:changeDamage(1)
  end,
})

return nigu
