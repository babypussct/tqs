local qice = fk.CreateSkill{
  name = "ld__qice",
}

Fk:loadTranslationTable{
  ["ld__qice"] = "奇策",
  [":ld__qice"] = "出牌阶段限一次，你可将所有手牌当任意一张普通锦囊牌使用，你不能以此法使用目标数大于X的牌（X为你的手牌数），然后你可变更副将。",

  ["#ld__qice-active"] = "发动 奇策，将所有手牌当一张锦囊牌使用",

  ["$ld__qice1"] = "倾力为国，算无遗策。",
  ["$ld__qice2"] = "奇策在此，谁与争锋？",
}

local H = require "packages.hegemony.util"
qice:addEffect("active", {
  prompt = "#ld__qice-active",
  interaction = function(self, player)
    local handcards = player:getCardIds("h")
    local names, all_names = {} , {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived and not table.contains(all_names, card.name) then
        table.insert(all_names, card.name)
        local to_use = Fk:cloneCard(card.name)
        to_use:addSubcards(handcards)
        if player:canUse(to_use) then
          local x = 0
          if to_use.multiple_targets and to_use.skill:getMinTargetNum(player) == 0 then
            for _, p in ipairs(Fk:currentRoom().alive_players) do
              if not player:isProhibited(p, card) and card.skill:modTargetFilter(player, p, {}, card, true) then
                x = x + 1
              end
            end
          end
          if x <= player:getHandcardNum() then
            table.insert(names, card.name)
          end
        end
      end
    end
    if #names == 0 then return end
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_num = 0,
  min_target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(qice.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if self.interaction.data == nil then return false end
    local to_use = Fk:cloneCard(self.interaction.data)
    to_use.skillName = qice.name
    to_use:addSubcards(player:getCardIds("h"))
    if not to_use.skill:targetFilter(player, to_select, selected, selected_cards, to_use, Util.DummyTable) then return false end
    if (#selected == 0 or to_use.multiple_targets) and
      player:isProhibited(to_select, to_use) then return false end
    if to_use.multiple_targets then
      if #selected >= player:getHandcardNum() then return false end
      if to_use.skill:getMaxTargetNum(player, to_use) == 1 then
        local x = 0
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          if p == to_select or (not player:isProhibited(p, to_use) and to_use.skill:modTargetFilter(player, p, {to_select}, to_use, true)) then
            x = x + 1
          end
        end
        if x > player:getHandcardNum() then return false end
      end
    end
    return true
  end,
  feasible = function(self, player, selected, selected_cards)
    if self.interaction.data == nil then return false end
    local to_use = Fk:cloneCard(self.interaction.data)
    to_use.skillName = qice.name
    to_use:addSubcards(player:getCardIds("h"))
    return to_use.skill:feasible(player, selected, selected_cards, to_use)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(player:getCardIds("h"))
    card.skillName = qice.name
    room:useCard{
      from = player,
      tos = effect.tos,
      card = card,
    }
    if not player.dead and room:askToChoice(player, {choices = {"transformDeputy", "Cancel"}, skill_name = qice.name}) ~= "Cancel" then
      H.transformGeneral(room, player)
    end
  end,
})

return qice
