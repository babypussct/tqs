local qiantun = fk.CreateSkill {
  name = "mobile__qiantun",
  tags = {Skill.AttachedKingdom},
  attached_kingdom = {"wei"},
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "mobile__qiantun_1v2"
    else
      return "mobile__qiantun_role_mode"
    end
  end,
}

Fk:loadTranslationTable{
  ["mobile__qiantun"] = "谦吞",
  [":mobile__qiantun"] = "魏势力技，出牌阶段限一次，你可以令一名有手牌的其他角色展示至少一张手牌，然后你与其拼点（其仅能用展示牌拼点）。"..
  "若你赢，你获得其展示的手牌；若你没赢，你获得其未展示的手牌。（若为斗地主模式，至多获得两张）",

  [":mobile__qiantun_role_mode"] = "魏势力技，出牌阶段限一次，你可以令一名有手牌的其他角色展示至少一张手牌，然后你与其拼点（其仅能用展示牌拼点）。"..
  "若你赢，你获得其展示的手牌；若你没赢，你获得其未展示的手牌。",
  [":mobile__qiantun_1v2"] = "魏势力技，出牌阶段限一次，你可以令一名有手牌的其他角色展示至少一张手牌，然后你与其拼点（其仅能用展示牌拼点）。"..
  "若你赢，你获得其展示的手牌；若你没赢，你获得其未展示的手牌。（至多获得两张）",

  ["#mobile__qiantun"] = "谦吞：令一名角色展示任意张手牌并与其拼点，若赢，你获得展示牌；若没赢，你获得其未展示的手牌",
  ["#mobile__qiantun-ask"] = "谦吞：请展示任意张手牌，你将只能用这些牌与 %src 拼点，根据拼点结果其获得你的展示牌或未展示牌！",
  ["#mobile__qiantun-pindian"] = "谦吞：你只能用这些牌与 %src 拼点！若其赢，其获得你的展示牌；若其没赢，其获得你未展示的手牌",

  ["$mobile__qiantun1"] = "天下未定，吾当辞邑修身，何敢冒僭？",
  ["$mobile__qiantun2"] = "统摄朝野，威加海内，此皆陛下恩德！",
  ["$mobile__qiantun3"] = "满朝尽忠天子，何有不臣之人？",--谦吞（赢）	
  ["$mobile__qiantun4"] = "九辞封赐，足见臣一片忠心。",--谦吞（没赢）
}

qiantun:addEffect("active", {
  mute = true,
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__qiantun",
  can_use = function(self, player)
    return player:usedSkillTimes(qiantun.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    player:broadcastSkillInvoke(qiantun.name, math.random(1, 2))
    room:notifySkillInvoked(player, qiantun.name, "control")
    local cards = room:askToCards(target, {
      min_num = 1,
      max_num = 999,
      include_equip = false,
      skill_name = qiantun.name,
      prompt = "#mobile__qiantun-ask:" .. player.id,
      cancelable = false,
    })
    target:showCards(cards)
    cards = table.filter(cards, function (id)
      return table.contains(target:getCardIds("h"), id)
    end)
    if player.dead or target.dead or #cards == 0 or not player:canPindian(target) then return end
    local pindian = {
      from = player,
      tos = {target},
      reason = qiantun.name,
      fromCard = nil,
      results = {},
      extra_data = {
        mobile__qiantun = {
          to = target,
          cards = cards,
        },
      },
    }
    room:pindian(pindian)
    if player.dead or target.dead then return end
    if pindian.results[target].winner == player then
      player:broadcastSkillInvoke(qiantun.name, 3)
      cards = table.filter(target:getCardIds("h"), function (id)
        return table.contains(cards, id)
      end)
    else
      player:broadcastSkillInvoke(qiantun.name, 4)
      cards = table.filter(target:getCardIds("h"), function (id)
        return not table.contains(cards, id)
      end)
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, qiantun.name, nil, false, player)
    end
    if not player.dead and not player:isKongcheng() then
      player:showCards(player:getCardIds("h"))
    end
  end,
})
qiantun:addEffect(fk.StartPindian, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player == data.from and data.reason == qiantun.name and data.extra_data and data.extra_data.mobile__qiantun then
      for _, to in ipairs(data.tos) do
        if not (data.results[to] and data.results[to].toCard) and
          data.extra_data.mobile__qiantun.to == to and
          table.find(data.extra_data.mobile__qiantun.cards, function (id)
            return table.contains(to:getCardIds("h"), id)
          end) then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, to in ipairs(data.tos) do
      if not (to.dead or to:isKongcheng() or (data.results[to] and data.results[to].toCard)) and
        data.extra_data.mobile__qiantun.to == to then
        local cards = table.filter(data.extra_data.mobile__qiantun.cards, function (id)
          return table.contains(to:getCardIds("h"), id)
        end)
        if #cards > 0 then
          local card = room:askToCards(to, {
            min_num = 1,
            max_num = 1,
            include_equip = false,
            skill_name = qiantun.name,
            pattern = tostring(Exppattern{ id = cards }),
            prompt = "#mobile__qiantun-pindian:"..data.from.id,
            cancelable = false,
          })
          data.results[to] = data.results[to] or {}
          data.results[to].toCard = Fk:getCardById(card[1])
        end
      end
    end
  end,
})

qiantun:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    if #ai:getEnabledTargets() == 0 then return end

    local ret, benefit = nil, -100000
    for _, p in ipairs(ai:getEnabledTargets()) do
      local tmp = ai:getBenefitOfEvents(function(logic)
        logic:pindian{
          from = ai.player,
          tos = { p },
          reason = self.skill_name,
          results = {},
        }
        local n = p:getHandcardNum() - 1
        if n > 0 then
          local cards = table.random(p:getCardIds("h"), n)
          logic:moveCardTo(cards, Card.PlayerHand, ai.player, fk.ReasonPrey, self.skill_name, nil, false, ai.player)
        end
      end)
      if tmp > benefit then
        ret, benefit = p, tmp
      end
    end
    if ret then
      return { { }, { ret } }, benefit
    end
  end,
})

return qiantun
