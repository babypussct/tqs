local extension = Package:new("utility", Package.SpecialPack)
extension:loadSkillSkelsByPath("./packages/utility/aux_skills")
local premeditate = fk.CreateCard{
  name = "&premeditate",
  type = Card.TypeTrick,
  sub_type = Card.SubtypeDelayedTrick,
  stackable_delayed = true,
}
extension:loadCardSkels{premeditate}
extension:addCardSpec("premeditate")

dofile 'packages/utility/qml_mark.lua'
dofile 'packages/utility/target_tip.lua'

Fk:addPoxiMethod{
  name = "askforCardsChosenFromAreas",
  prompt = function (data, extra_data)
    if extra_data then
      if extra_data.prompt then return extra_data.prompt end
      if extra_data.skillName and extra_data.to then
        return "#askforCardsChosenFromAreas::"..extra_data.to..":"..extra_data.skillName
      end
    end
    return "askforCardsChosenFromAreas"
  end,
  card_filter = function (to_select, selected, data, extra_data)
    if data and #selected < #data then
      for _, id in ipairs(selected) do
        for _, v in ipairs(data) do
          if table.contains(v[2], id) and table.contains(v[2], to_select) then
            return false
          end
        end
      end
      return true
    end
  end,
  feasible = function(selected, data)
    return data and #data == #selected
  end,
  default_choice = function(data)
    if not data then return {} end
    local cids = table.map(data, function(v) return v[2][1] end)
    return cids
  end,
}

Fk:loadTranslationTable{
  ["askforCardsChosenFromAreas"] = "选牌",
  ["#askforCardsChosenFromAreas"] = "%arg：选择 %dest 每个区域各一张牌",
}

return { extension }
