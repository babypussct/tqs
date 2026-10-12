local liwen = fk.CreateSkill {
  name = "liwen",
}

Fk:loadTranslationTable {
  ["liwen"] = "立文",
  [":liwen"] = "游戏开始时，你获得三枚“贤”标记；当你使用或打出非虚拟牌时，若此牌与你使用或打出的上一张非虚拟牌花色或类别相同，你获得一枚“贤”标记；" ..
      "回合结束时，你需将任意个“贤”标记分配给等量的角色（每名角色“贤”标记上限为5个），然后有“贤”标记的角色按照标记从多到少的顺序，依次使用一张手牌，" ..
      "若其不使用，移去其“贤”标记，你摸等量的牌。",

  ["@kongrong_virtuous"] = "贤",
  ["@liwen_record"] = "立文",
  ["#liwen-choose"] = "立文：你可以将“贤”标记交给其他角色各一枚（每名角色至多5枚）",
  ["#liwen-use"] = "立文：请使用一张手牌，否则你弃置所有“贤”标记，%src 摸牌",

  ["$liwen1"] = "伐竹筑学宫，大庇天下士子。",
  ["$liwen2"] = "学而不厌，诲人不倦，何有于我哉。",
}
--- 询问玩家从一些实体牌中选一个使用。默认无次数限制，与askForUseCard主要区别是不能调用转化技（酒默认不是无次数限制）
---@param player ServerPlayer @ 要询问的玩家
---@param params AskToUseRealCardParams @ 各种变量
---@return UseCardDataSpec? @ 返回卡牌使用框架。取消使用则返回空
local function askToUseRealCard(player, params)
  local self = player.room
  params.pattern = type(params.pattern) == "string" and params.pattern or tostring(Exppattern { id = params.pattern })
  params.skill_name = params.skill_name or ""
  params.prompt = params.prompt or ("#AskForUseOneCard:::" .. params.skill_name)
  if (params.cancelable == nil) then params.cancelable = true end
  local extra_data = params.extra_data and table.simpleClone(params.extra_data) or {}
  if extra_data.bypass_times == nil then extra_data.bypass_times = true end
  if extra_data.extraUse == nil then extra_data.extraUse = true end
  if extra_data.not_passive == nil then extra_data.not_passive = true end
  local pattern, skillName, prompt, cancelable, skipUse = params.pattern, params.skill_name, params.prompt,
      params.cancelable, params.skip

  local pile = params.expand_pile or extra_data.expand_pile
  local cards = player:getCardIds("h")
  if type(pile) == "string" then
    table.insertTable(cards, player:getPile(pile))
  elseif type(pile) == "table" then
    table.insertTable(cards, pile)
  end
  if pile and extra_data.expand_pile == nil then
    extra_data.expand_pile = pile
  end

  local cardIds = {}
  for _, cid in ipairs(cards) do
    local card = Fk:getCardById(cid)
    if card.trueName == "analeptic" then
      extra_data.bypass_times = false
      extra_data.extraUse = false
    end
    if Exppattern:Parse(pattern):match(card) then
      if #card:getAvailableTargets(player, extra_data) > 0 or
          (card.is_passive and not extra_data.not_passive and not player:prohibitUse(card)) then
        table.insert(cardIds, cid)
      end
    end
  end

  extra_data.skillName = skillName
  if #cardIds == 0 and not cancelable then return end
  extra_data.cardIds = cardIds
  local _, dat = self:askToUseActiveSkill(player, {
    skill_name = "userealcard_skill",
    prompt = prompt,
    cancelable = cancelable,
    extra_data = extra_data,
  })
  if (not cancelable) and (not dat) then
    for _, cid in ipairs(cardIds) do
      local card = Fk:getCardById(cid)
      local temp = card:getDefaultTarget(player, extra_data)
      if #temp > 0 or (card.is_passive and not extra_data.not_passive and not player:prohibitUse(card)) then
        dat = { targets = temp, cards = { cid } }
        break
      end
    end
  end
  if not dat then return end
  local card = Fk:getCardById(dat.cards[1])
  if card == nil then return end
  local use = {
    from = player,
    tos = #dat.targets > 0 and dat.targets or card:getDefaultTarget(player, extra_data),
    card = card,
    extraUse = extra_data.extraUse,
  }
  if not skipUse then
    self:useCard(use)
  end
  return use
end



liwen:addLoseEffect(function(self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@liwen_record", 0)
  for _, p in ipairs(room.alive_players) do
    room:setPlayerMark(p, "@kongrong_virtuous", 0)
  end
end)

liwen:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(liwen.name) and player:getMark("@kongrong_virtuous") < 5
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@kongrong_virtuous", math.min(3, 5 - player:getMark("@kongrong_virtuous")))
  end,
})

local liwen_record = {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(liwen.name, true) and #Card:getIdList(data.card) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card:getSuitString() == player:getMark("liwen_suit") or data.card.type == player:getMark("liwen_type") then
      data.extra_data = data.extra_data or {}
      data.extra_data.liwen_triggerable = true
    end
    if data.card.suit == Card.NoSuit then
      room:setPlayerMark(player, "liwen_suit", 0)
    else
      room:setPlayerMark(player, "liwen_suit", data.card:getSuitString())
    end
    room:setPlayerMark(player, "liwen_type", data.card.type)
    room:setPlayerMark(player, "@liwen_record", { data.card:getSuitString(true), data.card:getTypeString() })
  end,
}
liwen:addEffect(fk.AfterCardUseDeclared, liwen_record)
liwen:addEffect(fk.CardResponding, liwen_record)

local liwen_spec = {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liwen.name) and #Card:getIdList(data.card) > 0 and
        data.extra_data and data.extra_data.liwen_triggerable and player:getMark("@kongrong_virtuous") < 5
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@kongrong_virtuous", 1)
  end,
}
liwen:addEffect(fk.CardUsing, liwen_spec)
liwen:addEffect(fk.CardResponding, liwen_spec)

liwen:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liwen.name) and
        player:getMark("@kongrong_virtuous") > 0 and
        table.find(player.room:getOtherPlayers(player, false), function(p)
          return p:getMark("@kongrong_virtuous") < 5
        end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p:getMark("@kongrong_virtuous") < 5
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = player:getMark("@kongrong_virtuous"),
      prompt = "#liwen-choose",
      skill_name = liwen.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
    end
    for _, to in ipairs(tos) do
      room:removePlayerMark(player, "@kongrong_virtuous", 1)
      room:addPlayerMark(to, "@kongrong_virtuous", 1)
    end
    targets = {}
    for i = 5, 1, -1 do
      for _, p in ipairs(room:getAlivePlayers(false)) do
        if p:getMark("@kongrong_virtuous") == i then
          table.insert(targets, p)
        end
      end
    end
    for _, p in ipairs(targets) do
      if not p.dead then
        local use = nil
        if not p:isKongcheng() then
          use = askToUseRealCard(p, {
            pattern = p:getCardIds("h"),
            skill_name = liwen.name,
            prompt = "#liwen-use:" .. player.id,
            extra_data = {
              bypass_times = true,
              extraUse = true,
            },
            cancelable = true,
            skip = true,
          })
        end
        if use then
          room:useCard(use)
        else
          local n = p:getMark("@kongrong_virtuous")
          room:setPlayerMark(p, "@kongrong_virtuous", 0)
          if not player.dead then
            player:drawCards(n, liwen.name)
          end
        end
      end
    end
  end,
})

return liwen
