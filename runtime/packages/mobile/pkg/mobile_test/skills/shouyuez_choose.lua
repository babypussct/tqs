local shouyueChoose = fk.CreateSkill {
  name = "shouyuez_choose",
}

Fk:loadTranslationTable{
  ["shouyuez_choose"] = "授乐",
  ["shouyuez_draw"] = "摸牌并令一名角色获得琴音",
  ["shouyuez_restore"] = "令一名角色复原武将牌",
}

shouyueChoose:addEffect("active", {
  card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    return UI.ComboBox { choices = { "shouyuez_draw", "shouyuez_restore" } }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return
      #selected == 0 and
      (
        self.interaction.data ~= "shouyuez_restore" or
        (not to_select.faceup or to_select.chained)
      )
  end,
})

return shouyueChoose
