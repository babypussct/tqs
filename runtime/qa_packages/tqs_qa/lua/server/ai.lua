---@class Base.AI : Object
---@field public room Base.RoomBase
---@field public player Base.Player
---@field public command string
---@field public data any
---@field public handler any
---@field public _debug boolean?
local AI = class("Base.AI")

local AI_CANCEL = "__cancel"
local AI_NOTREADY = "__notready"
local AI_ERROR = {}
local AI_METRICS_TAG = "__ai_response_metrics"

-- A PlayCard request intentionally has no payload in the server runtime.  Do
-- not turn that valid request into a malformed-data fallback while still
-- rejecting missing payloads for handlers that actually consume one.
local OPTIONAL_DATA_COMMANDS = {
  PlayCard = true,
}

local NOISY_FALLBACK_REASONS = {
  ai_exception = true,
  ai_no_reply = true,
  handler_error = true,
  invalid_reply = true,
  invalid_strategy_reply = true,
  illegal_reply = true,
  malformed_data = true,
  malformed_prompt = true,
  missing_command = true,
  no_decision = true,
  no_strategy = true,
  unsupported_command = true,
  unexpected_notready = true,
  validator_error = true,
}

local ALLOWED_INVALID_DETAILS = {
  missing_handler = true,
  card_lookup_failed = true,
  skill_missing = true,
  special_skill_missing = true,
  feasibility_exception = true,
  feasibility_rejected = true,
}

local function safeCommand(command)
  if type(command) ~= "string" or command == "" then return "unknown" end
  local ret = command:gsub("[^%w_%-]", "_")
  if #ret > 64 then ret = ret:sub(1, 64) end
  return ret == "" and "unknown" or ret
end

local function newCommandMetrics()
  return {
    total = 0,
    fallback = 0,
    errors = 0,
    invalid = 0,
    no_decision = 0,
    unsupported = 0,
    processing_ms = 0,
    max_processing_ms = 0,
    fallback_reasons = {},
    invalid_details = {},
  }
end

local function getMetrics(self)
  local room = self.room
  if room and type(room.getTag) == "function" and type(room.setTag) == "function" then
    local metrics = room:getTag(AI_METRICS_TAG)
    if type(metrics) ~= "table" then
      metrics = {
        version = 1,
        total = 0,
        fallback = 0,
        errors = 0,
        invalid = 0,
        no_decision = 0,
        unsupported = 0,
        processing_ms = 0,
        max_processing_ms = 0,
        fallback_reasons = {},
        invalid_details = {},
        by_command = {},
      }
      room:setTag(AI_METRICS_TAG, metrics)
    end
    metrics.by_command = metrics.by_command or {}
    metrics.fallback_reasons = metrics.fallback_reasons or {}
    metrics.invalid_details = metrics.invalid_details or {}
    return metrics
  end

  self._ai_response_metrics = self._ai_response_metrics or {
    version = 1,
    total = 0,
    fallback = 0,
    errors = 0,
    invalid = 0,
    no_decision = 0,
    unsupported = 0,
    processing_ms = 0,
    max_processing_ms = 0,
    fallback_reasons = {},
    invalid_details = {},
    by_command = {},
  }
  return self._ai_response_metrics
end

local function addMetric(metrics, key, amount)
  metrics[key] = (metrics[key] or 0) + (amount or 1)
end

local function recordMetric(self, command, reason, elapsed_ms)
  local metrics = getMetrics(self)
  local command_name = safeCommand(command)
  local command_metrics = metrics.by_command[command_name]
  if type(command_metrics) ~= "table" then
    command_metrics = newCommandMetrics()
    metrics.by_command[command_name] = command_metrics
  end
  command_metrics.invalid_details = command_metrics.invalid_details or {}

  addMetric(metrics, "total")
  addMetric(command_metrics, "total")
  -- fk.GetMicroSecond is divided by 1000 at the call site, so preserve
  -- sub-millisecond work instead of rounding every fast request to zero.
  elapsed_ms = math.max(0, elapsed_ms or 0)
  addMetric(metrics, "processing_ms", elapsed_ms)
  addMetric(command_metrics, "processing_ms", elapsed_ms)
  metrics.max_processing_ms = math.max(metrics.max_processing_ms or 0, elapsed_ms)
  command_metrics.max_processing_ms = math.max(command_metrics.max_processing_ms or 0, elapsed_ms)

  if reason then
    addMetric(metrics, "fallback")
    addMetric(command_metrics, "fallback")
    metrics.fallback_reasons[reason] = (metrics.fallback_reasons[reason] or 0) + 1
    command_metrics.fallback_reasons[reason] = (command_metrics.fallback_reasons[reason] or 0) + 1

    -- A fixed diagnostic category helps distinguish validator failures without
    -- recording card, skill, target, or prompt contents.  Keep the public
    -- fallback reason and cancel decision unchanged.
    local detail
    if reason == "illegal_reply" then
      detail = ALLOWED_INVALID_DETAILS[self._ai_validation_detail] and
        self._ai_validation_detail or "unclassified"
    end
    if detail then
      addMetric(metrics.invalid_details, detail)
      addMetric(command_metrics.invalid_details, detail)
    end

    if reason == "handler_error" or reason == "ai_exception" then
      addMetric(metrics, "errors")
      addMetric(command_metrics, "errors")
    elseif reason == "invalid_reply" or reason == "illegal_reply" or reason == "validator_error"
      or reason == "invalid_strategy_reply" then
      addMetric(metrics, "invalid")
      addMetric(command_metrics, "invalid")
    elseif reason == "no_decision" or reason == "no_strategy" or reason == "malformed_data"
      or reason == "malformed_prompt" or reason == "ai_no_reply" then
      addMetric(metrics, "no_decision")
      addMetric(command_metrics, "no_decision")
    elseif reason == "unsupported_command" then
      addMetric(metrics, "unsupported")
      addMetric(command_metrics, "unsupported")
    end

    -- Never log request data, prompts, card ids, target ids, or raw Lua
    -- errors.  The command and bounded reason are enough to correlate a
    -- fallback with a room-side metric without exposing game information.
    if NOISY_FALLBACK_REASONS[reason] and fk and fk.qWarning then
      if detail then
        pcall(fk.qWarning, "[AI] fallback command=%s reason=%s detail=%s elapsed=%.3fms",
          command_name, reason, detail, elapsed_ms)
      else
        pcall(fk.qWarning, "[AI] fallback command=%s reason=%s elapsed=%.3fms",
          command_name, reason, elapsed_ms)
      end
    end
    command_metrics.last_reason = reason
    metrics.last_reason = reason
  end

  return metrics
end

local function contains(list, value)
  if type(list) ~= "table" then return false end
  for _, item in ipairs(list) do
    if item == value then return true end
  end
  return false
end

local function isInteger(value)
  return type(value) == "number" and value % 1 == 0
end

local function isDenseArray(value)
  if type(value) ~= "table" then return false end
  local count, length = 0, #value
  for key in pairs(value) do
    if not isInteger(key) or key < 1 or key > length then return false end
    count = count + 1
  end
  return count == length
end

local function validLimits(min_num, max_num)
  return isInteger(min_num) and isInteger(max_num) and
    min_num >= 0 and min_num <= max_num
end

local function validateChoiceList(command, data, reply)
  if type(reply) ~= "table" or type(data) ~= "table" then return false end
  local choices, limits = data[1], data[3]
  if not isDenseArray(reply) or not isDenseArray(choices) or type(limits) ~= "table" then return false end
  local min_num, max_num = limits[1], limits[2]
  if not validLimits(min_num, max_num) then return false end
  if #reply > max_num or (#reply < min_num and not data[4]) then return false end
  local seen = {}
  for _, choice in ipairs(reply) do
    if type(choice) ~= "string" or seen[choice] then return false end
    if not contains(choices, choice) and not
      (command == "AskForOptions" and data[4] == true and choice == "Cancel") then
      return false
    end
    seen[choice] = true
  end
  return true
end

local function cardIdsFromCardData(target, card_data)
  if type(card_data) == "string" and target and type(target.getCardIds) == "function" then
    local ok, ids = pcall(target.getCardIds, target, card_data)
    if ok and type(ids) == "table" then return ids end
  elseif type(card_data) == "table" and type(card_data.card_data) == "table" then
    local ids = {}
    for _, entry in ipairs(card_data.card_data) do
      if type(entry) == "table" and type(entry[2]) == "table" then
        for _, id in ipairs(entry[2]) do table.insert(ids, id) end
      end
    end
    return ids
  end
  return nil
end

local function validateCardChosen(data, reply)
  if not isInteger(reply) then return false end
  if type(data) ~= "table" then return false end
  local ids = cardIdsFromCardData(data[1], data[2])
  return type(ids) == "table" and contains(ids, reply)
end

local function validateAG(data, reply)
  if not isInteger(reply) then return false end
  return type(data) == "table" and type(data[1]) == "table" and contains(data[1], reply)
end

local function validateCardsAndChoice(data, reply)
  if type(data) ~= "table" or type(reply) ~= "table" then return false end
  if not isDenseArray(reply.cards) or type(reply.choice) ~= "string" then return false end
  if type(data.cards) ~= "table" then return false end
  local min_num, max_num = data.min, data.max
  if not validLimits(min_num, max_num) then return false end
  if #reply.cards < min_num or #reply.cards > max_num then return false end
  local seen = {}
  for _, id in ipairs(reply.cards) do
    if not isInteger(id) or seen[id] or not contains(data.cards, id)
      or contains(data.disabled, id) then return false end
    seen[id] = true
  end
  local allowed_choices = data.choices or {}
  local cancel_choices = data.cancel_choices or {}
  return contains(allowed_choices, reply.choice) or contains(cancel_choices, reply.choice)
end

local function validateBoardMove(data, reply)
  if type(data) ~= "table" or type(reply) ~= "table" or
    not isInteger(reply.cardId) or (reply.pos ~= 0 and reply.pos ~= 1) or
    not isDenseArray(data.cards) or not isDenseArray(data.cardsPosition) or
    #data.cards ~= #data.cardsPosition then return false end
  for i, id in ipairs(data.cards) do
    if id == reply.cardId and data.cardsPosition[i] == reply.pos then return true end
  end
  return false
end

local ACTIVE_COMMANDS = {
  AskForUseActiveSkill = true,
  AskForResponseCard = true,
  AskForUseCard = true,
  PlayCard = true,
}

local function validateReplyShape(self, command, data, reply)
  if reply == AI_CANCEL then return true end
  if reply == AI_NOTREADY then return false, "unexpected_notready" end
  if reply == nil or reply == "" then return false, "no_decision" end

  if command == "AskForSkillInvoke" then
    return reply == "1", "invalid_reply"
  elseif command == "AskForChoices" or command == "AskForOptions" then
    return validateChoiceList(command, data, reply), "invalid_reply"
  elseif command == "AskForChoice" then
    return type(data) == "table" and type(data[1]) == "table" and
      type(reply) == "string" and contains(data[1], reply), "invalid_reply"
  elseif command == "AskForCardChosen" then
    return validateCardChosen(data, reply), "invalid_reply"
  elseif command == "AskForAG" then
    return validateAG(data, reply), "invalid_reply"
  elseif command == "AskForCardsAndChoice" then
    return validateCardsAndChoice(data, reply), "invalid_reply"
  elseif command == "AskForMoveCardInBoard" then
    return validateBoardMove(data, reply), "invalid_reply"
  elseif command == "CustomDialog" then
    -- Only the initial Hegemony general pair has a supported table reply.
    -- Other custom dialogs must use the existing server-side fallback.
    if type(data) == 'table' and type(data.component) == 'table' and
        data.component.name == 'ChooseInitialGeneralBox' then
      return require('ltk.server.ai.general_pair').validate(data, reply), 'invalid_reply'
    end
    return false, 'invalid_reply'
  elseif ACTIVE_COMMANDS[command] then
    if type(reply) ~= "table" or type(reply.targets) ~= "table" then
      return false, "invalid_reply"
    end
    local card = reply.card
    if type(card) == "number" then
      if not isInteger(card) then return false, "invalid_reply" end
      if Fk and type(Fk.getCardById) == "function" then
        local ok, card_object = pcall(Fk.getCardById, Fk, card)
        if not ok or not card_object then return false, "invalid_reply" end
      end
    elseif type(card) == "table" then
      if type(card.skill) ~= "string" or card.skill == "" or type(card.subcards) ~= "table" then
        return false, "invalid_reply"
      end
      if Fk and Fk.skills and not Fk.skills[card.skill] then return false, "invalid_reply" end
      for _, id in ipairs(card.subcards) do
        if not isInteger(id) then return false, "invalid_reply" end
      end
    else
      return false, "invalid_reply"
    end
    local seen_targets = {}
    for _, pid in ipairs(reply.targets) do
      if not isInteger(pid) or seen_targets[pid] then return false, "invalid_reply" end
      seen_targets[pid] = true
      if self.room and type(self.room.getPlayerById) == "function" then
        local ok, target = pcall(self.room.getPlayerById, self.room, pid)
        if not ok or not target then return false, "invalid_reply" end
      end
    end
    if reply.special_skill ~= nil and type(reply.special_skill) ~= "string" then
      return false, "invalid_reply"
    end
    return true
  end

  -- Commands without a SmartAI handler must never receive an arbitrary table
  -- or boolean.  A string is left to the room-level default path, but only
  -- the canonical cancel sentinel reaches this point in the built-in AI.
  return type(reply) == "string", "invalid_reply"
end

function AI:getResponseMetrics()
  return getMetrics(self)
end

-- Used by Request when an exception happens outside Base.AI:makeReply (for
-- example while preparing a subclass-specific context).  This keeps that
-- failure visible without allowing it to strand a Request in __notready.
function AI:recordExternalFallback(command, reason)
  recordMetric(self, command, reason or "ai_no_reply", 0)
end

function AI:markFallback(reason)
  self._ai_fallback_reason = reason
end

function AI:initialize(player)
  ---@diagnostic disable-next-line
  self.room = RoomInstance
  self.player = player

  -- 直接用verbose结合verbose_level不是个好办法
  -- 因为lua会先计算参数再调用函数，在不启用verbose的情况下
  -- 那些调试用的json.encode就变成纯累赘了
  --
  -- 当然verbose本身能显示cpu时间是很不错的，只是需要结合if判断才能避免浪费
  -- 如果有C++的宏那就好了
  --
  -- 总之开发底层ai时设为true就可以了
  --
  -- [!!] 提交到master的话这个务必设为false!
  self._debug = false
end

function AI:__tostring()
  return string.format("%s: %s", self.class.name, tostring(self.player))
end

function AI:makeReply()
  Self = self.player -- FIXME: 这玩意还不杀？
  local now = os.getms()
  local raw_command = self.command
  local command = type(raw_command) == "string" and raw_command or ""
  local ret = AI_CANCEL
  local reason
  self._ai_fallback_reason = nil
  self._ai_validation_detail = nil
  self._last_ai_reply = nil
  self.handler = nil

  if command == "" then
    reason = "missing_command"
  else
    local fn = self["handle" .. command]
    if not fn then
      reason = "unsupported_command"
    elseif self.data == nil and not OPTIONAL_DATA_COMMANDS[command] then
      reason = "malformed_data"
    elseif self.data ~= nil and type(self.data) ~= "table" then
      reason = "malformed_data"
    else
      local ok, value = xpcall(function()
        local handler_class = self.room and self.room.request_handlers and
          self.room.request_handlers[command]
        if handler_class then
          self.handler = handler_class:new(self.player, self.data)
          self.handler:setup()
        end
        return fn(self, self.data)
      end, function()
        return AI_ERROR
      end)
      if not ok then
        reason = "handler_error"
      else
        ret = value
      end
    end
  end

  if not reason and (ret == nil or ret == "") then
    reason = self._ai_fallback_reason or "no_decision"
    ret = AI_CANCEL
  elseif not reason then
    -- A legacy strategy used `interaction`; the server protocol calls this
    -- field `interaction_data`.  Normalize it before validation so an old
    -- strategy cannot produce a structurally valid but unusable reply.
    if type(ret) == "table" and ret.interaction_data == nil and ret.interaction ~= nil then
      ret.interaction_data = ret.interaction
      ret.interaction = nil
    end
    local ok, validation_reason = validateReplyShape(self, command, self.data, ret)
    if not ok then
      reason = validation_reason or "invalid_reply"
      ret = AI_CANCEL
    elseif type(self.validateReply) == "function" and ret ~= AI_CANCEL then
      local validator_ok, valid, custom_reason = pcall(self.validateReply, self, command, self.data, ret)
      if not validator_ok then
        reason = "validator_error"
        ret = AI_CANCEL
      elseif valid == false then
        reason = custom_reason or "illegal_reply"
        ret = AI_CANCEL
      end
    end
    if not reason and self._ai_fallback_reason then
      reason = self._ai_fallback_reason
    end
  end

  self.handler = nil
  local elapsed_ms = (os.getms() - now) / 1000
  recordMetric(self, command, reason, elapsed_ms)

  if self._debug then
    -- Keep debug output metadata-only.  Reply payloads can contain card and
    -- target information that must not enter logs.
    verbose(1, "%s 在%.2fms后得出%s结果", safeCommand(command), elapsed_ms,
      reason and ("fallback(" .. reason .. ")") or "决定")
  end
  return ret
end

return AI
