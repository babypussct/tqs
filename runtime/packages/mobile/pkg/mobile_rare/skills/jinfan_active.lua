local jinfan_active = fk.CreateSkill {
  name = "jinfan_active",
}

Fk:loadTranslationTable{
  ["jinfan_active"] = "锦帆",
}

jinfan_active:addEffect("active", {
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Player.Equip or
      table.find(player:getPile("jinfan_ling"), function(id)
        return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(id))
      end) then return end
    if #selected == 0 then
      return true
    else
      return table.every(selected, function(id)
        return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(id), true)
      end)
    end
  end,
})

return jinfan_active
