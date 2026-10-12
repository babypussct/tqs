local quanyuBixie = fk.CreateSkill {
  name = "#quanyu_bixie",
}

Fk:loadTranslationTable{
  ["#quanyu_bixie"] = "权御",
}

quanyuBixie:addEffect(fk.TargetSpecified, {
  can_refresh = function(self, event, target, player, data)
    return
      table.contains((data.extra_data or {}).quanyuEffect or {}, "quanyu_bixie_name") and
      data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})

return quanyuBixie
