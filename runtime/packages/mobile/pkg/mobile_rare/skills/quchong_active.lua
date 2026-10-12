local quchong_active = fk.CreateSkill {
  name = "quchong_active",
}

Fk:loadTranslationTable{
  ["quchong_active"] = "渠冲",
}

quchong_active:addEffect("active", {
  card_num = 0,
  target_num = 1,
  interaction = function()
    return UI.ComboBox { choices = { "offensive_siege_engine", "defensive_siege_engine" } }
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.TrueFunc,
})

return quchong_active
