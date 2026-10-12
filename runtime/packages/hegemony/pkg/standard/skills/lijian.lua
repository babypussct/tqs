
local lijian = fk.CreateSkill {
  name = "hs__lijian",
}

Fk:loadTranslationTable{
  ["hs__lijian"] = "离间",
  [":hs__lijian"] = "出牌阶段限一次，你可弃置一张牌并选择两名其他男性角色，后选择的角色视为对先选择的角色使用一张【决斗】。",

  ["#hs__lijian"] = "离间：弃置一张手牌并选择两名其他男性角色，后选择的角色视为对先选择的角色使用【决斗】",

  ["$hs__lijian1"] = "嗯呵呵~~呵呵~~",
  ["$hs__lijian2"] = "夫君，你要替妾身做主啊……",
}

lijian:addEffect("active", {
  anim_type = "offensive",
  prompt = "#hs__lijian",
  max_phase_use_time = 1,
  card_num = 1,
  target_num = 2,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    if #selected < 2 and to_select ~= player and to_select:isMale() then
      if #selected == 0 then
        return true
      else
        return to_select:canUseTo(Fk:cloneCard("duel"), selected[1])
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, lijian.name, player, player)
    room:useVirtualCard("duel", nil, effect.tos[2], { effect.tos[1] })
  end,
  target_tip = function(self, _, to_select, selected, _, _, selectable, _)
    if not selectable then return end
    if #selected == 0 or (#selected > 0 and selected[1] == to_select) then
      return "use_to"
    else
      return "use_from"
    end
  end,
})

return lijian
