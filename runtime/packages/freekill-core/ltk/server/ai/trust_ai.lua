-- SPDX-License-Identifier: GPL-3.0-or-later

-- Trust AI
-- 需要打出牌时，有的话就打出
-- 需要使用闪、对自己使用无懈、酒、桃时，只要有就使用
-- 除此之外什么都不做

---@class TrustAI: AI
local TrustAI = AI:subclass("TrustAI")

local function promptField(prompt, index)
  if type(prompt) ~= "string" or prompt == "" then return nil end
  local parts = prompt:split(":")
  local value = parts[index]
  return type(value) == "string" and value ~= "" and value or nil
end

function TrustAI:initialize(player)
  AI.initialize(self, player)
end

function TrustAI:handleAskForUseCard(data)
  if type(data) ~= "table" or type(data[2]) ~= "string" then
    self:markFallback("malformed_data")
    return ""
  end
  local pattern = data[2]
  local prompt = data[3]

  local wontuse = true
  if pattern == "jink" then
    wontuse = false
  elseif pattern == "nullification" then
    -- 这只是复刻托管AI的逻辑而已 写死几个牌名即可
    local extra_data = type(data[5]) == "table" and data[5] or {}
    local cardName = extra_data.effectCardName
    if not cardName and extra_data.effectCardId and Fk and Fk.getCardById then
      local ok, card = pcall(Fk.getCardById, Fk, extra_data.effectCardId)
      if ok and card then cardName = card.trueName or card.name end
    end
    if not cardName then cardName = promptField(prompt, 4) end
    local goodCard = table.contains({ "ex_nihilo", "amazing_grace", "god_salvation" }, cardName)

    local toId = extra_data.effectTo
    if not toId and type(prompt) == "string" then
      toId = prompt:startsWith("#AskForNullificationWithoutTo") and
        promptField(prompt, 2) or promptField(prompt, 3)
    end
    if not cardName or not toId then
      self:markFallback("malformed_prompt")
      return ""
    end
    local toOther = tostring(toId) ~= tostring(self.player.id)

    wontuse = goodCard or toOther
  elseif pattern == "peach" or pattern == "peach,analeptic" then
    if type(prompt) ~= "string" then
      self:markFallback("malformed_prompt")
      return ""
    end
    wontuse = not prompt:startsWith("#AskForPeachesSelf")
  end
  if wontuse then return "" end

  local cards = self:getEnabledCards()
  for _, cd in ipairs(cards) do
    self:selectCard(cd, true) -- 默认按下卡牌后直接可确定 懒得管了
    return self:doOKButton()
  end
  return ""
end

function TrustAI:handleAskForResponseCard(data)
  if type(data) ~= "table" then
    self:markFallback("malformed_data")
    return ""
  end
  -- local cancelable = data[4] -- 算了，不按取消
  local cards = self:getEnabledCards()
  for _, cd in ipairs(cards) do
    self:selectCard(cd, true) -- 默认按下卡牌后直接可确定 懒得管了
    return self:doOKButton()
  end
  return ""
end

return TrustAI
