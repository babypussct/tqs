-- Exercise the actual candidate public-card client decoder. This is a
-- transport-free source probe: native CBOR and browser/QML remain separate.
local coreRoot, modulePath, refsPath = ...
assert(coreRoot and modulePath and refsPath, "candidate public client inputs required")
package.path = coreRoot .. "/?.lua;" .. coreRoot .. "/?/init.lua;" .. package.path

Card = { NoColor = 3 }

local function nativeCard(id, name)
  local card = { id = id, name = name or "slash", class = true }
  function card:isInstanceOf(class) return class == Card end
  return card
end

Fk = { cards = { [101] = nativeCard(101), [102] = nativeCard(102, "jink") } }
function Fk:getCardById(id) return self.cards[id] end
function Fk:cloneCard(name, suit, number)
  local card = nativeCard(0, name)
  card.suit, card.number, card.color = suit, number, Card.NoColor
  card.subcards, card.skillNames, card.mark = {}, {}, {}
  return card
end

local Refs = dofile(refsPath)
local Public = dofile(modulePath)
local room = { card_wire_version = 1, card_wire_refs = Refs.new() }
function room:getSettings(key)
  assert(key == "gameMode")
  return "new_heg_mode"
end

local function fail(fn, pattern)
  local ok, err = pcall(fn)
  assert(not ok and (not pattern or tostring(err):find(pattern, 1, true)),
    tostring(err))
end

local real = { cardWireCard = 1, kind = "real", ref = 101 }
local virtual = {
  cardWireCard = 1, kind = "virtual", name = "slash", suit = 1,
  number = 7, color = 1, subcards = {102}, skillNames = {"probe_skill"},
  virt_id = 9001, mark = { ["@probe"] = 1 },
}

local show = Public.receive(room, "ShowVirtualCard", {
  cardWireVersion = 1,
  payload = {
    { real, virtual }, 11,
    { type = "#UseCard", from = 11, card = { real, virtual }, arg = "probe",
      arg2 = real, toast = false },
    77,
  },
})
assert(show[1][1] == Fk.cards[101] and show[1][2].id == 0 and
  show[1][2].name == "slash" and show[1][2].subcards[1] == 102 and
  show[1][2].virt_id == 9001 and show[1][2].mark["@probe"] == 1 and
  show[3].card[1] == Fk.cards[101] and show[3].arg2 == Fk.cards[101])

local log = Public.receive(room, "GameLog", {
  cardWireVersion = 1,
  payload = {
    type = "#ResponsePlayCard", from = 11, to = {12},
    card = {101, virtual, -1}, arg = "probe", arg2 = real, toast = true,
  },
})
assert(log.type == "#ResponsePlayCard" and log.card[1] == Fk.cards[101] and
  log.card[2].id == 0 and log.card[2].subcards[1] == 102 and
  log.card[3] == -1 and log.arg2 == Fk.cards[101] and log.toast == true)

local unknown = Public.receive(room, "GameLog", {
  cardWireVersion = 1, payload = { type = "#Unknown", card = {{
    cardWireCard = 1, kind = "real", ref = 999,
  }} },
})
assert(unknown.card[1] == -1, "unknown public card must remain the upstream sentinel")

fail(function()
  Public.receive(room, "ShowVirtualCard", {
    cardWireVersion = 1, payload = {{
      { cardWireCard = 1, kind = "real", ref = "h:opaque" },
    }, 11, nil, 1 },
  })
end, "integer")
fail(function()
  Public.receive(room, "GameLog", {
    cardWireVersion = 1, payload = { type = "#Bad", arg = { cardId = 101 } },
  })
end, "unaudited field")
fail(function()
  Public.receive(room, "ShowVirtualCard", {
    cardWireVersion = 1, payload = {{virtual}, 11, nil, 1,
      extra = true},
  })
end, "unsupported field")
fail(function()
  Public.receive(room, "ShowVirtualCard", { payload = {{virtual}, 11, nil, 1} })
end, "version")

print("PASS candidate public client: ShowVirtualCard/GameLog descriptor decode, " ..
  "canonical refs, virtual marks/subcards, unknown and malformed/opaque/legacy " ..
  "fail-close; synthetic-only; native/browser NOT RUN")
