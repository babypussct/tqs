local config = assert(ServerConfig.tqsQa)
assert(config.enabled and config.maxPlayers == 2)
local extension = Package:new('tqs_qa', Package.SpecialPack)
extension.extensionName = 'tqs_qa'
local director = fk.CreateSkill {name = 'tqs_qa_concealed_extra_turn_director&'}
local ran = false
local extraStarts = 0
local extraEnds = 0
local stage = 0
local owner
local hiddenReason = 'tqs_qa_concealed_extra_reason'
local function check(ok, label)
  fk.qInfo('[TQS_QA_CONCEALED_EXTRA_TURN] ' .. (ok and 'PASS ' or 'FAIL ') .. label)
  assert(ok, label)
end
local function clearFake(player)
  for _, mark in ipairs({'__heg_general', '__heg_deputy'}) do
    local general = Fk.generals[player:getMark(mark)]
    if general then
      for _, name in ipairs(general:getSkillNameList(true)) do
        local skill = Fk.skills[name]
        if skill and player:isFakeSkill(skill) then player:loseFakeSkill(skill) end
      end
    end
  end
  local skill = Fk.skills['reveal_skill&']
  if skill and player:isFakeSkill(skill) then player:loseFakeSkill(skill) end
end
local function give(room, player, name, tag)
  local id
  for _, pile in ipairs({room.draw_pile, room.discard_pile}) do
    for _, cid in ipairs(pile) do
      if Fk:getCardById(cid).name == name then id = cid; break end
    end
    if id then break end
  end
  assert(id, 'fixture card unavailable')
  room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonJustMove, tag, nil, false, player)
  return id
end

director:addEffect(fk.GameStart, {
  global = true, priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    return not ran and player == room.players[1] and room:getSettings('roomName') == 'TQSQA/wine/0x1'
      and #room.players == 2 and table.every(room.players, function(p) return table.contains(config.allowedUsers, p._splayer:getScreenName()) end)
  end,
  on_trigger = function(self, event, target, player, data)
    ran = true
    owner = player
    local room, enemy = player.room, player.room.players[2]
    check(room.card_wire_version == 1, 'v1')
    for _, p in ipairs(room.players) do
      clearFake(p)
      local ids = p:getCardIds('he')
      if #ids > 0 then room:throwCard(ids, 'tqs_qa', p, p) end
    end
    room:setPlayerProperty(player, 'kingdom', 'wei')
    room:setPlayerProperty(enemy, 'kingdom', 'shu')
    room:setCurrent(player)
    give(room, player, 'jink', 'tqs_qa_private_hand')
    give(room, enemy, 'slash', 'tqs_qa_private_hand')
    check(#player:getCardIds('h') > 0 and #enemy:getCardIds('h') > 0, 'both hands nonempty')
    player:gainAnExtraTurn(true, hiddenReason, {Player.Play})
    check(#room.extra_turn_list == 1 and extraStarts == 0, 'one deferred extra turn queued')
    local queued = room.extra_turn_list[1]
    check(queued.who == player and queued.reason == hiddenReason, 'queued native reason and owner')
    stage = 3
  end,
})
director:addEffect(fk.TurnStart, {
  global = true, priority = 1000,
  can_trigger = function(self, event, target, player, data)
    return ran and stage == 3 and player == owner and target == owner
  end,
  on_trigger = function(self, event, target, player, data)
    extraStarts = extraStarts + 1
    check(data.reason == hiddenReason and player:insideExtraTurn() and player:getCurrentExtraTurnReason() == data.reason, 'real extra turn starts')
    check(player.room.current == player, 'extra turn current owner')
  end,
})
director:addEffect(fk.TurnEnd, {
  global = true, priority = 1000,
  can_trigger = function(self, event, target, player, data)
    return ran and stage == 3 and player == owner and target == owner
  end,
  on_trigger = function(self, event, target, player, data)
    extraEnds = extraEnds + 1
    check(data.reason == hiddenReason and player:insideExtraTurn(), 'real extra turn ends')
  end,
})
director:addEffect(fk.RoundStart, {
  global = true, priority = 1000,
  can_trigger = function(self, event, target, player, data)
    return ran and stage == 3 and player == owner
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    check(extraStarts == 1 and extraEnds == 1, 'exactly one extra turn completed')
    check(#room.extra_turn_list == 0 and not player:insideExtraTurn() and #player:getTableMark('_extra_turn_count') == 0, 'round drains extra turn and clears stack')
    fk.qInfo('[TQS_QA_CONCEALED_EXTRA_TURN] SUMMARY PASS')
    room:gameOver('')
  end,
})
extension:loadSkillSkels({director})
return extension
