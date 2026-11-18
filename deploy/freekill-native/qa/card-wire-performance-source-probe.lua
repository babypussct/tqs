-- Bounded candidate-only P6 probe for card-wire projection, CBOR encoding and
-- lifecycle cleanup. It measures metadata only: no token, physical card ID,
-- hand, general, request payload or exception is printed.
--
-- This is intentionally a source/runtime probe, not a native C++ benchmark.
-- The native/browser performance gate remains separate until the live runner
-- exports the same bounded metrics at the wire boundary.
local coreRoot, protocolPath = ...
assert(coreRoot and protocolPath, "candidate core and protocol paths required")

package.path = coreRoot .. "/?.lua;" .. coreRoot .. "/?/init.lua;" ..
  coreRoot .. "/lua/?.lua;" .. coreRoot .. "/lua/?/init.lua;" .. package.path

Card = {
  PlayerHand = 1, PlayerEquip = 2, PlayerJudge = 3, PlayerSpecial = 4,
  Processing = 5, DiscardPile = 6, DrawPile = 7, Void = 8,
}
cbor = assert(dofile(coreRoot .. "/lua/server/rpc/cbor.lua"))
local Protocol = assert(dofile(protocolPath))
local Mint = assert(dofile(coreRoot .. "/lua/server/card_wire_secure_mint.lua"))
local Projection = assert(dofile(coreRoot .. "/lua/server/card_wire_projection.lua"))
local protocol = Protocol.new(Mint.next)

local function sequence(start, count)
  local result = {}
  for index = 1, count do result[index] = start + index end
  return result
end

local function countMap(value)
  local count = 0
  for _ in pairs(value or {}) do count = count + 1 end
  return count
end

local function percentile(samples, fraction)
  table.sort(samples)
  if #samples == 0 then return 0 end
  local index = math.max(1, math.ceil(#samples * fraction))
  return samples[index]
end

local function newStats()
  return { count = 0, project = {}, serialize = {}, maxBytes = 0 }
end

local stats = {}
local function record(name, projectUs, serializeUs, bytes)
  local current = stats[name]
  if not current then current = newStats(); stats[name] = current end
  current.count = current.count + 1
  current.project[#current.project + 1] = projectUs
  current.serialize[#current.serialize + 1] = serializeUs
  if bytes > current.maxBytes then current.maxBytes = bytes end
end

local sockets = {
  owner = { audience = "p6-owner" },
  opponent = { audience = "p6-opponent" },
  observer = { audience = "p6-observer" },
}
local owner = { id = 1, _splayer = sockets.owner, role_shown = false,
  role = "hidden", general = "anjiang", deputyGeneral = "anjiang",
  gender = 4, kingdom = "unknown", player_cards = {}, special_cards = {} }
local opponent = { id = 2, _splayer = sockets.opponent, role_shown = false,
  role = "hidden", general = "anjiang", deputyGeneral = "anjiang",
  gender = 4, kingdom = "unknown", player_cards = {}, special_cards = {} }
local players = { [owner.id] = owner, [opponent.id] = opponent }
local locations = {}
local deck = sequence(10000, 256)
local hand = sequence(11000, 64)
local privatePile = sequence(12000, 32)
local discard = sequence(13000, 16)
local processing = sequence(14000, 8)
local void = sequence(15000, 4)

for _, id in ipairs(deck) do locations[id] = { area = Card.DrawPile } end
for _, id in ipairs(hand) do locations[id] = { area = Card.PlayerHand, owner = owner } end
for _, id in ipairs(privatePile) do
  locations[id] = { area = Card.PlayerSpecial, owner = owner, pile = "$secret" }
end
for _, id in ipairs(discard) do locations[id] = { area = Card.DiscardPile } end
for _, id in ipairs(processing) do locations[id] = { area = Card.Processing } end
for _, id in ipairs(void) do locations[id] = { area = Card.Void } end

owner.player_cards = { [Card.PlayerHand] = hand, [Card.PlayerEquip] = {},
  [Card.PlayerJudge] = {} }
owner.special_cards = { ["$secret"] = privatePile }
opponent.player_cards = { [Card.PlayerHand] = {}, [Card.PlayerEquip] = {},
  [Card.PlayerJudge] = {} }
opponent.special_cards = {}

function owner:getPileNameOfId(id)
  return locations[id] and locations[id].pile
end
function opponent:getPileNameOfId() return nil end

local room = {
  card_wire_version = 1,
  settings = { gameMode = "new_heg_mode" },
  _cardWireProtocol = protocol,
}
function room:getSettings(key) return self.settings[key] end
function room:cardWireAudience(physical) return physical.audience end
function room:getPlayerById(id) return players[id] end
function room:getCardArea(id) return locations[id] and locations[id].area end
function room:getCardOwner(id) return locations[id] and locations[id].owner end

local function playerSnapshot(player)
  return {
    mark = cbor.encode({}), fake_skills = {}, prelighted_skills = {},
    properties = {
      role = player.role, role_shown = player.role_shown,
      general = player.general, deputyGeneral = player.deputyGeneral,
      gender = player.gender, kingdom = player.kingdom,
    },
    player_cards = {
      [Card.PlayerHand] = player.player_cards[Card.PlayerHand],
      [Card.PlayerEquip] = player.player_cards[Card.PlayerEquip],
      [Card.PlayerJudge] = player.player_cards[Card.PlayerJudge],
    },
    special_cards = player.special_cards,
    virtual_equips = {},
  }
end

local snapshot = {
  settings = { gameMode = "new_heg_mode" },
  card_manager = {
    draw_pile = deck, discard_pile = discard, processing_area = processing,
    void = void, printed_cards = {},
    card_marks = cbor.encode({
      [hand[1]] = { ["@private"] = "owner" },
      [discard[1]] = { ["@public"] = "discard" },
      [privatePile[1]] = { ["@secret"] = "special" },
    }),
  },
  players = { [owner.id] = playerSnapshot(owner),
    [opponent.id] = playerSnapshot(opponent) },
}

local function emit(seat, physical, command, data, prepare)
  local batch = protocol:beginBatch()
  local audience = room:cardWireAudience(physical)
  if prepare then prepare(batch, audience) end
  local projectStart = os.clock()
  local ok, result = pcall(Projection.project, room, seat, physical,
    command, data, batch)
  local projectUs = math.floor((os.clock() - projectStart) * 1000000 + 0.5)
  if not ok then batch:abort(); error(result, 2) end
  local serializeStart = os.clock()
  local encodedOk, encoded = pcall(cbor.encode, result)
  local serializeUs = math.floor((os.clock() - serializeStart) * 1000000 + 0.5)
  if not encodedOk then batch:abort(); error(encoded, 2) end
  batch:commit()
  record(command, projectUs, serializeUs, #encoded)
end

local audiences = { sockets.owner, sockets.opponent, sockets.observer }
local seats = { owner, owner, owner }
local iterations = 12
local maxActiveRefs = 0

local function activeRefs(audience)
  local state = protocol.audiences[audience]
  if not state then return 0 end
  return countMap(state.byId) + countMap(state.public)
end

local function updateMaxActive()
  for _, physical in ipairs(audiences) do
    maxActiveRefs = math.max(maxActiveRefs, activeRefs(physical.audience))
  end
end

for index, physical in ipairs(audiences) do
  local seat = seats[index]
  for _ = 1, iterations do
    emit(seat, physical, "PrepareDrawPile", deck)
    emit(seat, physical, "SetPlayerPile", { owner.id, "$secret", privatePile })
    emit(seat, physical, "MoveCards", {
      {{ from = owner.id, to = owner.id, toArea = Card.PlayerHand,
        moveVisible = false,
        moveInfo = {{ cardId = deck[1], fromArea = Card.DrawPile }} }},
      100,
    })
    emit(seat, physical, "ChangeCardArea", {{ deck[2] }, Card.DrawPile, { deck[2] }},
      function(batch, audience)
        batch:reference(audience, deck[2], false)
      end)
    updateMaxActive()
  end
  -- Reconnect/Observe resets the physical session and reprojects a bounded
  -- snapshot; this is the memory and reconnect-cost portion of P6.
  emit(seat, physical, index == 3 and "Observe" or "Reconnect", snapshot)
  updateMaxActive()
end

-- Negative counters are intentionally metadata-only. The protocol must reject
-- a request from a foreign physical audience, a consumed reply and a stale
-- standing reference after rekey.
local ownerAudience = sockets.owner.audience
local peerAudience = sockets.opponent.audience
local choice = protocol:issueChoice(ownerAudience, "p6-foreign", {
  { id = hand[1], public = false },
}, 1, 1)
local foreign = protocol:resolveChoice(peerAudience, "p6-foreign", choice,
  function() return true end)
assert(foreign == nil, "foreign audience choice must be rejected")
local accepted = protocol:resolveChoice(ownerAudience, "p6-foreign", choice,
  function() return true end)
assert(accepted ~= nil, "owner choice must be accepted once")
local replay = protocol:resolveChoice(ownerAudience, "p6-foreign", choice,
  function() return true end)
assert(replay == nil, "replayed choice must be rejected")

local stale = protocol:issueChoice(ownerAudience, "p6-stale", {
  { id = hand[2], public = false },
}, 1, 1)
protocol:rekey(ownerAudience, { hand[2] })
local staleResult = protocol:resolveChoice(ownerAudience, "p6-stale", stale,
  function() return true end)
assert(staleResult == nil, "stale choice must be rejected after rekey")

local projectSamples, serializeSamples = {}, {}
local maxWireBytes = 0
local caseCount = 0
for _, current in pairs(stats) do
  caseCount = caseCount + 1
  for _, value in ipairs(current.project) do projectSamples[#projectSamples + 1] = value end
  for _, value in ipairs(current.serialize) do serializeSamples[#serializeSamples + 1] = value end
  maxWireBytes = math.max(maxWireBytes, current.maxBytes)
end
assert(caseCount >= 5 and #projectSamples > 0 and #serializeSamples > 0,
  "P6 probe did not exercise enough audited commands")
assert(maxActiveRefs <= 2048 and maxWireBytes <= 1024 * 1024,
  "bounded P6 source limits exceeded")

local cleanupStart = os.clock()
for _, physical in ipairs(audiences) do
  protocol:disconnect(physical.audience)
end
local cleanupUs = math.floor((os.clock() - cleanupStart) * 1000000 + 0.5)
for _, physical in ipairs(audiences) do
  assert(protocol.audiences[physical.audience] == nil,
    "GameOver/disconnect cleanup must release active audience mapping")
end
local tombstones = countMap(protocol.issued)
assert(tombstones > 0 and cleanupUs < 5000000,
  "cleanup must finish with bounded tombstones and latency")

print(string.format(
  "CARD_WIRE_PERFORMANCE=PASS;cases=%d;audiences=3;iterations=%d;project_p95_us=%d;serialize_p95_us=%d;max_wire_bytes=%d;max_active_refs=%d;cleanup_us=%d;cleanup_active_refs=0;foreign_rejects=1;replay_rejects=1;stale_rejects=1;retired_tombstones=%d;synthetic-only;native/browser NOT RUN",
  caseCount, iterations, percentile(projectSamples, 0.95),
  percentile(serializeSamples, 0.95), maxWireBytes, maxActiveRefs, cleanupUs,
  tombstones))
