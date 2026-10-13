local rule = fk.CreateSkill {
  name = "#chaos_rule&",
}

Fk:loadTranslationTable{
  ["#chaos_rule&"] = "文和乱武",
  ["@[:]chaos_mode_event"] = "事件",
  ["chaos_mode_event_log"] = "本轮的“文和乱武” %arg",
  ["chaos_intro"] = "<b>一人一队</b>，文和乱武的大吃鸡时代，你能入主长安吗？<br>"..
  "<b>每轮会有随机事件</b>，可点击<b>左上角</b>查看详情，祝你好运。<br>"..
  "线下规则新上线，默认采用，可在模式设置中更改。",
  ["chaos_fisrt_round"] = "第一轮时，已受伤角色视为拥有〖八阵〗。",

  ["#chaos_mode_equip_use"] = "游戏开始时，你可以使用任意张装备牌",

  ["chaos_e: 1"] = "事件：乱武。从随机一名角色开始，所有角色，需对距离最近的一名角色使用一张【杀】，否则失去1点体力。",
  ["chaos_luanwu"] = "乱武",
  [":chaos_luanwu"] = "从随机一名角色开始，所有角色需对距离最近的一名角色使用一张【杀】，否则失去1点体力。",

  ["chaos_e: 2"] = "事件：重赏。本轮中，击杀角色奖励翻倍。",
  ["generous_reward"] = "重赏",
  [":generous_reward"] = "本轮中，击杀角色奖励翻倍。",

  ["chaos_e: 3"] = "事件：破釜沉舟。一名角色的回合开始时，失去1点体力，摸三张牌。",
  ["burning_one's_boats"] = "破釜沉舟",
  [":burning_one's_boats"] = "一名角色的回合开始时，其失去1点体力，摸三张牌。",

  ["chaos_e: 4"] = "事件：横刀跃马。每个回合结束时，所有装备最少的角色失去1点体力，随机将一张装备牌置入其装备区。",
  ["leveling_the_blades"] = "横刀跃马",
  [":leveling_the_blades"] = "每个回合结束时，所有装备最少的角色失去1点体力，随机将一张装备牌置入其装备区。",
  ["#chaos_mode_event_4_log"] = "%from 由于“%arg”，将 %arg2 置入装备区",

  ["chaos_e: 5"] = "事件：横扫千军。本轮中，所有伤害值+1。",
  ["sweeping_all"] = "横扫千军",
  [":sweeping_all"] = "本轮中，所有伤害值+1。",

  ["chaos_e: 6"] = "事件：饿莩载道。本轮结束时，所有手牌最少的角色失去X点体力。（X为轮数）",
  ["starvation"] = "饿莩载道",
  [":starvation"] = "本轮结束时，所有手牌最少的角色失去X点体力。（X为轮数）",

  ["chaos_e: 7"] = "事件：宴安鸩毒。本轮中，所有的【桃】均视为<a href=':poison'>【毒】</a>。",
  ["poisoned_banquet"] = "宴安鸩毒",
  [":poisoned_banquet"] = "本轮中，所有的【桃】均视为<a href=':poison'>【毒】</a>。",

  ["chaos_e: 8"] = "事件：战备。已受伤角色视为拥有<a href=':bazhen'>〖八阵〗</a>。",
  ["chaos_mobilization"] = "战备",
  [":chaos_mobilization"] = "已受伤角色视为拥有<a href=':bazhen'>〖八阵〗</a>。",

  ["@!!chaos_grain-noclear"] = "粮草",
  [":@!!chaos_grain-noclear"] = "①每轮开始时，每名角色获得2枚“粮草”标记。<br/>②当一名角色对其他角色造成伤害后，" ..
    "获得其一半的“粮草”标记（向下取整）。<br/>③出牌阶段开始时，角色可以花费“粮草”标记，从供给区中获得牌，然后用牌堆顶的牌将供给区牌补到3张。" ..
    "基本牌2枚“粮草”，非基本牌3枚“粮草”。",
  ["#chaos_grain_lose"] = "%from 失去了 %arg 枚 “%arg2”，剩余 %arg3 枚 “%arg2”",
  ["#chaos_grain_gain"] = "%from 获得了 %arg 枚 “%arg2”，共有 %arg3 枚 “%arg2”",
  ["@$ChaosSupply"] = "供给区",
  ["@ChaosSupply"] = "供给牌",
  ["chaos_grain_take_supply"] = "粮草供给",
  ["#chaos_grain_take_supply"] = "你可以花费“粮草”，获得供给区中的牌，基本牌2枚，非基本牌3枚。你有 %arg 枚“粮草”",

  ["recover2"] = "回复2点体力",
}

--所有人获得完杀（线上）
rule:addEffect(fk.GameStart, {
  can_refresh = function (self, event, target, player, data)
    return player.seat == 1 and player.room:getSettings("modeChoice") == "chaos_mode_online"
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.players) do
      room:handleAddLoseSkills(p, "wansha", nil, false, true)
    end
  end,
})

--所有人不能对其他角色用桃（线下）
rule:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return Fk:currentRoom():getSettings("modeChoice") == "chaos_mode_choice:custom" and card.name == "peach" and from ~= to
  end,
})

--获胜
rule:addEffect(fk.GameOverJudge, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setTag("SkipGameRule", true)
    if #room.alive_players == 1 then
      local winner = Fk.game_modes[room:getSettings('gameMode')]:getWinner(player)
      if winner ~= "" then
        room:gameOver(winner)
      end
    end
  end,
})

--游戏开始时，所有人可以使用任意张装备牌（线下）
rule:addEffect(fk.GameStart, {
  priority = 0.001,
  mute = true,
  can_refresh = function (self, event, target, player, data)
    return player.seat == 1 and player.room:getSettings("modeChoice") == "chaos_mode_choice:custom"
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.players) do
      while true do
        if not room:askToUseRealCard(p, {
          pattern = ".|.|.|.|.|equip",
          skill_name = "chaos_mobilization",
          cancelable = true,
          prompt = "#chaos_mode_equip_use",
        }) then break end
      end
    end
  end,
})

--- 粮草机制（线下）

local function addGrain(room, player, num)
  room:addPlayerMark(player, "@!!chaos_grain-noclear", num)
  room:sendLog{
    type = "#chaos_grain_gain",
    from = player.id,
    arg = num,
    arg2 = "@!!chaos_grain-noclear",
    arg3 = player:getMark("@!!chaos_grain-noclear"),
  }
end

local function removeGrain(room, player, num)
  room:removePlayerMark(player, "@!!chaos_grain-noclear", num)
  room:sendLog{
    type = "#chaos_grain_lose",
    from = player.id,
    arg = num,
    arg2 = "@!!chaos_grain-noclear",
    arg3 = player:getMark("@!!chaos_grain-noclear"),
  }
end

-- 每轮开始时，所有角色获得2点粮草
rule:addEffect(fk.RoundStart, {
  priority = 0.001,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player == target and player.room:getSettings("modeChoice") == "chaos_mode_choice:custom"
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      addGrain(room, p, 2)
    end
  end,
})

-- 当一名角色对其他角色造成伤害后，获得其一半的粮草（向下取整）
rule:addEffect(fk.Damage, {
  priority = 0.001,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player == target and player.room:getSettings("modeChoice") == "chaos_mode_choice:custom"
      and data.to ~= player and data.to:getMark("@!!chaos_grain-noclear") > 1
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local grain = data.to:getMark("@!!chaos_grain-noclear") // 2
    removeGrain(room, data.to, grain)
    addGrain(room, player, grain)
  end,
})

-- 游戏开始设置供给区
rule:addEffect(fk.GameStart, {
  priority = 0.001,
  mute = true,
  can_refresh = function (self, event, target, player, data)
    return player.seat == 1 and player.room:getSettings("modeChoice") == "chaos_mode_choice:custom"
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:moveCardTo(cards, Card.Void, nil, fk.ReasonJustMove, rule.name, nil, true, player)
    room:setBanner("@$ChaosSupply", cards)
    room:setBanner("@ChaosSupply", table.map(cards, function(id) return Fk:getCardById(id).name end))
  end,
})

local function getGrainCost(id)
  return Fk:getCardById(id).type == Card.TypeBasic and 2 or 3
end

-- 出牌阶段开始时，角色可以花费粮草，从供给区中获得牌，然后用牌堆顶的牌将供给区牌补到3张
rule:addEffect(fk.EventPhaseStart, {
  priority = 0.001,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player.phase == Player.Play and
      player.room:getSettings("modeChoice") == "chaos_mode_choice:custom" and
      player:getMark("@!!chaos_grain-noclear") > 1
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    while true do
      if player:getMark("@!!chaos_grain-noclear") < 2 then break end
      local supply_ids = room:getBanner("@$ChaosSupply") or {}
      if #supply_ids == 0 then break end
      local cards = room:askToPoxi(player, {
        poxi_type = "chaos_grain_take_supply",
        cancelable = true,
        extra_data = player:getMark("@!!chaos_grain-noclear"),
        data = {{"@$ChaosSupply", supply_ids}},
      })
      if #cards == 0 then break end
      local total_cost = 0
      for _, id in ipairs(cards) do
        total_cost = total_cost + getGrainCost(id)
      end
      removeGrain(room, player, total_cost)
      room:obtainCard(player, cards, true, fk.ReasonPrey, player, "chaos_grain_take_supply")
      local n = 0
      for _, card in ipairs(cards) do
        table.removeOne(supply_ids, card)
        n = n + 1
      end
      local new_cards = room:getNCards(n)
      table.insertTable(supply_ids, new_cards)
      room:moveCardTo(new_cards, Card.Void, nil, fk.ReasonJustMove, rule.name, nil, true, player)
      room:setBanner("@$ChaosSupply", supply_ids)
      room:setBanner("@ChaosSupply", table.map(supply_ids, function(id) return Fk:getCardById(id).name end))
    end
  end,
})


Fk:addPoxiMethod{
  name = "chaos_grain_take_supply",
  card_filter = function(to_select, selected, data, extra_data)
    local n = getGrainCost(to_select)
    for _, id in ipairs(selected) do
      n = n + getGrainCost(id)
    end
    return n <= extra_data
  end,
  feasible = function (selected, data, extra_data)
    local n = 0
    for _, id in ipairs(selected) do
      n = n + getGrainCost(id)
    end
    return n <= extra_data
  end,
  prompt = function (data, extra_data)
    return "#chaos_grain_take_supply:::" .. extra_data
  end
}

--- 随机事件

--每轮开始触发随机事件
rule:addEffect(fk.RoundStart, {
  priority = 0.001,
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player.seat == 1
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local index = math.random(1, 7)
    if room:getBanner("RoundCount") == 1 then
      if room:getSettings("modeChoice") == "chaos_mode_online" then
        room:doBroadcastNotify("ShowToast", Fk:translate("chaos_fisrt_round"))
        index = 1
      else
        index = 8
      end
    end
    local chaos_event = {
      "chaos_luanwu",
      "generous_reward",
      "burning_one's_boats",
      "leveling_the_blades",
      "sweeping_all",
      "starvation",
      "poisoned_banquet",
      "chaos_mobilization", -- 线上无
    }
    room:setBanner("@[:]chaos_mode_event", chaos_event[index])
    if index == 7 then
      room:setBanner("_chaos_mode_event-round", "poisoned_banquet")
    end
    room:notifyMoveFocus(room.alive_players, rule.name)
    room:sendLog{
      type = "chaos_mode_event_log",
      arg = "chaos_e: " .. tostring(index),
      toast = true,
    }
    room:delay(3500)

    --事件1乱武
    if index == 1 then
      local online = room:getSettings("modeChoice") == "chaos_mode_online"
      -- 线上随机一人，线下从座位最小的开始
      local from = online and room:tableRandomPick(room.alive_players) or room:getAlivePlayers()[1]
      from:broadcastSkillInvoke("luanwu")
      room:notifySkillInvoked(from, "luanwu", "big")
      local targets = room:getAlivePlayers(false)
      room:sortByAction(targets, from)
      for _, target in ipairs(targets) do
        if not target.dead then
          local other_players = table.filter(room:getOtherPlayers(target, false), function(p)
            return not p:isRemoved()
          end)
          local luanwu_targets = table.filter(other_players, function(p2)
            return table.every(other_players, function(p1)
              return target:distanceTo(p1) >= target:distanceTo(p2)
            end)
          end)
          local use = room:askToUseCard(target, {
            pattern = "slash",
            prompt = "#luanwu-use",
            cancelable = true,
            extra_data = {
              exclusive_targets = table.map(luanwu_targets, Util.IdMapper),
              bypass_times = true,
            },
            skill_name = "luanwu",
          })
          if use then
            use.extraUse = true
            room:useCard(use)
          else
            room:loseHp(target, 1, rule.name)
          end
        end
      end
    end
  end,
})

--事件3破釜沉舟
rule:addEffect(fk.TurnStart, {
  priority = 0.001,
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player.room:getBanner("@[:]chaos_mode_event") == "burning_one's_boats"
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, rule.name)
    if not player.dead then
      player:drawCards(3, rule.name)
    end
  end,
})

--事件4横刀跃马
rule:addEffect(fk.TurnEnd, {
  priority = 0.001,
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player.room:getBanner("@[:]chaos_mode_event") == "leveling_the_blades"
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return table.every(room.alive_players, function(p2)
        return #p:getCardIds("e") <= #p2:getCardIds("e")
      end)
    end)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        room:loseHp(p, 1, rule.name)
        if not p.dead then
          local cards = table.filter(room.draw_pile, function (id)
            return p:canMoveCardIntoEquip(id, false)
          end)
          if #cards > 0 then
            local id = room:tableRandomPick(cards)
            room:sendLog{
              type = "#chaos_mode_event_4_log",
              from = p.id,
              arg = "leveling_the_blades",
              arg2 = Fk:getCardById(id):toLogString(),
            }
            room:moveCardIntoEquip(p, id, rule.name, false)
          end
        end
      end
    end
  end,
})

--事件5横扫千军
rule:addEffect(fk.DamageInflicted, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player.room:getBanner("@[:]chaos_mode_event") == "sweeping_all"
  end,
  on_refresh = function (self, event, target, player, data)
    data:changeDamage(1)
  end,
})

--事件6饿莩载道
rule:addEffect(fk.RoundEnd, {
  priority = 0.001,
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player.room:getBanner("@[:]chaos_mode_event") == "starvation"
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return table.every(room.alive_players, function(p2)
        return p:getHandcardNum() <= p2:getHandcardNum()
      end)
    end)
    room:sortByAction(targets)
    local num = room:getBanner("RoundCount")
    for _, p in ipairs(targets) do
      if not p.dead then
        room:loseHp(p, num, rule.name)
      end
    end
  end,
})

--事件7宴安鸩毒
rule:addEffect("filter", {
  card_filter = function(self, to_select, player)
    return Fk:currentRoom():getBanner("_chaos_mode_event-round") == "poisoned_banquet" and to_select.name == "peach"
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("poison", card.suit, card.number)
  end,
})

--首轮，已受伤角色视为拥有八阵
local spec={
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isWounded() and (player.room:getBanner("RoundCount") == 1 or player.room:getBanner("@[:]chaos_mode_event") == "chaos_mobilization") and
      (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none")) and
      #player:getEquipments(Card.SubtypeArmor) == 0 and not player:prohibitUse(Fk:cloneCard("jink")) 
      and (data.extraData == {} or data.extraData.not_passive ~= true) and
      Fk.skills["#eight_diagram_skill"] ~= nil and Fk.skills["#eight_diagram_skill"]:isEffectable(player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = "bazhen",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/standard_cards/audio/card/eight_diagram")
    room:setEmotion(player, "./packages/standard_cards/image/anim/eight_diagram")
    player:broadcastSkillInvoke("bazhen")
    room:notifySkillInvoked(player, "bazhen", "defensive")
    local skill = Fk.skills["#eight_diagram_skill"]
    skill:use(event, target, player, data)
  end,
}
rule:addEffect(fk.AskForCardUse, spec)
rule:addEffect(fk.AskForCardResponse, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isWounded() and (player.room:getBanner("RoundCount") == 1 or player.room:getBanner("@[:]chaos_mode_event") == "chaos_mobilization") and
      (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none")) and
      #player:getEquipments(Card.SubtypeArmor) == 0 and not player:prohibitResponse(Fk:cloneCard("jink")) and
      Fk.skills["#eight_diagram_skill"] ~= nil and Fk.skills["#eight_diagram_skill"]:isEffectable(player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = "bazhen",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/standard_cards/audio/card/eight_diagram")
    room:setEmotion(player, "./packages/standard_cards/image/anim/eight_diagram")
    player:broadcastSkillInvoke("bazhen")
    room:notifySkillInvoked(player, "bazhen", "defensive")
    local skill = Fk.skills["#eight_diagram_skill"]
    skill:use(event, target, player, data)
  end,
})

return rule