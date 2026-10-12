
local juao = fk.CreateSkill {
  name = "juao",
}

Fk:loadTranslationTable{
  ["juao"] = "倨傲",
  [":juao"] = "出牌阶段限一次，你可以弃置一张牌，视为对攻击范围内任意名其他角色使用一张【杀】或普通锦囊牌，"..
  "若如此做，此牌目标下次使用【杀】或普通锦囊牌必须指定你为目标，且无距离次数限制。",

  ["#juao"] = "倨傲：弃置一张牌，视为对攻击范围内任意名其他角色使用一张【杀】或普通锦囊牌",
  ["#juao-use"] = "倨傲：视为对攻击范围内任意名其他角色使用一张【杀】或普通锦囊牌",

  ["$juao1"] = "守户之犬效伶人姿态，徒增天下人笑耳。",
  ["$juao2"] = "子敬素称长者，今日却也学小儿做派？",
}

juao:addAuxActiveSkill("juao_active", {
  expand_pile = function(self, player)
    return Fk:currentRoom():getBanner("juao")
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(Fk:currentRoom():getBanner("juao"), to_select)
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected_cards == 1 then
      local card = Fk:cloneCard(Fk:getCardById(selected_cards[1]).name)
      card.skillName = "juao"
      return player:inMyAttackRange(to_select) and
        card.skill:modTargetFilter(player, to_select, selected, card, { bypass_distances = true, bypass_times = true })
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    return #selected_cards == 1 and #selected > 0
  end,
})

juao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#juao",
  card_num = 1,
  target_num = 0,
  can_use = function (self, player)
    return player:usedSkillTimes(juao.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, juao.name, player, player)
    if player.dead then return end
    if room:getBanner(juao.name) == nil then
      local cards = {}
      for _, id in ipairs(room:prepareUniversalCards()) do
        local card = Fk:getCardById(id)
        if card.name == "slash" or (card:isCommonTrick() and not card.is_passive) then
          table.insert(cards, id)
        end
      end
      room:setBanner(juao.name, cards)
    end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "juao_active",
      prompt = "#juao-use",
      cancelable = true,
    })
    if not (success and dat) then
      dat = {}
      for _, id in ipairs(room:getBanner(juao.name)) do
        local card = Fk:cloneCard(Fk:getCardById(id).name)
        card.skillName = juao.name
        for _, p in ipairs(room:getOtherPlayers(player, false)) do
          if player:inMyAttackRange(p) and
            card.skill:modTargetFilter(player, p, {}, card, { bypass_distances = true, bypass_times = true }) then
            dat.cards = { id }
            dat.targets = { p }
            break
          end
        end
      end
      if not dat.cards then return end
    end
    local card = Fk:cloneCard(Fk:getCardById(dat.cards[1]).name)
    card.skillName = juao.name
    for _, p in ipairs(dat.targets) do
      room:setPlayerMark(p, juao.name, player)
    end
    room:useCard({
      from = player,
      tos = dat.targets,
      card = card,
      extraUse = true,
    })
  end,
})

juao:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return from and to and card and
      from:getMark(juao.name) ~= 0 and not from:getMark(juao.name).dead and to ~= from:getMark(juao.name) and
      (card.trueName == "slash" or card:isCommonTrick())
  end,
})

juao:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and to and
      player:getMark(juao.name) ~= 0 and not player:getMark(juao.name).dead and
      (card.trueName == "slash" or card:isCommonTrick())
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    return card and to and
      player:getMark(juao.name) ~= 0 and not player:getMark(juao.name).dead and
      (card.trueName == "slash" or card:isCommonTrick())
  end,
})

juao:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark(juao.name) ~= 0 and
      (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, juao.name, 0)
    data.extraUse = true
  end,
})

return juao
