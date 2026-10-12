local xianzhao = fk.CreateSkill {
  name = "ol__xianzhao",
  tags = { Skill.AttachedKingdom },
  attached_kingdom = {"wei"},
  max_branches_use_time = {
    ["basic"] = {
      [Player.HistoryPhase] = 1
    },
    ["trick"] = {
      [Player.HistoryPhase] = 1
    },
    ["equip"] = {
      [Player.HistoryPhase] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["ol__xianzhao"] = "先著",
  [":ol__xianzhao"] = "魏势力技，出牌阶段每个类型限一次，你可以弃置一张非伤害牌，视为使用一张无次数限制的【杀】。"..
  "若造成伤害，你可以使用本次弃置的牌。",

  ["#ol__xianzhao"] = "先著：弃置一张非伤害牌，视为使用一张无次数限制的【杀】，若造成伤害可使用本次弃置的牌",
  ["#ol__xianzhao-use"] = "先著：你可以使用此%arg",

  ["$ol__xianzhao1"] = "敌荡荡无虑，旌旗不整，乃率一而可击十。",
  ["$ol__xianzhao2"] = "诱之以利，士贪于得，设伏投机，必取！",
}

xianzhao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ol__xianzhao",
  target_num = 0,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      local card = Fk:getCardById(to_select)
      return not card.is_damage_card and
        xianzhao:withinBranchTimesLimit(player, card:getTypeString(), Player.HistoryPhase) and
        not player:prohibitDiscard(card)
    end
  end,
  history_branch = function(self, player, data)
    return Fk:getCardById(data.cards[1]):getTypeString()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local ids = effect.cards
    room:throwCard(ids, xianzhao.name, player, player)
    if player.dead then return end
    local slash = Fk:cloneCard("slash")
    slash.skillName = xianzhao.name
    local targets = table.filter(room.alive_players, function(p)
      return player:canUseTo(slash, p, { bypass_times = true })
    end)
    if #targets == 0 then
      return
    elseif #targets > 1 then
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ol__xianzhao-slash",
        skill_name = xianzhao.name,
        cancelable = false,
      })
    end

    ---@type UseCardDataSpec
    local use = {
      card = slash,
      from = player,
      tos = targets,
      extraUse = true,
    }
    room:useCard(use)

    if use.damageDealt and #ids == 1 and table.contains(room.discard_pile, ids[1]) then
      local card = Fk:getCardById(ids[1])
      local bypass_times = (card.trueName ~= "analeptic")
      if #card:getAvailableTargets(player, { bypass_times = bypass_times }) > 0 then
        room:askToUseRealCard(player, {
          pattern = ids,
          skill_name = xianzhao.name,
          prompt = "#ol__xianzhao-use:::" .. Fk:getCardById(ids[1]):toLogString(),
          extra_data = {
            bypass_times = bypass_times,
            expand_pile = ids,
            extraUse = bypass_times,
          },
        })
      end
    end
  end,
}, { check_skill_limit = true })

return xianzhao
