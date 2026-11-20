-- Describe which offered references a native request presents face-up. The
-- same payload shapes are used before projection and after tokenization.
local Visibility = {}

local function add(cards, values, visibility)
  if type(values) ~= "table" then return end
  for _, id in ipairs(values) do cards[id] = visibility end
end

local function addGroups(cards, groups)
  for _, group in ipairs(groups) do add(cards, group[2], true) end
end

local function mask(cards, hidden, extra)
  if type(extra) ~= "table" or type(extra.visible_data) ~= "table" then return end
  for id in pairs(cards) do
    local visible = extra.visible_data[tostring(id)]
    if visible == false or visible == 0 then
      cards[id] = nil
      hidden[id] = true
    end
  end
end

function Visibility.offered(command, payload)
  local cards, hidden = {}, {}
  if command == "AskForArrangeCards" then
    for _, row in ipairs(payload.cards) do add(cards, row, true) end
  elseif command == "AskForCardsAndChoice" then
    add(cards, payload.cards, true)
    mask(cards, hidden, payload.extra_data)
  elseif command == "AskForCardChosen" and type(payload[2]) == "table" then
    addGroups(cards, payload[2].card_data)
    mask(cards, hidden, payload[2])
  elseif command == "AskForPoxi" then
    addGroups(cards, payload.data)
    mask(cards, hidden, payload.extra_data)
  elseif command == "AskForUseActiveSkill" or command == "AskForUseCard" or command == "AskForResponseCard" then
    local extra = payload[command == "AskForUseActiveSkill" and 4 or 5]
    if type(extra) == "table" then
      -- An explicit expansion of deck/processing cards is a native peek.
      -- Named piles and extra pattern IDs do not grant new visibility.
      add(cards, extra.expand_pile, "peek")
      add(cards, extra.visible_pile, true)
      mask(cards, hidden, extra.extra_data)
      mask(cards, hidden, extra)
    end
  end
  return cards, hidden
end

return Visibility
