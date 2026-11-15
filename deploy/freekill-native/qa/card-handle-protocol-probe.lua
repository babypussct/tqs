-- Transport-free adversarial contract; uses made-up card IDs/tokens only.
local file = assert((...))
local Protocol = assert(loadfile(file))()
local counter = 0
local protocol = Protocol.new(function()
  counter = counter + 1
  return string.format("h:fixture_only_%016x", counter)
end)

local function denied(func)
  local ok = pcall(func)
  assert(not ok, "expected contract rejection")
end

local all = function() return true end
local none = function() return false end
local owner, peer, observer = "seat-1/socket-A", "seat-2/socket-B", "observer/socket-C"
local card, other = 811, 829

local ownerRef = protocol:reference(owner, card, false)
local peerRef = protocol:reference(peer, card, false)
local observerRef = protocol:reference(observer, card, false)
assert(type(ownerRef) == "string" and ownerRef ~= peerRef and peerRef ~= observerRef
  and ownerRef ~= observerRef, "same hidden ID must use distinct physical-audience handles")
assert(protocol:reference(owner, card, false) == ownerRef, "same-zone handle must be stable")
assert(protocol:project(owner, { card, other }, none)[1] == ownerRef)

local choices = protocol:issueChoice(owner, "discard/1", {
  { id = card, public = false }, { id = other, public = false },
})
assert(choices[1] ~= ownerRef and choices[2] ~= ownerRef
  and choices[1] ~= choices[2],
  "choice answers need fresh request-scoped tokens, distinct from zone handles")
assert(protocol:resolveChoice(peer, "discard/1", { ownerRef }, all) == nil,
  "different physical audience may not resolve a choice")
assert(protocol:resolveChoice(observer, "discard/1", { ownerRef }, all) == nil,
  "observer cannot forge seat choices")
assert(protocol:resolveChoice(owner, "discard/1", { peerRef }, all) == nil,
  "cross-audience token must fail")
assert(protocol:resolveChoice(owner, "discard/1", { ownerRef }, all) == nil,
  "failed request must already be consumed")

protocol:issueChoice(owner, "discard/2", { { id = card, public = false } })
assert(protocol:resolveChoice(owner, "discard/2", { card }, all) == nil,
  "guessing a canonical physical ID for hidden card must fail")
protocol:issueChoice(owner, "discard/3", { { id = card, public = false } })
assert(protocol:resolveChoice(owner, "discard/3", { ownerRef }, none) == nil,
  "current-state validation must prevent stale choices")
local valid = protocol:issueChoice(owner, "discard/4", { { id = card, public = false } })
assert(protocol:resolveChoice(owner, "discard/4", valid, all)[1] == card)
assert(protocol:resolveChoice(owner, "discard/4", valid, all) == nil,
  "choice replay must fail")
local outdated = protocol:issueChoice(owner, "discard/old", { { id = card, public = false } })
local renewed = protocol:issueChoice(owner, "discard/new", { { id = card, public = false } })
assert(outdated[1] ~= renewed[1], "reissued prompts must mint independent answer tokens")
protocol:cancelChoice(owner, "discard/old")
assert(protocol:resolveChoice(owner, "discard/new", outdated, all) == nil,
  "a delayed answer to an old request must not answer a newer request")
local renewedAgain = protocol:issueChoice(owner, "discard/new-again", {
  { id = card, public = false },
})
assert(protocol:resolveChoice(owner, "discard/new-again", renewedAgain, all)[1] == card)

protocol:issueChoice(owner, "discard/5", { { id = card, public = false } })
assert(protocol:resolveChoice(owner, "discard/5", {}, all) == nil,
  "empty response must not silently bypass a mandatory choice")
local two = protocol:issueChoice(owner, "discard/6", {
  { id = card, public = false }, { id = other, public = false },
}, 2, 2)
assert(protocol:resolveChoice(owner, "discard/6", { two[1] }, all) == nil,
  "two-card choice must reject a one-card response")
local optional = protocol:issueChoice(owner, "discard/optional", {
  { id = card, public = false },
}, 0, 1)
assert(#optional == 1 and #protocol:resolveChoice(owner, "discard/optional", {}, all) == 0,
  "explicit optional request may accept empty response")

-- Untrusted decoded CBOR arrays must be dense and contain no extra hash keys.
local keyed = protocol:issueChoice(owner, "discard/keyed", { { id = card, public = false } })
local wrongShape = { keyed[1] }
wrongShape.unexpected = keyed[1]
local decoded, err = protocol:resolveChoice(owner, "discard/keyed", wrongShape, all)
assert(decoded == nil and err == "invalid_reference_array",
  "a keyed reply with an otherwise valid first reference must be rejected")
assert(protocol:resolveChoice(owner, "discard/keyed", keyed, all) == nil,
  "malformed response must consume the request")
local sparse = protocol:issueChoice(owner, "discard/sparse", {
  { id = card, public = false }, { id = other, public = false },
})
decoded, err = protocol:resolveChoice(owner, "discard/sparse", { [1] = sparse[1], [3] = sparse[2] }, all)
assert(decoded == nil and err == "invalid_reference_array",
  "a sparse reply with valid references must be rejected")
assert(protocol:resolveChoice(owner, "discard/sparse", sparse, all) == nil,
  "sparse response must consume the request")

local beforeBadInput = counter
denied(function() protocol:project(owner, { [1] = card, [3] = other }, none) end)
denied(function() protocol:project(owner, { [1] = card, debug = other }, none) end)
denied(function() protocol:project(owner, { 901, 902 }, function(id)
  if id == 902 then error("synthetic visibility failure") end
  return false
end) end)
denied(function() protocol:project(owner, { 901 }, function() return nil end) end)
denied(function() protocol:rekey(owner, { [1] = card, [3] = other }) end)
denied(function() protocol:rekey(owner, { [1] = card, unexpected = other }) end)
denied(function() protocol:issueChoice(owner, "invalid/duplicate", {
  { id = 901, public = false }, { id = 901, public = false },
}) end)
denied(function() protocol:issueChoice(owner, "invalid/visibility", {
  { id = 901, public = false }, { id = 902, public = nil },
}) end)
denied(function() protocol:issueChoice(owner, "invalid/hash", {
  { id = 901, public = false }, extra = { id = 902, public = false },
}) end)
denied(function() protocol:issueChoice(owner, "invalid/sparse", {
  [1] = { id = 901, public = false }, [3] = { id = 902, public = false },
}) end)
assert(counter == beforeBadInput,
  "invalid choice/project/rekey input must not mint partial handles")

-- Printed cards are negative, while virtual cards are allocated above 65535.
local printed, virtual = -2, 65536
local printedRef = protocol:reference(owner, printed, false)
local virtualRef = protocol:reference(owner, virtual, false)
assert(type(printedRef) == "string" and type(virtualRef) == "string"
  and printedRef ~= virtualRef,
  "printed and virtual cards require distinct opaque references")
local mixed = protocol:issueChoice(owner, "printed-virtual", {
  { id = printed, public = false }, { id = virtual, public = false },
}, 2, 2)
local mixedDecoded = protocol:resolveChoice(owner, "printed-virtual", mixed, all)
assert(mixedDecoded[1] == printed and mixedDecoded[2] == virtual,
  "printed and virtual cards must round-trip through scoped choice")
protocol:rekey(owner, { printed, virtual })
assert(protocol:reference(owner, printed, false) ~= printedRef
  and protocol:reference(owner, virtual, false) ~= virtualRef,
  "printed and virtual card handles must rekey")
denied(function() protocol:reference(owner, -1, false) end)

-- A CSPRNG failure in the middle of a projection/choice must not commit a
-- half-installed mapping or destroy an existing request. Issued values stay
-- tombstoned even when their staged transaction is abandoned.
local stagedCalls = 0
local staged = Protocol.new(function()
  stagedCalls = stagedCalls + 1
  if stagedCalls == 3 or stagedCalls == 5 then
    error("synthetic secure generator failure")
  end
  return string.format("h:staged_fixture_%016x", stagedCalls)
end)
local existing = staged:issueChoice("a", "existing", { { id = 700, public = false } })
denied(function() staged:issueChoice("a", "aborted", {
  { id = 701, public = false }, { id = 702, public = false },
}, 2, 2) end)
assert(staged.audiences.a.byId[701] == nil
  and staged.audiences.a.requests.aborted == nil,
  "failed choice must not leave a partial card mapping or request")
assert(staged:resolveChoice("a", "existing", existing, all)[1] == 700,
  "failed choice must preserve previously valid requests")
local afterAborted = staged:reference("a", 701, false)
assert(afterAborted ~= "h:staged_fixture_0000000000000002",
  "aborted minted handle must stay tombstoned")
denied(function() staged:project("a", { 703, 704 }, none) end)
assert(staged.audiences.a.byId[703] == nil
  and staged.audiences.a.byId[704] == nil,
  "failed projection must not commit either card's mapping")

-- Reveal retires the old concealed handle. A later rehide must mint a fresh one.
local beforeReveal = protocol:reference(peer, other, false)
assert(protocol:reference(peer, other, true) == other)
local afterRehide = protocol:reference(peer, other, false)
assert(afterRehide ~= beforeReveal)
local visible = protocol:issueChoice(peer, "choice/visible", { { id = card, public = true } })
assert(type(visible[1]) == "string" and visible[1] ~= card,
  "public choices must mint one-shot answer tokens, not expose canonical IDs as answers")
assert(protocol:reference(peer, card, true) == card,
  "repeat public visibility must preserve the currently issued public choice")
assert(protocol:resolveChoice(peer, "choice/visible", visible, all)[1] == card,
  "public answer token must resolve to its canonical card inside the issued request")
assert(protocol:resolveChoice(peer, "choice/visible", visible, all) == nil,
  "public answer token must not be replayable")
local stalePublic = protocol:issueChoice(peer, "choice/visible-stale", {
  { id = card, public = true },
})
local visibleRepeat = protocol:issueChoice(peer, "choice/visible-repeat", {
  { id = card, public = true },
})
assert(stalePublic[1] ~= visibleRepeat[1],
  "sequential public prompts must never reuse answer tokens")
assert(protocol:project(peer, { card }, all)[1] == card,
  "public snapshot should not invalidate a choice merely by rendering")
assert(protocol:resolveChoice(peer, "choice/visible-repeat", stalePublic, all) == nil,
  "delayed public answer must never satisfy a new prompt for the same card")
local visibleAgain = protocol:issueChoice(peer, "choice/visible-again", {
  { id = card, public = true },
})
assert(protocol:resolveChoice(peer, "choice/visible-again", { card }, all) == nil,
  "raw canonical public ID alone must not satisfy a choice request")
local visibleValid = protocol:issueChoice(peer, "choice/visible-valid", {
  { id = card, public = true },
})
assert(protocol:resolveChoice(peer, "choice/visible-valid", visibleValid, all)[1] == card)
local expiringPublic = protocol:issueChoice(peer, "choice/rehide-expiry", {
  { id = card, public = true },
})
local rehidden = protocol:reference(peer, card, false)
assert(type(rehidden) == "string" and rehidden ~= card,
  "rehidden card must have a concealed handle")
assert(protocol:resolveChoice(peer, "choice/rehide-expiry", expiringPublic, all) == nil,
  "public choice must expire when the card is hidden again")

local preShuffle = protocol:reference(peer, card, false)
protocol:issueChoice(peer, "pending/shuffle", { { id = card, public = false } })
protocol:rekey(peer, { card, other })
assert(protocol:reference(peer, card, false) ~= preShuffle,
  "shuffle must rekey concealed references")
assert(protocol:resolveChoice(peer, "pending/shuffle", { preShuffle }, all) == nil,
  "shuffle must invalidate pending choices")

protocol:issueChoice(owner, "pending/leave", { { id = card, public = false } })
protocol:disconnect(owner)
assert(protocol:resolveChoice(owner, "pending/leave", { ownerRef }, all) == nil,
  "disconnect/reconnect must reject stale requests")
assert(protocol:reference(owner, card, false) ~= ownerRef,
  "reconnect must never reactivate old handles")

denied(function() protocol:reference(owner, 0, false) end)
denied(function() protocol:reference(owner, card, nil) end)
denied(function() protocol:issueChoice(owner, "bad", {
  { id = card, public = false }, { id = card, public = false } }) end)
denied(function() Protocol.new() end)
local duplicate = Protocol.new(function() return "h:aaaaaaaaaaaaaaaa" end)
duplicate:reference("a", card, false)
denied(function() duplicate:reference("b", card, false) end)

-- One notification is a transaction across all physical recipients. A late
-- failure must preserve already committed maps and one-shot choices.
local serial, failNextMint = 0, false
local atomic = Protocol.new(function()
  serial = serial + 1
  if failNextMint then
    failNextMint = false
    error("synthetic generator stopped mid-batch")
  end
  return string.format("h:atomic_fixture_%016x", serial)
end)
local baseline = atomic:issueChoice(owner, "still-pending", {
  { id = 900, public = false },
})[1]
local standing900 = atomic:reference(owner, 900, false)
local batch = atomic:beginBatch()
denied(function() atomic:beginBatch() end)
denied(function() atomic:reference(owner, 901, false) end)
denied(function() atomic:project(owner, { 901 }, none) end)
denied(function() atomic:disconnect(owner) end)
local abortedOwner = batch:reference(owner, 901, false)
local abortedObserver = batch:reference(observer, 901, false)
assert(abortedOwner ~= abortedObserver, "staged hidden refs must be audience-specific")
assert(batch:project(owner, { 901 }, none)[1] == abortedOwner,
  "repeated projection in one batch must reuse staged mappings")
batch:rekey(owner, { 900 })
assert(batch:reference(owner, 900, false) ~= standing900,
  "staged rekey must create a new handle")
assert(atomic.audiences[owner].byId[901] == nil
  and atomic.audiences[owner].byId[900] == standing900
  and atomic.audiences[owner].requests["still-pending"] ~= nil
  and atomic.audiences[observer] == nil,
  "staging must not mutate committed audiences or pending requests")
batch:abort()
denied(function() batch:commit() end)
denied(function() batch:abort() end)
denied(function() batch:reference(owner, 902, false) end)
assert(atomic:resolveChoice(owner, "still-pending", { baseline }, all)[1] == 900,
  "aborted rekey must preserve an existing request")
assert(atomic.issued[abortedOwner] and atomic.issued[abortedObserver]
  and atomic:reference(owner, 901, false) ~= abortedOwner,
  "aborted minted tokens must remain tombstoned")

local successful = atomic:beginBatch()
local ownerCommitted = successful:reference(owner, 903, false)
local observerCommitted = successful:project(observer, { 903, 904 }, none)
successful:rekey(owner, { 900 })
assert(atomic.audiences[owner].byId[903] == nil
  and atomic.audiences[observer] == nil)
successful:commit()
denied(function() successful:commit() end)
assert(atomic:reference(owner, 903, false) == ownerCommitted
  and atomic:reference(observer, 903, false) == observerCommitted[1]
  and atomic:reference(observer, 904, false) == observerCommitted[2],
  "commit must publish all recipients together")
assert(atomic.audiences[owner].byId[900] == nil,
  "rekey must be visible only after commit")

local bad = atomic:beginBatch()
local preFailure = bad:reference(owner, 905, false)
denied(function() bad:project(observer, { 906, 907 }, function(id)
  if id == 907 then error("synthetic visibility callback failure") end
  return false
end) end)
denied(function() bad:reference(owner, 908, false) end)
denied(function() bad:commit() end)
assert(atomic.audiences[owner].byId[905] == nil
  and atomic.audiences[observer].byId[906] == nil,
  "failed batch must not expose staged state")
bad:abort()
assert(atomic.issued[preFailure], "failed batch must retire already issued handles")

local malformed = atomic:beginBatch()
denied(function() malformed:rekey(owner, { [1] = 903, [3] = 904 }) end)
denied(function() malformed:commit() end)
malformed:abort()
assert(atomic.audiences[owner].byId[903] == ownerCommitted,
  "malformed batch must preserve committed refs")

local badMint = atomic:beginBatch()
local issuedBeforeFailure = badMint:reference(owner, 909, false)
-- Inject a reproducible entropy failure into this second recipient.
failNextMint = true
denied(function() badMint:reference(observer, 910, false) end)
denied(function() badMint:commit() end)
badMint:abort()
assert(atomic.audiences[owner].byId[909] == nil
  and atomic.issued[issuedBeforeFailure],
  "mid-batch generator exception must not commit handles")

-- Native ask/response prompts can be projected inside the same notification
-- transaction. Aborting delivery must roll back the issued allowlist too.
local pendingChoice = atomic:beginBatch()
local ownerChoice = pendingChoice:issueChoice(owner, "prompt/aborted", {
  { id = 913, public = false }, { id = 914, public = false },
}, 1, 2)
local observerChoice = pendingChoice:issueChoice(observer, "prompt/aborted", {
  { id = 913, public = false },
})
assert(ownerChoice[1] ~= observerChoice[1],
  "batch choices must retain distinct physical-audience handles")
denied(function() atomic:resolveChoice(owner, "prompt/aborted", ownerChoice, all) end)
pendingChoice:abort()
assert(atomic:resolveChoice(owner, "prompt/aborted", ownerChoice, all) == nil
  and atomic:resolveChoice(observer, "prompt/aborted", observerChoice, all) == nil,
  "aborted multi-recipient prompts must never be actionable")
assert(atomic.issued[ownerChoice[1]] and atomic.issued[observerChoice[1]],
  "aborted request references must remain globally retired")

local delivered = atomic:beginBatch()
local deliveredOwner = delivered:issueChoice(owner, "prompt/delivered", {
  { id = 913, public = false }, { id = 914, public = false },
}, 2, 2)
delivered:issueChoice(observer, "prompt/delivered", {
  { id = 913, public = false },
})
delivered:commit()
assert(atomic:resolveChoice(owner, "prompt/delivered", deliveredOwner, all)[2] == 914,
  "committed batch must publish its exact one-shot request allowlist")
assert(atomic:resolveChoice(owner, "prompt/delivered", deliveredOwner, all) == nil,
  "committed batch requests must still reject replay")

local canceled = atomic:beginBatch()
canceled:issueChoice(owner, "prompt/canceled", { { id = 915, public = false } })
canceled:cancelChoice(owner, "prompt/canceled")
canceled:commit()
assert(atomic:resolveChoice(owner, "prompt/canceled", { 915 }, all) == nil,
  "canceling a staged prompt must not publish an active allowlist")

local invalidBatch = atomic:beginBatch()
denied(function() invalidBatch:issueChoice(owner, "prompt/bad", {
  { id = 916, public = false }, [3] = { id = 917, public = false },
}) end)
denied(function() invalidBatch:commit() end)
invalidBatch:abort()
assert(atomic.audiences[owner].requests["prompt/bad"] == nil,
  "malformed staged choice must fail closed and retain committed state")

-- A returning socket needs fresh identities. An aborted snapshot must leave
-- old committed state intact, and a successful snapshot must retire it only
-- for that physical audience (not the other controller or an observer).
local oldReconnect = atomic:issueChoice(owner, "reconnect/old", {
  { id = 920, public = false },
})[1]
local otherSocket = atomic:reference(observer, 920, false)
local failedReconnect = atomic:beginBatch()
failedReconnect:resetAudience(owner)
local abortedReconnect = failedReconnect:reference(owner, 920, false)
assert(abortedReconnect ~= oldReconnect,
  "reconnect staging must mint an independent new reference")
failedReconnect:abort()
assert(atomic:resolveChoice(owner, "reconnect/old", { oldReconnect }, all)[1] == 920,
  "aborted reconnect must preserve last committed request")
assert(atomic:reference(observer, 920, false) == otherSocket,
  "aborted reconnect cannot change another socket's mapping")
local oldReconnectAgain = atomic:issueChoice(owner, "reconnect/pending", {
  { id = 920, public = false },
})[1]
local goodReconnect = atomic:beginBatch()
goodReconnect:resetAudience(owner)
local refreshed = goodReconnect:reference(owner, 920, false)
goodReconnect:commit()
assert(refreshed ~= oldReconnectAgain and refreshed ~= abortedReconnect,
  "successful reconnect must not reuse old or aborted handles")
assert(atomic:resolveChoice(owner, "reconnect/pending", { oldReconnectAgain }, all) == nil,
  "committed reconnect must invalidate all previous session choices")
assert(atomic:reference(observer, 920, false) == otherSocket,
  "reconnect must not alter independent observer identity")

print("PASS opaque card-handle contract: physical audiences, choice scope, replay, " ..
  "reveal, rehide, shuffle, reconnect, token collision, printed/virtual IDs, strict CBOR arrays; " ..
  "multi-recipient atomic commit/abort/tombstones, staged choice allowlists, " ..
  "physical reconnect reset; " ..
  "synthetic-only; native/browser NOT RUN")
