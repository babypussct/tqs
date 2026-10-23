local tianyi = fk.CreateSkill({
  name = "tianyi",
})

Fk:loadTranslationTable{
  ["tianyi"] = "天义",
  [":tianyi"] = "出牌阶段限一次，你可以与一名角色拼点：若你赢，在本回合结束之前，你可以多使用一张【杀】、使用【杀】无距离限制且可以多选择一个目标；"..
  "若你没赢，本回合你不能使用【杀】。",

  ["#tianyi"] = "天义：与一名角色拼点，若赢，你使用【杀】获得增益，若没赢，本回合你不能使用【杀】",

  ["$tianyi1"] = "请助我一臂之力！",
  ["$tianyi2"] = "我当要替天行道！",
}

tianyi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#tianyi",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(tianyi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, tianyi.name)
    if player.dead then return end
    if pindian.results[target].winner == player then
      room:addPlayerMark(player, "tianyi_win-turn", 1)
    else
      room:addPlayerMark(player, "tianyi_lose-turn", 1)
    end
  end,
})
tianyi:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("tianyi_win-turn") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
  bypass_distances =  function(self, player, skill)
    return skill.trueName == "slash_skill" and player:getMark("tianyi_win-turn") > 0
  end,
  extra_target_func = function(self, player, skill)
    if skill.trueName == "slash_skill" and player:getMark("tianyi_win-turn") > 0 then
      return 1
    end
  end,
})

tianyi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("tianyi_lose-turn") > 0 and card.trueName == "slash"
  end,
})

-- 天义 is a risk decision, not a blind target-first action. Estimate the
-- opponent's pindian range from public hand size and use the BOT's highest
-- private card only as its own legal evidence. The actual pindian remains
-- entirely server-controlled.
tianyi:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local player = ai.player
    local own_high = 0
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card and type(card.number) == "number" then
        own_high = math.max(own_high, card.number)
      end
    end
    if own_high < 7 then return end

    local has_slash = table.find(player:getCardIds("h"), function(id)
      local card = Fk:getCardById(id)
      return card and card.trueName == "slash"
    end) ~= nil
    local win_reward = has_slash and 140 or 70
    local loss_cost = has_slash and 150 or 25
    local best_target, best_benefit = nil, -100000

    for _, target in ipairs(ai:getEnabledTargets()) do
      local relation = ai:getFactionRelation(target)
      local targetable = relation.state == "enemy" or
        (relation.state == "unknown" and relation.confidence >= 0.65 and relation.attitude < -0.25)
      local hand_num = type(target.getHandcardNum) == "function" and target:getHandcardNum() or 0
      if targetable and hand_num > 0 then
        local expected_target = 6 + math.min(3, math.max(0, hand_num - 2) * 0.5)
        local win_probability = math.max(0.10, math.min(0.90,
          0.50 + (own_high - expected_target) * 0.07))
        local low_hand_bonus = math.max(0, 4 - hand_num) * 8
        local benefit = win_probability * win_reward - (1 - win_probability) * loss_cost + low_hand_bonus
        if benefit > best_benefit then
          best_target, best_benefit = target, benefit
        end
      end
    end

    if best_target and best_benefit > 0 then
      return { {}, { best_target } }, best_benefit
    end
  end,
})

tianyi:addTest(function(room, me)
  local comp2, comp3, comp4 = room.players[2], room.players[3], room.players[4]
  local slashK = room:printCard("slash", Card.Diamond, 13)
  local jinkA = room:printCard("jink", Card.Club, 1)
  local peachA = room:printCard("peach", Card.Spade, 1)
  local analepticK = room:printCard("analeptic", Card.Heart, 13)
  local slash = Fk:getCardById(1)
  local slash2 = Fk:getCardById(2)

  -- test1: 第一个出牌阶段内：对comp2发动天义，用A拼K，暂停发现不能出杀
  FkTest.setNextReplies(me, {
    json.encode { card = { skill = tianyi.name, }, targets = { comp2.id } },
    json.encode { card = { subcards = { jinkA.id }, } }
  })
  FkTest.setNextReplies(comp2, {
    json.encode { card = { subcards = { analepticK.id }, } }
  })
  -- 用了点辣鸡手段 让他在第二次询问PlayCard时切出
  local function createTwiceClosure()
    local i = 0
    return function()
      i = i + 1
      return i == 2
    end
  end
  FkTest.setRoomBreakpoint(me, "PlayCard", createTwiceClosure())
  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, tianyi.name)
    room:obtainCard(me, { slashK.id, jinkA.id, slash.id, slash2.id })
    room:obtainCard(comp2, { peachA.id, analepticK.id })
    me:gainAnExtraTurn(false, "", {
      who = me, reason = "", phase_table = { Player.Play }})
  end)

  -- 应该不能点杀，也不能点天义按钮
  local handler = ClientInstance.current_request_handler --[[@as ReqPlayCard]]
  lu.assertIsFalse(handler:cardValidity(slash.id))
  lu.assertIsFalse(handler:skillButtonValidity(tianyi.name))

  -- 结束出牌阶段，让房间恢复正常
  FkTest.resumeRoom()

  -- test2: 用K拼A，再中断一次检查tmd技能生效情况
  FkTest.setNextReplies(me, {
    json.encode { card = { skill = tianyi.name, }, targets = { comp2.id } },
    json.encode { card = { subcards = { slashK.id }, } }
  })
  FkTest.setNextReplies(comp2, {
    json.encode { card = { subcards = { peachA.id }, } }
  })
  FkTest.setRoomBreakpoint(me, "PlayCard", createTwiceClosure())
  FkTest.runInRoom(function()
    me:gainAnExtraTurn(false, "", {
      who = me, reason = "", phase_table = { Player.Play }})
  end)
  local handler2 = ClientInstance.current_request_handler --[[@as ReqPlayCard]]
  lu.assertIsTrue(handler2:cardValidity(slash.id))
  handler2:selectCard(slash.id, { selected = true })
  -- 无距离限制：可杀到所有人
  for _, p in ipairs(room:getOtherPlayers(me)) do
    lu.assertIsTrue(handler2:targetValidity(p.id))
  end
  -- 喵分叉：可多杀一个
  handler2:selectTarget(comp2.id, { selected = true })
  lu.assertIsTrue(handler2:targetValidity(comp3.id))
  handler2:selectTarget(comp3.id, { selected = true })
  lu.assertNotIsTrue(handler2:targetValidity(comp4.id))

  FkTest.setNextReplies(me, {
    json.encode{ card = slash.id, targets = { comp2.id, comp3.id }}
  })
  FkTest.setRoomBreakpoint(me, "PlayCard")
  FkTest.resumeRoom()
  -- 双刀：本阶段还可再使用杀
  local handler3 = ClientInstance.current_request_handler --[[@as ReqPlayCard]]
  lu.assertIsTrue(handler3:cardValidity(slash2.id))
end)

return tianyi
