local biwei = fk.CreateSkill {
  name = "biwei",
}

Fk:loadTranslationTable{
  ["biwei"] = "鄙位",
  [":biwei"] = "出牌阶段限一次，你可以弃置一张点数唯一最大的手牌并选择一名其他角色，令其弃置所有点数不小于此牌的手牌。若其未因此弃置牌，复原此技能。",

  ["#biwei"] = "鄙位：弃置点数唯一最大的手牌，令一名角色弃置所有点数不小于此牌的手牌",

  ["$biwei1"] = "何羡殿上公卿？徒惹一身铜臭。",
  ["$biwei2"] = "但见朱门酒肉臭，谁知人间疾苦久？",
}

biwei:addEffect("active", {
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#biwei",
  can_use = function(self, player)
    return player:usedSkillTimes(biwei.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select) and
      not player:prohibitDiscard(to_select) and
      not table.find(player:getCardIds("h"), function (id)
        return id ~= to_select and Fk:getCardById(id).number >= Fk:getCardById(to_select).number
      end)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = Fk:getCardById(effect.cards[1]).number
    room:throwCard(effect.cards, biwei.name, player, player)
    if target.dead then return end
    local cards = table.filter(target:getCardIds("h"), function (id)
      return Fk:getCardById(id).number >= n and not target:prohibitDiscard(id)
    end)
    if #cards > 0 then
      room:throwCard(cards, biwei.name, target, target)
    else
      player:setSkillUseHistory(biwei.name, 0, Player.HistoryPhase)
    end
  end,
})

return biwei
