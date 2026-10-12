local juzhan = fk.CreateSkill {
  name = "m_ex__juzhan",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable {
  ["m_ex__juzhan"] = "拒战",
  [":m_ex__juzhan"] =
      "转换技，若你初始势力为蜀，此技能初始状态为阴。<br>" ..
      "阳：你或此状态下第三次有角色成为【杀】的目标后，你可以与此【杀】使用者各摸一张牌，其本回合不能对你使用牌。" ..
      "阴：你或此状态下第三次有角色使用【杀】指定目标后，你可以获得此【杀】目标一张牌，本回合你不能对其使用牌。" ..
      "乘势：你的出牌阶段使用【杀】次数+1，并于此【杀】结算后获得之。",

  [":m_ex__juzhan_yang"] =
      "转换技，<font color=\"#E0DB2F\">阳：你或此状态下第三次有角色成为【杀】的目标后，你可以与此【杀】使用者各摸一张牌，" ..
      "其本回合不能对你使用牌。</font>阴：你或此状态下第三次有角色使用【杀】指定目标后，你可以获得此【杀】目标一张牌，本回合你不能对其使用牌。" ..
      "乘势：你的出牌阶段使用【杀】次数+1，并于此【杀】结算后获得之。",
  [":m_ex__juzhan_yin"] =
      "转换技，阳：你或此状态下第三次有角色成为【杀】的目标后，你可以与此【杀】使用者各摸一张牌，其本回合不能对你使用牌。" ..
      "<font color=\"#E0DB2F\">阴：你或此状态下第三次有角色使用【杀】指定目标后，你可以获得此【杀】目标一张牌，本回合你不能对其使用牌。</font>" ..
      "乘势：你的出牌阶段使用【杀】次数+1，并于此【杀】结算后获得之。",

  ["@m_ex__juzhan_yang"] = "拒战阳",
  ["@m_ex__juzhan_yin"] = "拒战阴",

  ["$m_ex__juzhan1"] = "纵公放虎为祸，老夫亦独守关前！",
  ["$m_ex__juzhan2"] = "川中壮士岂是汝等可欺！",
  ["$m_ex__juzhan3"] = "若老夫壮年之时，必生擒此黑厮！",
  ["$m_ex__juzhan4"] = "哈哈哈哈！尽逞口舌之快，于战又有何益？",
}

---@param player ServerPlayer
---@param state string|integer
local function initStateMark(player, state)
  local room = player.room
  if state == "yang" or state == fk.SwitchYang then
    room:setPlayerMark(player, "@m_ex__juzhan_yang", "0")
    room:setPlayerMark(player, "@m_ex__juzhan_yin", 0)
  elseif state == "yin" or state == fk.SwitchYin then
    room:setPlayerMark(player, "@m_ex__juzhan_yin", "0")
    room:setPlayerMark(player, "@m_ex__juzhan_yang", 0)
  end
end

juzhan:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return (target == player or ((data.extra_data or {}).m_ex__juzhan_yang or {})[player]) and
        player:hasSkill(juzhan.name) and
        data.card.trueName == "slash" and
        player:getSwitchSkillState(juzhan.name, false) == fk.SwitchYang and
        not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
          skill_name = juzhan.name,
          prompt = "#juzhan-yang:" .. data.from.id,
        }) then
      event:setCostData(self, { tos = { data.from } })
      return true
    elseif tonumber(player:getMark("@m_ex__juzhan_yang")) >= 3 then
      room:setPlayerMark(player, "@m_ex__juzhan_yang", 0)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    initStateMark(player, fk.SwitchYin)
    player:drawCards(1, juzhan.name)
    if data.from.dead then return end
    room:addTableMark(data.from, "@@juzhan-turn", player.id)
    data.from:drawCards(1, juzhan.name)
    if not player.dead and target == player and ((data.extra_data or {}).m_ex__juzhan_yang or {})[player] then
      room:addPlayerMark(player, MarkEnum.SlashResidue, 1)
      data.extra_data.m_ex__juzhan_prey = player
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(juzhan.name, true) and
        player:getSwitchSkillState(juzhan.name) == fk.SwitchYang and
        data.card.trueName == "slash" and
        player:hasMark("@m_ex__juzhan_yang")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local count = tonumber(player:getMark("@m_ex__juzhan_yang"))
    count = count + 1
    room:setPlayerMark(player, "@m_ex__juzhan_yang", tostring(count))
    if count == 3 then
      data.extra_data = data.extra_data or {}
      data.extra_data.m_ex__juzhan_yang = data.extra_data.m_ex__juzhan_yang or {}
      data.extra_data.m_ex__juzhan_yang[player] = true
    end
  end,
})

juzhan:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return (target == player or ((data.extra_data or {}).m_ex__juzhan_yin or {})[player]) and
        player:hasSkill(juzhan.name) and
        data.card.trueName == "slash" and
        player:getSwitchSkillState(juzhan.name, false) == fk.SwitchYin and
        not data.to:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.room:askToSkillInvoke(player, {
          skill_name = juzhan.name,
          prompt = "#juzhan-yin:" .. data.to.id,
        }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    elseif tonumber(player:getMark("@m_ex__juzhan_yin")) >= 3 then
      room:setPlayerMark(player, "@m_ex__juzhan_yin", 0)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    initStateMark(player, fk.SwitchYang)
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = "he",
      skill_name = juzhan.name,
    })
    room:addTableMark(player, "@@juzhan-turn", data.to.id)
    room:obtainCard(player, card, false, fk.ReasonPrey, player, juzhan.name)
    if not player.dead and target == player and ((data.extra_data or {}).m_ex__juzhan_yin or {})[player] then
      room:addPlayerMark(player, MarkEnum.SlashResidue, 1)
      data.extra_data.m_ex__juzhan_prey = player
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(juzhan.name, true) and
        player:getSwitchSkillState(juzhan.name) == fk.SwitchYin and
        data.card.trueName == "slash" and
        player:hasMark("@m_ex__juzhan_yin")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local count = tonumber(player:getMark("@m_ex__juzhan_yin"))
    count = count + 1
    room:setPlayerMark(player, "@m_ex__juzhan_yin", tostring(count))
    if count == 3 then
      data.extra_data = data.extra_data or {}
      data.extra_data.m_ex__juzhan_yin = data.extra_data.m_ex__juzhan_yin or {}
      data.extra_data.m_ex__juzhan_yin[player] = true
    end
  end,
})

juzhan:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and (data.extra_data or {}).m_ex__juzhan_prey == player and
        player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, juzhan.name, nil, false, player)
  end,
})

juzhan:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and from and table.contains(from:getTableMark("@@juzhan-turn"), to.id)
  end,
})

juzhan:addEffect(fk.GameStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(juzhan.name, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.kingdom == "shu" then
      room:setPlayerMark(player, MarkEnum.SwithSkillPreName .. juzhan.name, 1)
      player:setSkillUseHistory(juzhan.name, 0, Player.HistoryGame)
    end
    initStateMark(player, player:getSwitchSkillState(juzhan.name))
  end,
})

juzhan:addAcquireEffect(function(self, player, is_start, src)
  if is_start then return end
  local room = player.room
  initStateMark(player, player:getSwitchSkillState(juzhan.name))
end)

juzhan:addLoseEffect(function(self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@m_ex__juzhan_yang", 0)
  room:setPlayerMark(player, "@m_ex__juzhan_yin", 0)
end)

return juzhan
