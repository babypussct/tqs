local fenming_active = fk.CreateSkill{
  name = "os__fenming_active",
}

Fk:loadTranslationTable{
  ["os__fenming_active"] = "奋命",
}

fenming_active:addEffect("active", {
  card_num = 0,
  target_num = 1,
  interaction = UI.ComboBox { choices = {"os__fenming_discard", "os__fenming_chained", "os__fenming_beishui"} },
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      if self.interaction.data == "os__fenming_discard" then
        return not to_select:isNude() and
          not (to_select == player and
            not table.find(player:getCardIds("he"), function (id)
              return not player:prohibitDiscard(id)
            end))
      elseif self.interaction.data == "os__fenming_chained" then
        return not to_select.chained
      elseif self.interaction.data == "os__fenming_beishui" then
        return not to_select:isNude() and not to_select.chained and
          not (to_select == player and
            not table.find(player:getCardIds("he"), function (id)
              return not player:prohibitDiscard(id)
            end))
      end
    end
  end,
})

return fenming_active
