local shiqiang = fk.CreateSkill({
  name = "m_shiqiang",
  mode_skill = true,
})

Fk:loadTranslationTable{
  ["m_shiqiang"] = "恃强",
  [":m_shiqiang"] = "出牌阶段限一次，你可以将一张牌当无距离限制的任意【杀】使用；你以此法使用【杀】时，摸一张牌；此【杀】结算结束后，若未造成伤害，你减1点体力上限。",
  ["#m_shiqiang"] = "恃强：你可以将一张牌当任意【杀】使用",
}

shiqiang:addEffect("viewas", {
  pattern = "slash",
  card_num = 1,
  prompt = "#m_shiqiang",
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    local c = Fk:cloneCard("slash")
    return (Fk.currentResponsePattern == nil and player:canUse(c)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  interaction = function(self, player)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if
        not table.contains(allCardNames, card.name) and
        card.trueName == "slash" and
        (
          (Fk.currentResponsePattern == nil and player:canUse(card)) or
          (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))
        ) and
        not player:prohibitUse(card) then
        table.insert(allCardNames, card.name)
      end
    end
    return UI.ComboBox { choices = allCardNames }
  end,
  view_as = function(self, player, cards)
    local choice = self.interaction.data
    if not choice or #cards ~= 1 then return end
    local c = Fk:cloneCard(choice)
    c:addSubcards(cards)
    c.skillName = shiqiang.name
    return c
  end,
  after_use = function(self, player, use)
    local t = use.damageDealt
    if not t or not next(t) then
      player.room:changeMaxHp(player, -1)
    end
  end,
  enabled_at_play = function(self, player)
    return player:canUse(Fk:cloneCard("slash")) and
      player.phase == Player.Play and player:usedSkillTimes(shiqiang.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = function(self, player, response)
    return Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("slash"))
      and not response and
      player.phase == Player.Play and player:usedSkillTimes(shiqiang.name, Player.HistoryPhase) == 0
  end,
})

shiqiang:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, shiqiang.name)
  end,
})

shiqiang:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      table.contains(data.card.skillNames, shiqiang.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, shiqiang.name)
  end,
})

return shiqiang
