import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { LuaRuntime } from '../src/engine/luaRuntime';

const PACKAGE_FILE = /\.(lua|json|md|qml|js)$/iu;

function mountRuntimePackages(): Map<string, Uint8Array> {
  const packagesRoot = path.resolve(process.cwd(), '../../runtime/packages');
  const files = new Map<string, Uint8Array>();

  const visit = (directory: string, packageName: string) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      if (entry.name === '.git') continue;
      const absolute = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        visit(absolute, packageName);
      } else if (entry.isFile() && PACKAGE_FILE.test(entry.name)) {
        const relative = path.relative(packagesRoot, absolute).split(path.sep).join('/');
        files.set(`packages/${relative}`, fs.readFileSync(absolute));
      }
    }
  };

  for (const packageName of fs.readdirSync(packagesRoot)) {
    const absolute = path.join(packagesRoot, packageName);
    if (fs.statSync(absolute).isDirectory()) visit(absolute, packageName);
  }
  return files;
}

function setupScript(): string {
  return `
    FileIO.cd('packages/freekill-core')
    dofile('ltk/server/ai/init.lua')
    Request = dofile('lua/server/request.lua')
    FileIO.cd('../..')

    local tags = {}
    RoomInstance = {
      request_handlers = {},
      timeout = 1,
      getTag = function(_, key) return tags[key] end,
      setTag = function(_, key, value) tags[key] = value end,
      getPlayerById = function(_, id)
        if id == 17 or id == 18 then return { id = id } end
      end,
      checkNoHuman = function() end,
    }

    local target = {
      id = 18,
      getCardIds = function() return { 101, 102 } end,
    }
    local player = {
      id = 17,
      isFriend = function() return true end,
    }
    local ai = SmartAI:new(player)
    ai.room = RoomInstance

    local strategy = {
      makeReply = function(_, _) return 101 end,
    }
    ai.findStrategyOfSkill = function(_, _, skill_name)
      return skill_name == 'skill_x' and strategy or nil
    end

    -- The caller continues in the same Lua chunk so these locals remain in
    -- scope for each regression request below.
  `;
}

test('SmartAI response guard handles malformed prompts, invalid replies, and metrics', async () => {
  const logs: string[] = [];
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: {
      send() {},
      ui() {},
      setup() {},
      log: (level, message) => {
        if (level === 'warn' || level === 'error') logs.push(message);
      },
    },
  });

  await runtime.start();
  try {
    const result = runtime.eval<{
      valid: number | string;
      contextual_valid: number | string;
      valid_metric: { skill: string; reason: string; detail: string };
      rejected_active: string;
      rejected_metric: { skill: string; reason: string; detail: string };
      play_metric_reply: { card: number; targets: number[] };
      play_metric: { skill: string; reason: string; detail: string };
      malformed: string;
      invalid: string;
      choice: string;
      missing: string;
      missing_choice: string;
      exception: string;
      metrics: {
        total: number;
        processing_ms: number;
        fallback_reasons: Record<string, number>;
        by_command: Record<string, { total: number; fallback: number }>;
      };
      request_reply: string;
      request_reason: string;
      defense: { card: number; targets: number[] };
      response: { card: number; targets: number[] };
      defense_target_count: number;
      response_target_count: number;
      active: { card: { skill: string; subcards: number[] }; targets: number[] };
      play: { card: number; targets: number[] };
      invalid_target: string;
      trust_response: { card: number; targets: number[] };
      trust_malformed: string;
      multi_choices: string[];
      strategic_choice: string[];
      invalid_strategy_choice: string[];
      optional_choices: string[];
      ag_card: number;
      board_move: { cardId: number; pos: number };
      duplicate_choices: string;
      sparse_choices: string;
      illegal_cancel: string;
      allowed_cancel: string[];
      invalid_ag: string;
      invalid_board_move: string;
      disabled_cards: string;
      duplicate_cards: string;
      valid_cards: { cards: number[]; choice: string };
      filtered_cards: string;
      no_enabled_cards: string;
    }>(`${setupScript()}
      ai.command = 'AskForCardChosen'
      ai.data = { target, 'h', '#AskForChooseCard:18::skill_x' }
      local valid = ai:makeReply()

      -- The room adapter preserves skill_name separately so a valid custom
      -- display prompt does not have to be parsed as a strategy identifier.
      ai.command = 'AskForCardChosen'
      ai.data = { target, 'h', '#custom-card-prompt', 'skill_x' }
      local contextual_valid = ai:makeReply()

      ai.command = 'AskForCardChosen'
      ai.data = { target, 'h', '#AskForChooseCard:18' }
      local malformed = ai:makeReply()

      strategy.makeReply = function(_, _) return 999 end
      ai.command = 'AskForCardChosen'
      ai.data = { target, 'h', '#AskForChooseCard:18::skill_x' }
      local invalid = ai:makeReply()

      strategy.makeReply = function(_, _) return 'not-an-option' end
      ai.command = 'AskForChoice'
      ai.data = { {'ok', 'cancel'}, {'ok', 'cancel'}, 'skill_x', 'prompt' }
      local choice = ai:makeReply()

      ai.command = 'AskForSkillInvoke'
      ai.data = nil
      local missing = ai:makeReply()

      ai.command = 'AskForChoice'
      ai.data = nil
      local missing_choice = ai:makeReply()

      function ai:handleRegressionBoom()
        error('secret payload must not enter the AI log')
      end
      ai.command = 'RegressionBoom'
      ai.data = {}
      local exception = ai:makeReply()

      local request_player = {
        class = true,
        id = 17,
        room = RoomInstance,
        serverplayer = { getState = function() return -999 end },
        ai = {
          makeReply = function() error('request exception') end,
          recordExternalFallback = function(_, _, reason) RoomInstance:setTag('__request_reason', reason) end,
        },
      }
      local request = Request:new(request_player, 'AskForSkillInvoke')
      request.data[17] = { 'skill_x', 'prompt' }
      local request_reply = request:_checkReply(request_player, true)

      -- Exercise the four dashboard-shaped response families with a minimal
      -- handler whose feasible() method is authoritative.  The cards/targets
      -- are still checked by Base.AI and AI:validateReply before returning.
      local valid_skill_name = next(Fk.skills)
      local valid_card_id
      for id in pairs(Fk.cards) do
        if type(id) == 'number' then
          valid_card_id = id
          break
        end
      end
      if not valid_card_id then valid_card_id = 101 end
      local getCardById = Fk.getCardById
      Fk.getCardById = function(_, id)
        if id == valid_card_id then return { id = id } end
        return getCardById(Fk, id)
      end
      local FakeHandler = {}
      function FakeHandler:new(_, data)
        return {
          skill_name = type(data) == 'table' and data[1] or nil,
          reject = type(data) == 'table' and data[1] == 'reject_active',
          setup = function() end,
          isInstanceOf = function(_, class) return class == FakeHandler end,
          feasible = function(self) return not self.reject end,
        }
      end
      RoomInstance.request_handlers.AskForUseCard = FakeHandler
      RoomInstance.request_handlers.AskForResponseCard = FakeHandler
      RoomInstance.request_handlers.AskForUseActiveSkill = FakeHandler
      RoomInstance.request_handlers.PlayCard = FakeHandler
      ai.getEnabledCards = function() return { valid_card_id } end
      ai.selectCard = function() end
      ai.doOKButton = function() return { card = valid_card_id, targets = {} } end
      ai.currentSkill = function() return nil end
      ai.findStrategyOfSkill = function(_, _, skill_name)
        if skill_name == 'skill_x' then return strategy end
        if skill_name == 'fake_active' then
          return { makeReply = function() return {
            card = { skill = valid_skill_name, subcards = {} }, targets = { 18 },
          } end }
        end
        if skill_name == 'reject_active' then
          return { makeReply = function() return {
            card = { skill = valid_skill_name, subcards = {} }, targets = { 18 },
          } end }
        end
        if skill_name == 'play_metric_skill' then
          return {
            skill_name = skill_name,
            use_priority = 1,
            makeReply = function() return { card = valid_card_id, targets = { 18 } }, 1 end,
          }
        end
      end

      ai.command = 'AskForUseCard'
      ai.data = { nil, 'jink', 'prompt', true, {}, {} }
      local defense = ai:makeReply()
      ai.command = 'AskForResponseCard'
      ai.data = { nil, 'jink', 'prompt', true, {}, {} }
      local response = ai:makeReply()
      ai.command = 'AskForUseActiveSkill'
      ai.data = { 'fake_active', 'prompt', true, {} }
      local active = ai:makeReply()
      local valid_metric = {
        skill = ai._ai_last_metric_skill,
        reason = ai._ai_last_metric_reason,
        detail = ai._ai_last_metric_detail,
      }
      ai.command = 'AskForUseActiveSkill'
      ai.data = { 'reject_active', 'prompt', true, {} }
      local rejected_active = ai:makeReply()
      local rejected_metric = {
        skill = ai._ai_last_metric_skill,
        reason = ai._ai_last_metric_reason,
        detail = ai._ai_last_metric_detail,
      }
      local savedGetEnabledSkills = ai.getEnabledSkills
      local savedGetEnabledCards = ai.getEnabledCards
      local savedSelectSkill = ai.selectSkill
      local savedUnSelectAll = ai.unSelectAll
      ai.getEnabledSkills = function() return { 'play_metric_skill' } end
      ai.getEnabledCards = function() return {} end
      ai.selectSkill = function() end
      ai.unSelectAll = function() end
      ai.command = 'PlayCard'
      ai.data = nil
      local play_metric_reply = ai:makeReply()
      local play_metric = {
        skill = ai._ai_last_metric_skill,
        reason = ai._ai_last_metric_reason,
        detail = ai._ai_last_metric_detail,
      }
      ai.getEnabledSkills = savedGetEnabledSkills
      ai.getEnabledCards = savedGetEnabledCards
      ai.selectSkill = savedSelectSkill
      ai.unSelectAll = savedUnSelectAll
      ai.handlePlayCard = function() return { card = valid_card_id, targets = { 18 } } end
      ai.command = 'PlayCard'
      ai.data = nil
      local play = ai:makeReply()
      ai.handlePlayCard = function() return { card = valid_card_id, targets = { 999 } } end
      local invalid_target = ai:makeReply()

      -- Keep the simpler TrustAI path covered as well: opponent/possessed BOT
      -- responses share the base validator but do not use SmartAI strategies.
      local trust = TrustAI:new(player)
      trust.room = RoomInstance
      trust.getEnabledCards = function() return { valid_card_id } end
      trust.selectCard = function() end
      trust.doOKButton = function() return { card = valid_card_id, targets = {} } end
      trust.command = 'AskForResponseCard'
      trust.data = { nil, 'jink', 'prompt', true, {}, {} }
      local trust_response = trust:makeReply()
      trust.command = 'AskForUseCard'
      trust.data = { nil, 'nullification', nil }
      local trust_malformed = trust:makeReply()

      local function ask(command, data)
        ai.command, ai.data = command, data
        return ai:makeReply()
      end
      local choice_data = { {'left', 'right', 'third'}, {'left', 'right', 'third'},
        {2, 2}, false, '', '', false, false }
      local multi_choices = ask('AskForChoices', choice_data)
      strategy.makeReply = function() return 'right' end
      local single_data = { {'left', 'right'}, {'left', 'right'},
        {1, 1}, false, 'skill_x', '', false, true }
      local strategic_choice = ask('AskForChoices', single_data)
      strategy.makeReply = function() return 'out-of-request' end
      local invalid_strategy_choice = ask('AskForOptions', single_data)
      local optional_choices = ask('AskForChoices', {
        {'left'}, {'left'}, {0, 1}, true, '', '', false, false
      })

      ai.getCardValue = function(_, id) return id == 102 and 10 or 1 end
      local ag_card = ask('AskForAG', { {101, 102}, false, 'amazing_grace' })
      local board_data = {
        cards = {101, 102}, cardsPosition = {1, 0}, playerIds = {17, 18}
      }
      local board_move = ask('AskForMoveCardInBoard', board_data)

      ai.handleAskForChoices = function() return {'left', 'left'} end
      local duplicate_choices = ask('AskForChoices', choice_data)
      ai.handleAskForChoices = function() return {[1] = 'left', [3] = 'right'} end
      local sparse_choices = ask('AskForChoices', choice_data)
      ai.handleAskForChoices = nil

      ai.handleAskForOptions = function() return {'Cancel'} end
      local illegal_cancel = ask('AskForOptions', single_data)
      local allowed_cancel = ask('AskForOptions', {
        {'left'}, {'left'}, {1, 1}, true, '', '', true
      })
      ai.handleAskForOptions = nil

      ai.handleAskForAG = function() return 999 end
      local invalid_ag = ask('AskForAG', { {101, 102}, false, 'amazing_grace' })
      ai.handleAskForAG = nil
      ai.handleAskForMoveCardInBoard = function() return {cardId = 101, pos = 0} end
      local invalid_board_move = ask('AskForMoveCardInBoard', board_data)
      ai.handleAskForMoveCardInBoard = nil

      local cards_data = {
        cards = {101, 102}, disabled = {102}, choices = {'OK'},
        cancel_choices = {}, min = 1, max = 2,
      }
      ai.handleAskForCardsAndChoice = function()
        return {cards = {102}, choice = 'OK'}
      end
      local disabled_cards = ask('AskForCardsAndChoice', cards_data)
      ai.handleAskForCardsAndChoice = function()
        return {cards = {101, 101}, choice = 'OK'}
      end
      local duplicate_cards = ask('AskForCardsAndChoice', cards_data)
      ai.handleAskForCardsAndChoice = nil
      local valid_cards = ask('AskForCardsAndChoice', cards_data)
      cards_data.filter_skel = 'skill_specific_filter'
      local filtered_cards = ask('AskForCardsAndChoice', cards_data)
      cards_data.filter_skel = nil
      cards_data.disabled = {101, 102}
      local no_enabled_cards = ask('AskForCardsAndChoice', cards_data)

      local metrics = ai:getResponseMetrics()
      return {
        valid = valid,
        contextual_valid = contextual_valid,
        valid_metric = valid_metric,
        rejected_active = rejected_active,
        rejected_metric = rejected_metric,
        play_metric_reply = play_metric_reply,
        play_metric = play_metric,
        malformed = malformed,
        invalid = invalid,
        choice = choice,
        missing = missing,
        missing_choice = missing_choice,
        exception = exception,
        metrics = metrics,
        request_reply = request_reply,
        request_reason = RoomInstance:getTag('__request_reason'),
        defense = defense,
        response = response,
        defense_target_count = type(defense) == 'table' and #defense.targets or -1,
        response_target_count = type(response) == 'table' and #response.targets or -1,
        active = active,
        play = play,
        invalid_target = invalid_target,
        trust_response = trust_response,
        trust_malformed = trust_malformed,
        multi_choices = multi_choices,
        strategic_choice = strategic_choice,
        invalid_strategy_choice = invalid_strategy_choice,
        optional_choices = optional_choices,
        ag_card = ag_card,
        board_move = board_move,
        duplicate_choices = duplicate_choices,
        sparse_choices = sparse_choices,
        illegal_cancel = illegal_cancel,
        allowed_cancel = allowed_cancel,
        invalid_ag = invalid_ag,
        invalid_board_move = invalid_board_move,
        disabled_cards = disabled_cards,
        duplicate_cards = duplicate_cards,
        valid_cards = valid_cards,
        filtered_cards = filtered_cards,
        no_enabled_cards = no_enabled_cards,
      }
    `);

    assert.equal(result.valid, 101, 'canonical choose-card prompt should reach the strategy');
    assert.equal(result.valid_metric.reason, 'accepted');
    assert.equal(result.valid_metric.detail, 'none');
    assert.notEqual(result.valid_metric.skill, 'unknown');
    assert.equal(result.rejected_active, '__cancel');
    assert.equal(result.rejected_metric.skill, 'reject_active');
    assert.equal(result.rejected_metric.reason, 'illegal_reply');
    assert.equal(result.rejected_metric.detail, 'feasibility_rejected');
    assert.equal(result.contextual_valid, 101, 'custom display prompts must use preserved skill metadata');
    assert.equal(typeof result.play_metric_reply.card, 'number');
    assert.deepEqual(result.play_metric_reply.targets, [18]);
    assert.equal(result.play_metric.skill, 'play_metric_skill');
    assert.equal(result.play_metric.reason, 'accepted');
    assert.equal(result.play_metric.detail, 'none');
    assert.equal(result.malformed, '__cancel', 'short prompt must cancel safely');
    assert.equal(result.invalid, '__cancel', 'card id outside the request data must be rejected');
    assert.equal(result.choice, 'ok', 'invalid choice strategy reply must use a legal fallback');
    assert.equal(result.missing, '__cancel', 'missing request data must not throw');
    assert.equal(result.missing_choice, '__cancel', 'missing choice data must not throw');
    assert.equal(result.exception, '__cancel', 'handler exceptions must become a safe cancel');
    assert.equal(result.request_reply, '__cancel', 'Request must not retain an AI exception as nil');
    assert.equal(result.request_reason, 'ai_exception');
    assert.equal(result.defense.card, result.response.card);
    assert.equal(result.defense_target_count, 0, JSON.stringify(result));
    assert.equal(result.response_target_count, 0, JSON.stringify(result));
    assert.equal(result.active.targets[0], 18, JSON.stringify(result));
    assert.equal(result.play.targets[0], 18, JSON.stringify(result));
    assert.equal(result.invalid_target, '__cancel', 'target outside the room must be rejected');
    assert.equal(typeof result.active.card.skill, 'string');
    assert.equal(result.trust_response.card, result.defense.card);
    assert.equal(result.trust_malformed, '__cancel', 'TrustAI must cancel malformed nullification prompts');
    assert.deepEqual(result.multi_choices, ['left', 'right']);
    assert.deepEqual(result.strategic_choice, ['right']);
    assert.deepEqual(result.invalid_strategy_choice, ['left']);
    assert.deepEqual(result.optional_choices, []);
    assert.equal(result.ag_card, 102, 'AG should select the card with best available value');
    assert.deepEqual(result.board_move, { cardId: 101, pos: 1 });
    assert.equal(result.duplicate_choices, '__cancel', 'repeated selections must be rejected');
    assert.equal(result.sparse_choices, '__cancel', 'sparse choice arrays must be rejected');
    assert.equal(result.illegal_cancel, '__cancel', 'Cancel is invalid for noncancelable options');
    assert.deepEqual(result.allowed_cancel, ['Cancel'], 'cancelable options may use native Cancel');
    assert.equal(result.invalid_ag, '__cancel', 'AG card outside native list must be rejected');
    assert.equal(result.invalid_board_move, '__cancel', 'card position must match native index');
    assert.equal(result.disabled_cards, '__cancel', 'disabled card must be rejected');
    assert.equal(result.duplicate_cards, '__cancel', 'duplicate selected cards must be rejected');
    assert.deepEqual(result.valid_cards, { cards: [101], choice: 'OK' });
    assert.equal(result.filtered_cards, '__cancel', 'custom skill filters require a native-aware strategy');
    assert.equal(result.no_enabled_cards, '__cancel', 'no enabled cards must not produce a forged selection');
    assert.ok(result.metrics.total >= 6);
    assert.ok(result.metrics.processing_ms >= 0);
    assert.ok((result.metrics.fallback_reasons.malformed_prompt ?? 0) >= 1);
    assert.ok((result.metrics.fallback_reasons.invalid_reply ?? 0) >= 1);
    assert.ok((result.metrics.fallback_reasons.malformed_data ?? 0) >= 1);
    assert.ok((result.metrics.fallback_reasons.handler_error ?? 0) >= 1);
    assert.ok(result.metrics.by_command.AskForCardChosen.total >= 3);
    assert.ok(logs.some((message) => message.includes(
      'fallback command=AskForCardChosen reason=malformed_prompt')),
    'malformed prompt fallbacks must retain a bounded reason in telemetry');
    assert.ok(logs.every((message) => !message.includes('secret payload')),
      'AI logs must not contain raw exception/request data');
  } finally {
    runtime.close();
  }
});

test('generic active chooser rejects empty cancelable replies and replays card-dependent targets', async () => {
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: { send() {}, ui() {}, setup() {}, log() {} },
  });

  await runtime.start();
  try {
    const result = runtime.eval<{
      cancelableEmpty: boolean;
      cardDependentCards: number[];
      cardDependentTargets: number[];
    }>(String.raw`
      FileIO.cd('packages/freekill-core')
      dofile('ltk/server/ai/init.lua')
      FileIO.cd('../..')

      local active = Fk.skills.choose_players_skill:getSkeleton().ai_strategies[
        Fk.Ltk.AI.ActiveStrategy][1]
      local chooser = Fk.skills.choose_players_skill:getSkeleton().ai_strategies[
        Fk.Ltk.AI.ChoosePlayersStrategy][1]
      local enemy = { id = 2 }

      local function fake(data, cards)
        local selected_cards, selected_targets = {}, {}
        local ai = { data = data }
        function ai:findStrategyOfSkill(_, name)
          return name == 'choose_players_skill' and chooser or nil
        end
        function ai:getEnabledCards()
          local ret = {}
          for _, id in ipairs(cards) do
            local selected = false
            for _, chosen in ipairs(selected_cards) do
              if chosen == id then selected = true break end
            end
            if not selected then table.insert(ret, id) end
          end
          return ret
        end
        function ai:selectCard(id, selected)
          if selected then table.insert(selected_cards, id) end
        end
        function ai:getEnabledTargets()
          if data[4].pattern ~= '' and #selected_cards == 0 then return {} end
          if #selected_targets > 0 then return {} end
          return { enemy }
        end
        function ai:selectTarget(target, selected)
          if selected then table.insert(selected_targets, target.id) end
        end
        function ai:okButtonEnabled()
          local min_cards = data[4].pattern ~= '' and 1 or 0
          return #selected_cards >= min_cards and #selected_targets >= data[4].min_num
        end
        function ai:unSelectAll()
          selected_cards, selected_targets = {}, {}
        end
        return ai
      end

      local cancelable = active:think(fake({
        'choose_players_skill', '', true,
        { targets = { 2 }, num = 1, min_num = 1, pattern = '', skillName = 'qa_missing' }
      }, {}))

      local cardDependent = active:think(fake({
        'choose_players_skill', '', false,
        { targets = { 2 }, num = 1, min_num = 1, pattern = '.', skillName = 'qa_missing' }
      }, { 101 }))

      return {
        cancelableEmpty = cancelable == nil,
        cardDependentCards = cardDependent and cardDependent[1] or {},
        cardDependentTargets = cardDependent and table.map(cardDependent[2] or {}, Util.IdMapper) or {},
      }
    `);

    assert.equal(result.cancelableEmpty, true,
      'cancelable requests must not serialize an infeasible empty target selection');
    assert.deepEqual(result.cardDependentCards, [101]);
    assert.deepEqual(result.cardDependentTargets, [2],
      'target selection must run after the card-dependent filter is replayed');
  } finally {
    runtime.close();
  }
});

test('generic card choosers reject infeasible empty replies before serialization', async () => {
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: { send() {}, ui() {}, setup() {}, log() {} },
  });

  await runtime.start();
  try {
    const result = runtime.eval<{
      cardsCancelableEmpty: boolean;
      cardsValid: number[];
      combinedCancelableEmpty: boolean;
      combinedValidCards: number[];
      combinedValidTargets: number[];
    }>(String.raw`
      FileIO.cd('packages/freekill-core')
      dofile('ltk/server/ai/init.lua')
      FileIO.cd('../..')

      local cardsActive = Fk.skills.choose_cards_skill:getSkeleton().ai_strategies[
        Fk.Ltk.AI.ActiveStrategy][1]
      local cardsChooser = Fk.skills.choose_cards_skill:getSkeleton().ai_strategies[
        Fk.Ltk.AI.CardsStrategy][1]
      local combinedActive = Fk.skills['ex__choose_skill']:getSkeleton().ai_strategies[
        Fk.Ltk.AI.ActiveStrategy][1]
      local combinedChooser = Fk.skills['ex__choose_skill']:getSkeleton().ai_strategies[
        Fk.Ltk.AI.ChooseCardsAndPlayersStrategy][1]
      local enemy = { id = 2 }

      local function fake(data, mode)
        local selected_cards, selected_targets = {}, {}
        local ai = { data = data }
        function ai:findStrategyOfSkill(kind, name)
          if mode == 'cards' and kind == Fk.Ltk.AI.CardsStrategy and
              name == 'choose_cards_skill' then return cardsChooser end
          if mode == 'combined' and kind == Fk.Ltk.AI.ChooseCardsAndPlayersStrategy and
              name == 'ex__choose_skill' then return combinedChooser end
        end
        function ai:getEnabledCards()
          local ret = {}
          for _, id in ipairs({ 101, 102 }) do
            local selected = false
            for _, chosen in ipairs(selected_cards) do
              if chosen == id then selected = true break end
            end
            if not selected then table.insert(ret, id) end
          end
          return ret
        end
        function ai:getEnabledTargets()
          if #selected_targets > 0 then return {} end
          return { enemy }
        end
        function ai:selectCard(id, selected)
          if selected then table.insert(selected_cards, id) end
        end
        function ai:selectTarget(target, selected)
          if selected then table.insert(selected_targets, target.id) end
        end
        function ai:okButtonEnabled()
          local min_cards = data[4].min_num or data[4].min_c_num or 0
          local min_targets = data[4].min_t_num or 0
          return #selected_cards >= min_cards and #selected_targets >= min_targets
        end
        function ai:unSelectAll()
          selected_cards, selected_targets = {}, {}
        end
        return ai
      end

      local cardsEmpty = cardsActive:think(fake({
        'choose_cards_skill', '', true,
        { skillName = 'qa_missing', min_num = 1, num = 1, pattern = '' }
      }, 'cards'))
      local cardsValid = cardsActive:think(fake({
        'choose_cards_skill', '', false,
        { skillName = 'qa_missing', min_num = 1, num = 1, pattern = '' }
      }, 'cards'))

      local combinedEmpty = combinedActive:think(fake({
        'ex__choose_skill', '', true,
        { skillName = 'qa_missing', min_c_num = 1, max_c_num = 1,
          min_t_num = 1, max_t_num = 1, equal = false }
      }, 'combined'))
      local combinedValid = combinedActive:think(fake({
        'ex__choose_skill', '', false,
        { skillName = 'qa_missing', min_c_num = 1, max_c_num = 1,
          min_t_num = 1, max_t_num = 1, equal = false }
      }, 'combined'))

      return {
        cardsCancelableEmpty = cardsEmpty == nil,
        cardsValid = cardsValid and cardsValid[1] or {},
        combinedCancelableEmpty = combinedEmpty == nil,
        combinedValidCards = combinedValid and combinedValid[1] or {},
        combinedValidTargets = combinedValid and
          table.map(combinedValid[2] or {}, Util.IdMapper) or {},
      }
    `);

    assert.equal(result.cardsCancelableEmpty, true,
      'cancelable card prompts must not serialize an infeasible empty selection');
    assert.equal(result.cardsValid.length, 1);
    assert.ok([101, 102].includes(result.cardsValid[0]));
    assert.equal(result.combinedCancelableEmpty, true,
      'cancelable combined prompts must not serialize an infeasible empty selection');
    assert.equal(result.combinedValidCards.length, 1);
    assert.ok([101, 102].includes(result.combinedValidCards[0]));
    assert.deepEqual(result.combinedValidTargets, [2]);
  } finally {
    runtime.close();
  }
});

test('discard active strategy replays cards through live feasibility before serialization', async () => {
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: { send() {}, ui() {}, setup() {}, log() {} },
  });

  await runtime.start();
  try {
    const result = runtime.eval<{
      validCards: number[];
      validSelectedAfterReplay: number;
      rejected: boolean;
      rejectedSelectedAfterReplay: number;
      stale: boolean;
      staleSelectedAfterReplay: number;
    }>(String.raw`
      FileIO.cd('packages/freekill-core')
      dofile('ltk/server/ai/init.lua')
      FileIO.cd('../..')

      local active = Fk.skills.discard_skill:getSkeleton().ai_strategies[Fk.Ltk.AI.ActiveStrategy][1]
      local selected, strategyCards, feasible = {}, {101, 102}, true
      local strategy = {
        chooseCards = function() return strategyCards, 3 end,
      }

      local function fake()
        local ai = {
          data = {'discard_skill', '', false, {skillName = 'discard_skill', num = 2, min_num = 2}},
        }
        function ai:findStrategyOfSkill(kind, name)
          if kind == Fk.Ltk.AI.DiscardStrategy and name == 'discard_skill' then
            return strategy
          end
        end
        function ai:getEnabledCards()
          return {101, 102}
        end
        function ai:selectCard(id, enabled)
          if enabled then table.insert(selected, id) end
        end
        function ai:okButtonEnabled()
          return feasible
        end
        function ai:unSelectAll()
          selected = {}
        end
        return ai
      end

      local valid = active:think(fake())
      local validCards = valid and valid[1] or {}
      local validSelectedAfterReplay = #selected

      feasible = false
      local rejected = active:think(fake()) == nil
      local rejectedSelectedAfterReplay = #selected

      strategyCards = {999}
      feasible = true
      local stale = active:think(fake()) == nil
      local staleSelectedAfterReplay = #selected

      return {
        validCards = validCards,
        validSelectedAfterReplay = validSelectedAfterReplay,
        rejected = rejected,
        rejectedSelectedAfterReplay = rejectedSelectedAfterReplay,
        stale = stale,
        staleSelectedAfterReplay = staleSelectedAfterReplay,
      }
    `);

    assert.deepEqual(result.validCards, [101, 102]);
    assert.equal(result.validSelectedAfterReplay, 0,
      'live selection must be cleared after a feasible discard reply');
    assert.equal(result.rejected, true,
      'an infeasible discard selection must not be serialized');
    assert.equal(result.rejectedSelectedAfterReplay, 0,
      'live selection must be cleared after a rejected discard reply');
    assert.equal(result.stale, true,
      'a strategy card outside the live enabled set must not be serialized');
    assert.equal(result.staleSelectedAfterReplay, 0,
      'stale-card rejection must clear any partial live selection');
  } finally {
    runtime.close();
  }
});

test('PlayCard treats a strategy nil result as no decision, not an invalid reply', async () => {
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: { send() {}, ui() {}, setup() {}, log() {} },
  });

  await runtime.start();
  try {
    const result = runtime.eval<{ replyIsNil: boolean; fallback?: string }>(String.raw`
      FileIO.cd('packages/freekill-core')
      dofile('ltk/server/ai/init.lua')
      FileIO.cd('../..')

      local bot = SmartAI:new({ id = 17 })
      bot.handler = {}
      bot.getEnabledSkills = function() return {'qa_nil_strategy'} end
      bot.getEnabledCards = function() return {} end
      bot.findStrategyOfSkill = function(_, kind, name)
        if kind == Fk.Ltk.AI.ActiveStrategy and name == 'qa_nil_strategy' then
          return {
            skill_name = name,
            use_priority = 1,
            makeReply = function() return nil, 0 end,
          }
        end
      end
      bot.selectSkill = function() end
      bot.unSelectAll = function() end

      local reply = bot:handlePlayCard()
      return { replyIsNil = reply == nil, fallback = bot._ai_fallback_reason }
    `);

    assert.equal(result.replyIsNil, true);
    assert.equal(result.fallback, undefined,
      'a nil strategy result must flow to Base.AI no_decision handling');
  } finally {
    runtime.close();
  }
});

test('hegemony SmartAI keeps hidden seats uncertain, updates from public actions, and ignores private data', async () => {
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: { send() {}, ui() {}, setup() {}, log() {} },
  });
  await runtime.start();
  try {
    const result = runtime.eval<{
      confirmed: { ally: boolean; enemy: boolean; overturned: boolean };
      initial: { state: string; confidence: number; attitude: number; enemy: boolean; friend: boolean };
      attacked: { state: string; attitude: number; confidence: number; wei: number; protection: boolean };
      helped: { state: string; attitude: number; confidence: number; wei: number; protection: boolean };
      revealed: { friend: boolean; enemy: boolean; confidence: number };
      secretA: { attitude: number; probabilities: Record<string, number> };
      secretB: { attitude: number; probabilities: Record<string, number> };
      damage: { before: number; after: number; confirmed: number; legacy: number };
      oldPolicy: number;
      unobserved: number;
      resumed: number;
      reversal: number;
      privateHandCount: number;
      possibleKingdoms: string[];
      unknownAfterReversal: boolean;
      secretDecisionsEqual: boolean;
      privateMoveEstimated: boolean;
      wildGroupEvidence: number;
      otherMode: boolean;
    }>(`
      FileIO.cd('packages/freekill-core')
      dofile('ltk/server/ai/init.lua')
      FileIO.cd('../..')
      math.randomseed(24680)

      local room = { players = {}, logic = { event_recorder = {} } }
      function room:getSettings(key) return key == 'gameMode' and 'new_heg_mode' end
      function room:getBanner(key)
        if key == 'all_kingdoms' then return { 'wei', 'shu', 'wu', 'qun' } end
      end
      function room:getPlayerById(id)
        for _, p in ipairs(self.players) do if p.id == id then return p end end
      end
      local selfSeat = { id = 1, kingdom = 'unknown', hp = 3, maxHp = 4, shield = 0 }
      function selfSeat:getMark(key)
        assert(key == '__heg_kingdom', 'unexpected private mark access')
        return 'wei'
      end
      function selfSeat:isFriend(target)
        return target.id == self.id or (target.kingdom == 'wei' and not target.gouni)
      end
      local ally = { id = 2, kingdom = 'wei', hp = 3, maxHp = 4, shield = 0 }
      local enemy = { id = 3, kingdom = 'shu', hp = 3, maxHp = 4, shield = 0 }
      local hidden = { id = 4, kingdom = 'unknown', hp = 3, maxHp = 4, shield = 0 }
      local hidden2 = { id = 5, kingdom = 'unknown', hp = 3, maxHp = 4, shield = 0 }
      function hidden:getMark() error('opponent hidden mark accessed') end
      function hidden2:getMark() error('opponent hidden mark accessed') end
      function hidden:getCardIds(area)
        if area == 'h' then error('opponent private hand IDs accessed') end
        return {}
      end
      function hidden:getHandcardNum() return 3 end
      -- Deliberately supply different hidden secrets behind identical public states.
      hidden.privateGeneral, hidden.privateHand = 'secret_wei', { 999 }
      hidden2.privateGeneral, hidden2.privateHand = 'secret_shu', { 1, 2, 3 }
      room.players = { selfSeat, ally, enemy, hidden, hidden2 }

      local bot = SmartAI:new(selfSeat)
      bot.room = room
      local confirmed = { ally = bot:isFriend(ally), enemy = bot:isEnemy(enemy) }
      ally.gouni = true
      confirmed.overturned = bot:isEnemy(ally)
      ally.gouni = nil

      local initialRelation = bot:getFactionRelation(hidden)
      local oldPolicy = selfSeat:isFriend(hidden) and 1 or -1
      local initial = { state = initialRelation.state, confidence = initialRelation.confidence,
        attitude = initialRelation.attitude, enemy = bot:isEnemy(hidden), friend = bot:isFriend(hidden) }
      local possibleKingdoms = {}
      for kingdom in pairs(initialRelation.probabilities) do table.insert(possibleKingdoms, kingdom) end
      table.sort(possibleKingdoms)

      local Logic = require('ltk.server.ai.logic')
      local calculation = Logic:new(bot)
      calculation:setPlayerProperty(hidden, 'hp', 2)
      local damageBefore = calculation.benefit

      local events = {}
      room.logic.event_recorder[GameEvent.UseCard] = events
      local function observe(actor, target, card, status, flags)
        local data = { from = actor, tos = { target }, card = { trueName = card }, noIndicate = flags }
        table.insert(events, { status = status or 'dead', data = data })
      end
      for i = 1, 3 do observe(hidden, ally, 'slash') end
      local attackRelation = bot:getFactionRelation(hidden)
      local attacked = { state = attackRelation.state, attitude = attackRelation.attitude,
        confidence = attackRelation.confidence, wei = attackRelation.probabilities.wei,
        protection = bot:shouldProtect(hidden) }
      calculation.benefit = 0
      calculation:setPlayerProperty(hidden, 'hp', 2)
      local damageAfter = calculation.benefit
      local privateHandCount = bot:needHelp(hidden, 'h')

      -- A separate seat observes four public Peach uses on a revealed Wei seat.
      local helper = { id = 6, kingdom = 'unknown' }
      function helper:getMark() error('helper hidden mark accessed') end
      table.insert(room.players, helper)
      for i = 1, 4 do observe(helper, ally, 'peach') end
      local helpRelation = bot:getFactionRelation(helper)
      local helped = { state = helpRelation.state, attitude = helpRelation.attitude,
        confidence = helpRelation.confidence, wei = helpRelation.probabilities.wei,
        protection = bot:shouldProtect(helper) }

      -- Wild players may have different independent founded kingdoms. Public
      -- aid to one wild seat does not prove membership in a shared wild camp.
      local wild = { id = 7, kingdom = 'wild' }
      table.insert(room.players, wild)
      observe(hidden2, wild, 'peach')
      observe(hidden2, wild, 'peach')
      local wildGroupEvidence = bot:getFactionRelation(hidden2).evidence

      -- A private change is inert. Even a new AI seat with the same public
      -- observation history must make the same seeded choice/estimate.
      local secretA = bot:getFactionRelation(hidden2)
      calculation.benefit = 0
      calculation:setPlayerProperty(hidden2, 'hp', 2)
      local secretDecisionBefore = calculation.benefit
      hidden2.privateGeneral, hidden2.privateHand = 'another_kingdom', { 5, 6, 7, 8 }
      local secretB = bot:getFactionRelation(hidden2)
      local privateA = { attitude = secretA.attitude, probabilities = secretA.probabilities }
      local privateB = { attitude = secretB.attitude, probabilities = secretB.probabilities }

      -- A private mutation must not influence a fixed simulated tactical action.
      calculation.benefit = 0
      calculation:setPlayerProperty(hidden2, 'hp', 2)
      local secretDecisionAfter = calculation.benefit
      local secretDecisionsEqual = secretDecisionBefore == secretDecisionAfter

      -- Scoring a card transfer from another hand must not resolve that
      -- private card's identity (even when the server simulation has its ID).
      local originalGetCardValue = bot.getCardValue
      bot.getCardValue = function(_, id)
        assert(id ~= 999, 'simulator read a secret opponent hand card')
        return 2
      end
      calculation.benefit = 0
      calculation:applyMoveInfo({ from = hidden }, { fromArea = Player.Hand, cardId = 999 })
      local privateMoveEstimated = calculation.benefit ~= 0
      bot.getCardValue = originalGetCardValue

      -- Ignore events whose effects have not yet been publicly announced.
      observe(hidden2, ally, 'peach', 'running')
      local unobserved = bot:getFactionRelation(hidden2).attitude
      events[#events].status = 'dead'
      events[#events].data.noIndicate = true
      assert(bot:getFactionRelation(hidden2).attitude == unobserved)
      observe(hidden2, ally, 'peach')
      local resumed = bot:getFactionRelation(hidden2).attitude

      -- Later public help may overturn an earlier suspicion without ever
      -- upgrading a still-hidden player's state to confirmed ally.
      for i = 1, 6 do observe(hidden, ally, 'peach') end
      local reversedRelation = bot:getFactionRelation(hidden)
      local reversal = reversedRelation.attitude
      local unknownAfterReversal = reversedRelation.state == 'unknown'

      hidden.kingdom = 'wei' -- Newly revealed during the match.
      local revealedRelation = bot:getFactionRelation(hidden)
      local revealed = { friend = bot:isFriend(hidden), enemy = bot:isEnemy(hidden),
        confidence = revealedRelation.confidence }
      calculation.benefit = 0
      calculation:setPlayerProperty(hidden, 'hp', 2)
      local damageConfirmed = calculation.benefit
      room.getSettings = function() return 'aaa_role_mode' end
      local otherMode = bot:isEnemy(hidden2)

      return {
        confirmed = confirmed, initial = initial, attacked = attacked, helped = helped,
        revealed = revealed, secretA = privateA, secretB = privateB,
        damage = { before = damageBefore, after = damageAfter,
          confirmed = damageConfirmed, legacy = oldPolicy * -200 },
        oldPolicy = oldPolicy, unobserved = unobserved, resumed = resumed,
        reversal = reversal, privateHandCount = privateHandCount,
        possibleKingdoms = possibleKingdoms, otherMode = otherMode,
        unknownAfterReversal = unknownAfterReversal,
        secretDecisionsEqual = secretDecisionsEqual,
        privateMoveEstimated = privateMoveEstimated,
        wildGroupEvidence = wildGroupEvidence,
      }
    `);

    assert.deepEqual(result.confirmed, { ally: true, enemy: true, overturned: true });
    assert.deepEqual(result.initial,
      { state: 'unknown', confidence: 0, attitude: 0, enemy: false, friend: false });
    assert.equal(result.oldPolicy, -1, 'previous binary classification on the same seed');
    assert.deepEqual(result.possibleKingdoms, ['other', 'qun', 'shu', 'wei', 'wu'],
      'never eliminate publicly available but unrevealed kingdoms');
    assert.equal(result.attacked.state, 'unknown');
    assert.ok(result.attacked.attitude < 0 && result.attacked.attitude > -1);
    assert.ok(result.attacked.confidence > 0 && result.attacked.confidence < 1);
    assert.ok(result.attacked.wei < 1 / 5);
    assert.equal(result.attacked.protection, false);
    assert.equal(result.helped.state, 'unknown');
    assert.ok(result.helped.attitude > 0);
    assert.ok(result.helped.wei > 0.78);
    assert.equal(result.helped.protection, true);
    assert.deepEqual(result.secretA, result.secretB, 'secret-only mutation must not change result');
    assert.equal(result.unobserved, 0);
    assert.ok(result.resumed > 0, 'later completed public event is observed once');
    assert.ok(result.reversal > 0, 'later public assistance reverses earlier suspicion');
    assert.equal(result.unknownAfterReversal, true);
    assert.equal(result.wildGroupEvidence, 0,
      'aid to an independent wild seat is not proof of a common wild faction');
    assert.ok(result.privateHandCount < 0, 'hand value uses only the public count');
    assert.equal(result.secretDecisionsEqual, true,
      'same seeded tactical calculation must ignore private-only mutations');
    assert.equal(result.privateMoveEstimated, true,
      'unknown opponent card transfer is estimated without resolving its private card');
    assert.deepEqual(result.revealed, { friend: true, enemy: false, confidence: 1 });
    assert.equal(result.damage.before, -25, 'unobserved opponent carries an attack risk');
    assert.ok(result.damage.after > 0, 'attacking a suspected enemy becomes beneficial');
    assert.equal(result.damage.confirmed, -200, 'confirmed ally damage retains exact value');
    assert.equal(result.damage.legacy, 200, 'legacy binary policy favors attacking every hidden seat');
    assert.equal(result.otherMode, true, 'legacy behavior outside new_heg_mode');
  } finally {
    runtime.close();
  }
});

test('illegal_reply reports bounded validator causes with identical dashboard controls across modes', async () => {
  const logs: string[] = [];
  const runtime = new LuaRuntime({
    files: mountRuntimePackages(),
    callbacks: {
      send() {}, ui() {}, setup() {},
      log: (level, message) => {
        if (level === 'warn' || level === 'error') logs.push(message);
      },
    },
  });
  await runtime.start();
  try {
    const result = runtime.eval<Array<{
      mode: string;
      replies: string[];
      total: number;
      fallback: number;
      details: Record<string, number>;
    }>>(`
      FileIO.cd('packages/freekill-core')
      dofile('ltk/server/ai/init.lua')
      FileIO.cd('../..')
      local savedGetCardById = Fk.getCardById
      local skill = next(Fk.skills)
      assert(skill ~= nil)
      local results = {}
      for _, gameMode in ipairs({ 'new_heg_mode', 'aaa_role_mode' }) do
        math.randomseed(24680)
        local tags = {}
        local behavior = 'accept'
        local lookupCount = 0
        local dynamicLookup = false
        Fk.getCardById = function(_, id)
          if id == 765432 then
            lookupCount = lookupCount + 1
            return (not dynamicLookup or lookupCount == 1) and { id = id } or nil
          end
          return savedGetCardById(Fk, id)
        end
        local handlerClass = {}
        function handlerClass:new()
          return {
            setup = function() end,
            feasible = function()
              if behavior == 'reject' then return false end
              if behavior == 'throw' then error('private validator fixture text') end
              return true
            end,
          }
        end
        RoomInstance = {
          request_handlers = { AskForUseActiveSkill = handlerClass },
          getSettings = function() return gameMode end,
          getTag = function(_, key) return tags[key] end,
          setTag = function(_, key, val) tags[key] = val end,
        }
        local ai = SmartAI:new({ id = 1 })
        ai.room = RoomInstance
        local response = { card = { skill = skill, subcards = {} }, targets = {} }
        function ai:handleAskForUseActiveSkill() return response end
        local function run()
          ai.command = 'AskForUseActiveSkill'
          ai.data = { 'diagnostic_skill', 'redacted', true, {} }
          return ai:makeReply()
        end
        local replies = {}
        replies[1] = type(run())
        behavior = 'reject'
        replies[2] = run()
        behavior = 'throw'
        replies[3] = run()
        behavior = 'accept'
        response = { card = { skill = skill, subcards = {} },
          targets = {}, special_skill = 'definitely_missing_skill' }
        replies[4] = run()
        RoomInstance.request_handlers.AskForUseActiveSkill = nil
        response = { card = { skill = skill, subcards = {} }, targets = {} }
        replies[5] = run()
        RoomInstance.request_handlers.AskForUseActiveSkill = handlerClass
        dynamicLookup, lookupCount = true, 0
        response = { card = 765432, targets = {} }
        replies[6] = run()
        dynamicLookup = false
        response = { card = { skill = skill, subcards = {} }, targets = {} }
        local originalValidator = ai.validateReply
        ai.validateReply = function() return false, 'illegal_reply' end
        replies[7] = run()
        ai.validateReply = originalValidator
        local metrics = ai:getResponseMetrics()
        results[#results + 1] = {
          mode = gameMode, replies = replies,
          total = metrics.by_command.AskForUseActiveSkill.total,
          fallback = metrics.by_command.AskForUseActiveSkill.fallback,
          details = metrics.by_command.AskForUseActiveSkill.invalid_details,
        }
      end
      Fk.getCardById = savedGetCardById
      return results
    `);

    const details = {
      feasibility_rejected: 1,
      feasibility_exception: 1,
      special_skill_missing: 1,
      missing_handler: 1,
      card_lookup_failed: 1,
      unclassified: 1,
    };
    for (const run of result) {
      assert.equal(run.total, 7);
      assert.equal(run.fallback, 6);
      assert.deepEqual(run.replies,
        ['table', '__cancel', '__cancel', '__cancel', '__cancel', '__cancel', '__cancel']);
      assert.deepEqual(run.details, details);
    }
    assert.deepEqual(result[0]?.replies, result[1]?.replies,
      'identical reply/handler fixtures must have identical legality outcomes in both modes');
    assert.ok(logs.some((message) => message.includes(
      'fallback command=AskForUseActiveSkill reason=illegal_reply detail=feasibility_rejected')),
    'validator rejection must remain distinguishable from an unclassified fallback');
    assert.ok(logs.every((message) => !message.includes('private validator fixture text') &&
      !message.includes('redacted') && !message.includes('765432')),
    'metadata-only illegal_reply logs must not reveal request fields or exception content');
  } finally {
    runtime.close();
  }
});
