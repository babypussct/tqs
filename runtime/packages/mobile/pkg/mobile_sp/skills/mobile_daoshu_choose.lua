local mobileDaoshuChoose = fk.CreateSkill {
  name = "mobile__daoshu_choose",
}

Fk:loadTranslationTable{
  ["mobile__daoshu_choose"] = "盗书",
}

mobileDaoshuChoose:addEffect("active", {
  card_num = 1,
  target_num = 0,
  interaction = function(self, player)
    return UI.ComboBox { choices = player:getMark("mobile__daoshu_names") }
  end,
  card_filter = function(self, player, to_select, selected)
    return
      #selected == 0 and
      Fk:currentRoom():getCardArea(to_select) == Player.Hand and
      Fk:getCardById(to_select).name ~= self.interaction.data
  end,
  target_filter = Util.FalseFunc,
})

return mobileDaoshuChoose
