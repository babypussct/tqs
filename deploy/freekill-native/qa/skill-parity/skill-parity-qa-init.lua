local config = assert(ServerConfig.tqsQa)
assert(config.enabled and (config.maxPlayers == 2 or config.maxPlayers == 3))
local chainLane = config.maxPlayers == 3
local hiddenCases = {
  ['0x2'] = {name='main-effect', card='slash', red=true, prelight=true, choice='effect'},
  ['0x3'] = {name='deputy-remove', deputy=true, card='slash', red=true, prelight=true, choice='remove'},
  ['0x4'] = {name='black', card='slash', red=false, prelight=true},
  ['0x5'] = {name='unlit', deputy=true, card='slash', red=true, prelight=false},
  ['0x6'] = {name='trick', card='snatch', red=true, prelight=true, choice='effect'},
  ['0x7'] = {name='delayed', card='indulgence', red=true, prelight=true},
  ['0x8'] = {name='multi', card='archery_attack', red=true, prelight=true},
  ['0x9'] = {name='main-remove', card='slash', red=true, prelight=true, choice='remove'},
  ['0x11'] = {name='decline', card='slash', red=true, prelight=true},
  ['0x10'] = {name='deputy-effect', deputy=true, card='slash', red=true, prelight=true, choice='effect'},
}
local tlCases = {['0x12']='physical', ['0x13']='success', ['0x14']='cancel', ['0x15']='prevent'}
local hiddenCase, hiddenActor
local hiddenEffects, hiddenDamage, hiddenConfirmed, hiddenResolutions = 0, 0, 0, 0
local extension = Package:new('tqs_qa', Package.SpecialPack)
extension.extensionName = 'tqs_qa'
local director = fk.CreateSkill {name = 'tqs_qa_skill_parity_director&'}
local ran, prevent = false, false
local directDamage, chainDamage, activeMode = 0, 0, nil
local tlConfirmed, tlResolutions, tlAttempts = 0, 0, 0
local tlShown, tlCost
local function check(ok, label)
  fk.qInfo('[TQS_QA_SKILL_PARITY] ' .. (ok and 'PASS ' or 'FAIL ') .. label)
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
local function clearHand(room, p)
  local ids = p:getCardIds('he')
  if #ids > 0 then room:throwCard(ids, 'tqs_qa', p, p) end
end
local function give(room, player, predicate, label)
  local id
  for _, pile in ipairs({room.draw_pile, room.discard_pile}) do
    for _, cid in ipairs(pile) do
      if predicate(Fk:getCardById(cid)) then id=cid; break end
    end
    if id then break end
  end
  assert(id,'fixture card unavailable')
  if label then check(room:getCardArea(id) == Card.DrawPile, 'private fixture card from draw pile '..label) end
  room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonJustMove, label or 'tqs_qa', nil, false, player)
  return id
end
director:addEffect(fk.DamageInflicted, {
  global = true, priority = 2000,
  can_trigger = function(self, event, target, player, data)
    return activeMode ~= nil and target == player and data.card and data.card.name == 'fire_attack'
  end,
  on_trigger = function(self, event, target, player, data)
    tlAttempts = tlAttempts + 1
    local parent = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    check(parent and parent.data.to == player.room.players[2] and
      table.contains(parent.data.extra_data.fire_attack_show or {}, tlShown) and
      table.contains(parent.data.extra_data.fire_attack_discard or {}, tlCost), 'TL parent CardEffect and exact show/cost')
    fk.qInfo('[TQS_QA_SKILL_PARITY] trace DamageInflicted chain='..tostring(not not data.chain))
    return false
  end,
})
director:addEffect(fk.DamageInflicted, {
  global = true, priority = 1000,
  can_trigger = function(self, event, target, player, data) return prevent and target == player end,
  on_trigger = function(self, event, target, player, data)
    prevent = false
    data:preventDamage()
    return true
  end,
})
director:addEffect(fk.Damage, {
  global = true, priority = 1000,
  can_trigger = function(self, event, target, player, data)
    return activeMode ~= nil and target == player and data.card and data.card.name == 'fire_attack'
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    check(data.damage == 1 and data.damageType == fk.FireDamage, 'Fire Attack damage amount/nature '..activeMode)
    if data.chain then
      check(chainLane and data.to == room.players[3], 'chain damage target')
      chainDamage = chainDamage + 1
    else
      check(data.to == room.players[2], 'direct damage target '..activeMode)
      directDamage = directDamage + 1
    end
    return false
  end,
})
local function runHidden(room, source, actor, case)
  hiddenCase, hiddenActor = case, actor
  local slot = case.deputy and 'deputyGeneral' or 'general'
  local other = case.deputy and 'general' or 'deputyGeneral'
  local mark = case.deputy and '__heg_deputy' or '__heg_general'
  local otherMark = case.deputy and '__heg_general' or '__heg_deputy'
  room:setPlayerMark(source, 'tqs_qa_hidden_phase', 1)
  check(actor.general == 'anjiang' and actor.deputyGeneral == 'anjiang', 'hidden initial slots')
  room:setPlayerMark(actor, mark, 'ld__yanbaihu')
  room:setPlayerMark(actor, otherMark, 'ld__huangzu')
  room:setPlayerMark(actor, '__heg_wild', 0)
  room:setPlayerMark(actor, '__heg_kingdom', 'qun')
  room:setPlayerMark(actor, '__heg_init_kingdom', 'qun')
  for _, pair in ipairs({{'ld__yanbaihu', case.deputy}, {'ld__huangzu', not case.deputy}}) do
    for _, name in ipairs(Fk.generals[pair[1]]:getSkillNameList(true)) do
      local skill = Fk.skills[name]
      if not skill:hasTag(pair[2] and Skill.MainPlace or Skill.DeputyPlace) then
        room:addFakeSkill(actor, name)
      end
    end
  end
  room:addFakeSkill(actor, 'reveal_skill&')
  check(actor:isFakeSkill('ld__jilix') and not actor:hasSkill('ld__jilix'), 'hidden fake inactive')
  local gate = Request:new(actor, 'AskForSkillInvoke')
  gate.timeout = 12
  gate.receive_decode = false
  gate:setData(actor, {'tqs_qa_hidden_jilix_gate', 'prelight readiness'})
  check(gate:getResult(actor) ~= '', 'hidden readiness reply')
  check(table.contains(actor.prelighted_skills, Fk.skills.ld__jilix) == case.prelight, 'hidden real prelight state')
  check(actor:hasSkill('ld__jilix') == case.prelight and actor[slot] == 'anjiang', 'hidden activation before target')
  -- Seed the bounded action after initial deal, and fix semantic card faces.
  room:randomseed(20261127, 5)
  local faces = {slash={case.red and Card.Heart or Card.Spade, case.red and 10 or 5},
    snatch={Card.Diamond, 3}, indulgence={Card.Heart, 6}, archery_attack={Card.Heart, 1}}
  local face = faces[case.card]
  local id = give(room, source, function(c)
    return c.name == case.card and c.suit == face[1] and c.number == face[2]
  end)
  if case.name == 'trick' then
    give(room, actor, function(c) return c.name == 'jink' and c.suit == Card.Heart and c.number == 2 end)
    give(room, actor, function(c) return c.name == 'peach' and c.suit == Card.Heart and c.number == 4 end)
  end
  local targets = {actor}
  if case.name == 'multi' then targets[2] = room.players[3] end
  local req = Request:new(source, 'PlayCard')
  req.timeout = 12
  local reply = req:getResult(source)
  check(type(reply) == 'table' and reply.card == id and #reply.targets == #targets, 'hidden physical PlayCard')
  for i, target in ipairs(targets) do
    check(reply.targets[i] == target.id, 'hidden PlayCard target '..i)
  end
  local use = room:handleUseCardReply(source, reply)
  check(type(use) == 'table', 'hidden PlayCard dispatch')
  use.extraUse = true
  room:useCard(use)
  check(hiddenConfirmed == 1, 'hidden TargetConfirmed once')
  check(hiddenEffects == (case.choice and 1 or 0), 'hidden SkillEffect count')
  local expected = case.choice == 'remove' and 'blank_shibing' or case.choice and 'ld__yanbaihu' or 'anjiang'
  check(actor[slot] == expected and actor[other] == 'anjiang' and actor:getMark(otherMark) == 'ld__huangzu', 'hidden owning slot only')
  check(actor:hasSkill('ld__jilix') == (case.choice ~= 'remove' and case.prelight), 'hidden final skill state')
  if case.card == 'slash' or case.card == 'archery_attack' then
    local count = case.choice == 'effect' and 2 or 1
    check(hiddenDamage == count and hiddenResolutions == count, 'hidden damage and resolution count')
  elseif case.card == 'snatch' then
    check(hiddenResolutions == 2 and #actor:getCardIds('h') == 0 and #source:getCardIds('h') == 2, 'hidden trick two successful obtains')
  elseif case.card == 'indulgence' then
    check(room:getCardArea(id) == Card.PlayerJudge and room:getCardOwner(id) == actor, 'hidden delayed trick placed in judge area')
  end
  fk.qInfo('[TQS_QA_SKILL_PARITY] hidden case '..case.name..' actionSeed=20261127:5 confirmed='..hiddenConfirmed..' effects='..hiddenEffects..' resolutions='..hiddenResolutions..' damage='..hiddenDamage)
  room:setPlayerMark(source, 'tqs_qa_hidden_phase', 2)
  hiddenCase = nil
end

director:addEffect(fk.TargetConfirmed, {
  global=true, priority=1000,
  can_trigger=function(self,event,target,player,data)
    return hiddenCase and target == hiddenActor and player == target and data.card.name == hiddenCase.card
  end,
  on_trigger=function(self,event,target,player,data)
    hiddenConfirmed = hiddenConfirmed + 1
    check(player.general == 'anjiang' and player.deputyGeneral == 'anjiang', 'hidden before TargetConfirmed effect')
    check(data:isOnlyTarget(player) == (hiddenCase.name ~= 'multi'), 'hidden target cardinality')
    return false
  end,
})
director:addEffect(fk.SkillEffect, {
  global=true, priority=1000,
  can_trigger=function(self,event,target,player,data)
    return hiddenCase and target == hiddenActor and player == target and data.skill:getSkeleton().name == 'ld__jilix'
  end,
  on_trigger=function(self,event,target,player,data)
    hiddenEffects = hiddenEffects + 1
    check(player[hiddenCase.deputy and 'deputyGeneral' or 'general'] == 'ld__yanbaihu' and
      player[hiddenCase.deputy and 'general' or 'deputyGeneral'] == 'anjiang', 'hidden reveal before SkillEffect')
    return false
  end,
})
director:addEffect(fk.CardEffecting, {
  global=true, priority=1000,
  can_trigger=function(self,event,target,player,data)
    return hiddenCase and data.to == hiddenActor and player == hiddenActor and data.card.name == hiddenCase.card
  end,
  on_trigger=function(self,event,target,player,data)
    hiddenResolutions = hiddenResolutions + 1
    fk.qInfo("[TQS_QA_SKILL_PARITY] trace CardEffecting " .. hiddenResolutions)
    return false
  end,
})
-- Observe successful damage rather than HP deltas, since general removal can change max HP.
director:addEffect(fk.Damaged, {
  global=true, priority=1000,
  can_trigger=function(self,event,target,player,data)
    return hiddenCase and target == hiddenActor and player == target and data.card and data.card.name == hiddenCase.card
  end,
  on_trigger=function(self,event,target,player,data)
    hiddenDamage = hiddenDamage + data.damage
    fk.qInfo("[TQS_QA_SKILL_PARITY] trace Damaged total=" .. hiddenDamage)
    return false
  end,
})
director:addEffect(fk.TargetConfirmed, {
  global=true, priority=1000,
  can_trigger=function(self,event,target,player,data)
    return activeMode and target == player and player == player.room.players[2] and data.card.name == 'fire_attack'
  end,
  on_trigger=function()
    tlConfirmed = tlConfirmed + 1
    fk.qInfo('[TQS_QA_SKILL_PARITY] trace TL TargetConfirmed '..tlConfirmed)
    return false
  end,
})
director:addEffect(fk.CardEffecting, {
  global=true, priority=1000,
  can_trigger=function(self,event,target,player,data)
    return activeMode and data.to == player and player == player.room.players[2] and data.card.name == 'fire_attack'
  end,
  on_trigger=function()
    tlResolutions = tlResolutions + 1
    fk.qInfo('[TQS_QA_SKILL_PARITY] trace TL CardEffecting '..tlResolutions)
    return false
  end,
})
local function runLiaoye(room, owner, chooser, other)
  room:changeHero(owner, 'heg__jiananfeng', false, false, false, false, false)
  room:setPlayerMark(owner, '__heg_general', 'heg__jiananfeng')
  check(owner:hasSkill('heg__liaoye'), 'Liêu Dã acquired from Giả Nam Phong')
  for _, case in ipairs({
    {name = 'chosen', chooserHp = 10, otherHp = 9},
    {name = 'unchosen', chooserHp = 9, otherHp = 10},
    {name = 'empty', chooserHp = 9, otherHp = 9},
    {name = 'no-reply'},
  }) do
    for _, p in ipairs(room.players) do
      room:setPlayerProperty(p, 'maxHp', 10)
      room:setPlayerProperty(p, 'hp', 10)
      room:setPlayerProperty(p, 'shield', 0)
    end
    owner:setSkillUseHistory('heg__liaoye', 0, Player.HistoryPhase)
    local request = Request:new(owner, 'PlayCard')
    local reply = request:getResult(owner)
    check(type(reply) == 'table' and reply.card.skill == 'heg__liaoye'
      and #reply.targets == 1 and reply.targets[1] == chooser.id, 'Liêu Dã PlayCard ' .. case.name)
    room:handleUseCardReply(owner, reply)
    local validHp = chooser.hp == case.chooserHp and other.hp == case.otherHp
    if case.name == 'no-reply' then
      validHp = (chooser.hp == 9 and other.hp == 10) or (chooser.hp == 10 and other.hp == 9)
    end
    check(owner.hp == 10 and validHp, 'Liêu Dã HP ' .. case.name)
  end
end

director:addEffect(fk.GameStart, {
  global = true, priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local room=player.room
    local suffix = room:getSettings('roomName'):match('^TQSQA/skill%-parity/(0x%d+)$')
    if ran or player ~= room.players[1] or not (suffix == '0x1' or suffix == '0x16'
      or hiddenCases[suffix] or tlCases[suffix]) or #room.players ~= config.maxPlayers then return false end
    return table.every(room.players,function(p) return table.contains(config.allowedUsers,p._splayer:getScreenName()) end)
  end,
  on_trigger = function(self,event,target,player,data)
    ran=true
    local room,enemy=player.room,player.room.players[2]
    check(room.card_wire_version==1,'v1')
    for _,p in ipairs(room.players) do clearFake(p); clearHand(room,p) end
    room:setCurrent(player)
    room:setPlayerProperty(player,'phase',Player.Play)
    room:setPlayerProperty(enemy,'maxHp',10)
    room:setPlayerProperty(enemy,'hp',10)
    room:setPlayerProperty(enemy,'shield',0)
    local suffix = room:getSettings('roomName'):match('0x%d+$')
    if suffix == '0x16' then
      runLiaoye(room, player, enemy, room.players[3])
      fk.qInfo('[TQS_QA_SKILL_PARITY] SUMMARY PASS')
      room:gameOver('')
      return
    end
    local case = hiddenCases[suffix]
    if case then
      runHidden(room, player, enemy, case)
      fk.qInfo('[TQS_QA_SKILL_PARITY] SUMMARY PASS')
      room:gameOver('')
      return
    end
    local tlCase = tlCases[suffix]
    local modes = chainLane and {'chain'} or tlCase and {tlCase} or {'physical','success','cancel','prevent'}
    for _,mode in ipairs(modes) do
      clearHand(room,player); clearHand(room,enemy)
      room:setPlayerProperty(enemy,'hp',10)
      local physical = mode == 'physical'
      if not physical and (tlCase or mode == 'success' or mode == 'chain') then
        room:handleAddLoseSkills(player,'ld__chenglue',nil,false,true)
      end
      room:randomseed(20261127, 4)
      local selected = give(room,player,function(c)
        if tlCase or chainLane then
          return physical and c.name == 'fire_attack' and c.suit == Card.Heart and c.number == 3 or
            not physical and c.name == 'slash' and c.suit == Card.Spade and c.number == 5
        end
        return physical and c.name == 'fire_attack' or not physical and c.type == Card.TypeBasic
      end)
      local shown = give(room,enemy,function(c)
        if tlCase then return c.name == 'jink' and c.suit == Card.Heart and c.number == 2 end
        if chainLane then return c.name == 'jink' and c.suit == Card.Heart end
        return c.suit == Card.Heart
      end, chainLane and 'tqs_qa_parity_shown' or nil)
      local cost = give(room,player,function(c)
        if tlCase or chainLane then return c.name == 'peach' and c.suit == Card.Heart and c.number == 4 end
        return c.suit == Card.Heart
      end)
      local third, thirdCard
      if chainLane then
        third = room.players[3]
        room:setPlayerProperty(third, 'maxHp', 10)
        room:setPlayerProperty(third, 'hp', 10)
        room:setPlayerProperty(third, 'shield', 0)
        thirdCard = give(room, third, function(c) return c.name == 'slash' and c.suit == Card.Spade end, 'tqs_qa_parity_third')
        enemy:setChainState(true)
        third:setChainState(true)
        check(enemy.chained and third.chained and not player.chained, 'chain setup')
      end
      local hand = player:getCardIds('he')
      check(#hand == 2 and hand[1] == selected and hand[2] == cost, 'fixed PlayCard hand '..mode)
      prevent = mode == 'prevent'
      -- Use the real request and the same reply dispatcher as Phase:main.
      -- The fixture bounds the phase to one PlayCard per case.
      local req = Request:new(player, 'PlayCard')
      req.timeout = 12
      local reply = req:getResult(player)
      check(type(reply) == 'table' and #reply.targets == 1 and reply.targets[1] == enemy.id, 'PlayCard target '..mode)
      if physical then
        check(reply.card == selected, 'physical PlayCard reference')
      else
        check(type(reply.card) == 'table' and reply.card.skill == 'ld__chenglue' and
          #reply.card.subcards == 1 and reply.card.subcards[1] == selected, 'view-as PlayCard reference '..mode)
      end
      activeMode = mode
      directDamage, chainDamage = 0, 0
      tlConfirmed, tlResolutions, tlAttempts = 0, 0, 0
      tlShown, tlCost = shown, cost
      local use = room:handleUseCardReply(player, reply)
      if type(use) == 'table' then room:useCard(use) end
      activeMode = nil
      local hits = (physical or mode == 'success' or chainLane) and 1 or 0
      fk.qInfo('[TQS_QA_SKILL_PARITY] damage counts '..mode..' direct='..directDamage..' chain='..chainDamage)
      check(tlConfirmed == 1 and tlResolutions == 1 and tlAttempts == (mode == 'cancel' and 0 or chainLane and 2 or 1), 'TL event counts '..mode)
      fk.qInfo('[TQS_QA_SKILL_PARITY] TL case '..mode..' actionSeed=20261127:4 confirmed='..tlConfirmed..' resolutions='..tlResolutions..' attempts='..tlAttempts)
      check(directDamage == hits and chainDamage == (chainLane and 1 or 0), 'damage event count '..mode)
      if chainLane then
        check(third.hp == 9 and not third.chained and not enemy.chained, 'chain HP and unlink')
        check(room:getCardArea(thirdCard) == Card.PlayerHand and table.contains(third:getCardIds('h'), thirdCard), 'third-seat card retained')
      end
      check(room:getCardArea(selected) == Card.DiscardPile, 'PlayCard consumed '..mode)
      check(enemy.hp == (hits == 1 and 9 or 10), 'Fire Attack HP '..mode)
      check(room:getCardArea(shown) == ((mode == 'success' or chainLane) and Card.DiscardPile or Card.PlayerHand), 'Fire Attack shown-card area '..mode)
      check(room:getCardArea(cost) == (mode == 'cancel' and Card.PlayerHand or Card.DiscardPile), 'Fire Attack cost '..mode)
      check(not prevent, 'damage prevention consumed '..mode)
    end
    room:handleAddLoseSkills(player,'-ld__chenglue',nil,false,true)
    for _,deputy in ipairs((chainLane or tlCase) and {} or {false,true}) do
      local slot=deputy and 'deputyGeneral' or 'general'
      local mark=deputy and '__heg_deputy' or '__heg_general'
      room:changeHero(enemy,'ld__yanbaihu',false,deputy,false,false,false)
      room:setPlayerMark(enemy,mark,'ld__yanbaihu')
      check(enemy:hasSkill('ld__jilix'),'Jilix acquired '..slot)
      for _,mode in ipairs({'effect','remove'}) do
        clearHand(room,enemy); clearHand(room,player)
        room:setPlayerProperty(enemy,'hp',10)
        local id=give(room,player,function(c) return c.name=='slash' and c.color==Card.Red end)
        room:useCard{from=player,tos={enemy},card=Fk:getCardById(id),extraUse=true}
        check(enemy.hp==(mode=='effect' and 8 or 9),'Jilix HP '..slot..' '..mode)
        check(enemy[slot]==(mode=='effect' and 'ld__yanbaihu' or 'blank_shibing'),'Jilix slot '..slot..' '..mode)
        check(enemy:hasSkill('ld__jilix')==(mode=='effect'),'Jilix skill '..slot..' '..mode)
      end
    end
    fk.qInfo('[TQS_QA_SKILL_PARITY] SUMMARY PASS')
    room:gameOver('')
  end,
})
extension:loadSkillSkels({director})
return extension
