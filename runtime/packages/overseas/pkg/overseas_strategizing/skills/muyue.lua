local muyue = fk.CreateSkill {
  name = "os__muyue",
}

Fk:loadTranslationTable{
  ["os__muyue"] = "睦约",
  [":os__muyue"] = "出牌阶段限一次，你选择一个基本牌或普通锦囊牌的牌名，弃置一张牌并选择一名角色，令其从牌堆中获得该牌名的牌。"..
  "若你弃置的牌与该牌名相同，你下次发动此技能无需弃牌。",

  ["#os__muyue1"] = "睦约：弃置一张牌，令一名角色获得一张你指定牌名的牌",
  ["#os__muyue0"] = "睦约：令一名角色获得一张你指定牌名的牌",

  ["$os__muyue1"] = "歃血盟誓，以告神明。",
}

muyue:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#os__muyue"..player:getMark(muyue.name) + 1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(muyue.name, Player.HistoryPhase) < 1
  end,
  card_num = function(self, player)
    return player:getMark(muyue.name) + 1
  end,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected < player:getMark(muyue.name) + 1 and not player:prohibitDiscard(to_select)
  end,
  interaction_helper = function(self, player)
    return UI.CardNameBox { choices = Fk:getAllCardNames("bt", true) }
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local name = self.interaction.data
    if not name then return false end
    if #effect.cards > 0 and Fk:getCardById(effect.cards[1]).trueName == name then
      room:setPlayerMark(player, muyue.name, -1)
    else
      room:setPlayerMark(player, muyue.name, 0)
    end
    room:throwCard(effect.cards, muyue.name, player, player)
    if target.dead then return end
    local id = room:getCardsFromPileByRule(name)
    if #id > 0 then
      room:obtainCard(target, id, false, fk.ReasonJustMove, target, muyue.name)
    end
  end,
})

return muyue


