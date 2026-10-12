local rule = fk.CreateSkill {
  name = "#rougelike1v1_talent",
}

local RougeUtil = require "packages.ol.pkg.ol_gamemode.rougelike1v1.util"
local hasTalent = RougeUtil.hasTalent
local hasTalentStart = function(...)
  return #RougeUtil.hasTalentStart(...) > 0
end
local sendTalentLog = RougeUtil.sendTalentLog

Fk:loadTranslationTable {
  ["#rougelike1v1_talent"] = "单骑无双",
}

rule:addEffect(fk.TurnEnd, {
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getCurrentExtraTurnReason() == "game_rule"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalent(player, "rouge_bingquanzaiwo1") then
      sendTalentLog(player, "rouge_bingquanzaiwo1")
      RougeUtil.changeMoney(player, 1)
    end
    for _, p in ipairs(room.alive_players) do
      if hasTalent(p, "rouge_bingquanzaiwo2") then
        sendTalentLog(player, "rouge_bingquanzaiwo2")
        RougeUtil.changeMoney(p, 1)
      end
      if hasTalent(p, "rouge_chijiuzhan2") and p:getMark("rouge_money") >= 5 then
        sendTalentLog(player, "rouge_chijiuzhan2")
        RougeUtil.changeMoney(p, 1)
      end
    end
  end,
})


rule:addEffect(fk.EventPhaseStart, {
  name = "#rougelike1v1_rule_eventphasestart_leiming",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and #table.filter(player.room.alive_players, function(p)
      return hasTalent(p, "rouge_leiming") and player.phase == Player.Judge
    end) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local findplayer = table.find(player.room.alive_players, function(p)
      return hasTalent(p, "rouge_leiming") ~= nil
    end)
    if findplayer then
      sendTalentLog(findplayer, "rouge_leiming")
    end

    for _, p in ipairs(player.room.alive_players) do
      if hasTalent(p, "rouge_leiming") then
        local judge = {
          who = player,
          reason = "lightning",
          pattern = ".|2~9|spade",
        }
        room:judge(judge)
        local result = judge.card
        if result.suit == Card.Spade and result.number >= 2 and result.number <= 9 then
          room:damage {
            to = player,
            damage = 3,
            damageType = Fk:getDamageNature(fk.ThunderDamage) and fk.ThunderDamage or fk.NormalDamage,
            skillName = "rouge_leiming",
          }
        end
      end
    end
  end
})

rule:addEffect(fk.TurnStart, {
  name = "#rougelike1v1_rule_turnstart",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and (RougeUtil.hasOneOfTalents(player,
        { "rouge_banyun", "rouge_bowen1", "rouge_bowen2", "rouge_bowen3", "rouge_fenjin",
          "rouge_yuanmou1", "rouge_yuanmou2", "rouge_yuanmou3" }) or
      hasTalentStart(player, "rouge_fuyiqu__"))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local talent = RougeUtil.hasTalent(player, "rouge_banyun")
    if talent then
      RougeUtil.sendTalentLog(player, talent)
      local enemies = table.filter(room.alive_players, function(p)
        return RougeUtil.isEnemy(player, p) and not p:isKongcheng()
      end)
      if #enemies ~= 0 then
        local card = room:tableRandomPick(room:tableRandomPick(enemies):getCardIds("h"))
        room:obtainCard(player, card, false, fk.ReasonPrey, player, talent)
      end
    end

    for i = 1, 3 do
      local t = "rouge_bowen" .. i
      if RougeUtil.hasTalent(player, t) then
        RougeUtil.sendTalentLog(player, t)
        local tricks = room:getCardsFromPileByRule('.|.|.|.|.|trick', i, "drawPile")
        if #tricks > 0 then room:obtainCard(player, tricks, true, fk.ReasonPrey, player, t) end
      end
    end

    talent = RougeUtil.hasTalent(player, "rouge_fenjin")
    if talent then
      if player.hp > 2 then
        RougeUtil.sendTalentLog(player, talent)
        room:loseHp(player, 1, talent)
        if player:isAlive() then player:drawCards(2, talent) end
      end
    end

    talent = RougeUtil.hasTalent(player, "rouge_yuanmou1")
    if talent and room:getBanner("RoundCount") == 3 and player:isWounded() then
      RougeUtil.sendTalentLog(player, talent)
      room:recover {
        who = player,
        num = 2,
        skillName = talent
      }
    end

    talent = RougeUtil.hasTalent(player, "rouge_yuanmou2")
    if talent and room:getBanner("RoundCount") == 3 and player:isWounded() then
      RougeUtil.sendTalentLog(player, talent)
      room:recover {
        who = player,
        num = 3,
        skillName = talent
      }
    end

    talent = RougeUtil.hasTalent(player, "rouge_yuanmou3")
    if talent and room:getBanner("RoundCount") == 2 and player:isWounded() then
      RougeUtil.sendTalentLog(player, talent)
      room:recover {
        who = player,
        num = 2,
        skillName = talent
      }
    end

    for _, talent in ipairs(RougeUtil.hasTalentStart(player, "rouge_fuyiqu__")) do
      sendTalentLog(player, talent)
      local name_splited = talent:split("rouge_fuyiqu__")
      local card_name = name_splited[#name_splited]
      if card_name then
        local card = room:getCardsFromPileByRule(card_name)
        room:obtainCard(player, card, true, fk.ReasonPrey, player, talent)
      end
    end
  end,

  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("rouge_hengfeng") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "rouge_hengfeng", 0)
  end,
})

rule:addEffect(fk.RoundStart, {
  name = "#rougelike1v1_rule_roundstart",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return RougeUtil.hasOneOfTalents(player,
      { "rouge_hujia", "rouge_hujia2",
        "rouge_xuezhan1", "rouge_xuezhan2", "rouge_xuezhan3" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if RougeUtil.hasTalent(player, "rouge_hujia") then
      RougeUtil.sendTalentLog(player, "rouge_hujia")
      room:changeShield(player, 1)
    end
    if RougeUtil.hasTalent(player, "rouge_hujia2") then
      RougeUtil.sendTalentLog(player, "rouge_hujia2")
      room:changeShield(player, 2)
    end

    for i = 1, 3 do
      local skillName = RougeUtil.hasTalent(player, "rouge_xuezhan" .. i)
      if skillName and player:isWounded() then
        RougeUtil.sendTalentLog(player, skillName)
        room:recover {
          who = player,
          num = i,
          recoverBy = player,
          skillName = skillName
        }
      end
    end
  end
})

rule:addEffect(fk.EventPhaseProceeding, {
  name = "#rougelike1v1_rule_draw_n_cards",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and RougeUtil.hasOneOfTalents(player,
      { "rouge_wendinghouqin" }) and player.phase == Player.Draw
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local talent = RougeUtil.hasTalent(player, "rouge_wendinghouqin")
    data.phase_end = true
    if talent then
      RougeUtil.sendTalentLog(player, talent)
      room.logic:trigger(fk.DrawNCards, player, { n = 2 })
      local drawcards = #room:drawCards(player, 5, "phase_draw")
      room.logic:trigger(fk.AfterDrawNCards, player, { n = drawcards })
    end
  end
})
rule:addEffect(fk.DrawNCards, {
  name = "#rougelike1v1_rule_draw_n_cards",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return (target == player and RougeUtil.hasOneOfTalents(player,
      { "rouge_buzhen1", "rouge_buzhen2", "rouge_buzhen3", "rouge_chijiuzhan3",
        "rouge_kuangbao3", "rouge_kuangbao4", "rouge_mopai1", "rouge_mopai2",
        "rouge_houfaxianzhi", "rouge_muniuliuma" })) or (
      RougeUtil.isEnemy(player, target) and RougeUtil.hasOneOfTalents(player,
        { "rouge_duanliangcao2" })
    )
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if RougeUtil.isEnemy(player, target) and RougeUtil.hasOneOfTalents(player,
          { "rouge_duanliangcao2" }) then
      RougeUtil.sendTalentLog(player, "rouge_duanliangcao2")
      data.n = data.n - 1
    else
      local talent = RougeUtil.hasTalent(player, "rouge_wendinghouqin")
      for i = 1, 3 do
        talent = RougeUtil.hasTalent(player, "rouge_buzhen" .. i)
        if talent and room:getBanner("RoundCount") >= i * 2 + 1 then
          RougeUtil.sendTalentLog(player, talent)
          data.n = data.n + 1
        end
      end



      if RougeUtil.hasTalent(player, "rouge_chijiuzhan3") then
        if player:getMark("rouge_money") >= 7 then
          RougeUtil.sendTalentLog(player, "rouge_chijiuzhan3")
          data.n = data.n + 1
        end
      end

      if RougeUtil.hasTalent(player, "rouge_kuangbao3") then
        if player.hp <= 3 then
          RougeUtil.sendTalentLog(player, "rouge_kuangbao3")
          data.n = data.n + 1
        end
      end
      if RougeUtil.hasTalent(player, "rouge_kuangbao4") then
        if player.hp <= 5 then
          RougeUtil.sendTalentLog(player, "rouge_kuangbao4")
          data.n = data.n + 1
        end
      end

      if RougeUtil.hasTalent(player, "rouge_mopai1") then
        RougeUtil.sendTalentLog(player, "rouge_mopai1")
        data.n = data.n + 1
      end
      if RougeUtil.hasTalent(player, "rouge_mopai2") then
        RougeUtil.sendTalentLog(player, "rouge_mopai2")
        data.n = data.n + 2
      end

      if RougeUtil.hasTalent(player, "rouge_houfaxianzhi") then
        RougeUtil.sendTalentLog(player, "rouge_houfaxianzhi")
        data.n = math.max(data.n - 1, 0)
      end

      if RougeUtil.hasTalent(player, "rouge_muniuliuma") then
        RougeUtil.sendTalentLog(player, "rouge_muniuliuma")
        data.n = data.n + 2
      end
    end
  end
})



rule:addEffect(fk.BeforeDrawCard, {
  name = "#rougelike1v1_rule_drawcard",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and RougeUtil.hasOneOfTalents(player,
      { "rouge_ershengsan" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if RougeUtil.hasTalent(player, "rouge_ershengsan") then
      if data.skillName == "ex_nihilo" then
        RougeUtil.sendTalentLog(player, "rouge_ershengsan")
        data.num = (data.num or 0) + 1
      end
    end
  end,
})

rule:addEffect(fk.AfterDrawNCards, {
  name = "#rougelike1v1_rule_AfterDrawNCards",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and RougeUtil.hasOneOfTalents(player,
      { "rouge_jinnangji" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if RougeUtil.hasTalent(player, "rouge_jinnangji") then
      if data.n > 1 then
        RougeUtil.sendTalentLog(player, "rouge_jinnangji")
        player.room:addPlayerMark(player, "rouge_jinnangji-turn", data.n // 2)
      end
    end
  end,
})

rule:addEffect(fk.TurnEnd, {
  name = "#rougelike1v1_rule_turnend",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and RougeUtil.hasOneOfTalents(player,
      { "rouge_yuanzhu1", "rouge_yuanzhu2", "rouge_yuanzhu3", "rouge_houfaxianzhi", "rouge_xvshi", "rouge_woxinchangdan" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if RougeUtil.hasTalent(player, "rouge_yuanzhu1") then
      RougeUtil.sendTalentLog(player, "rouge_yuanzhu1")
      player:drawCards(1, "rouge_yuanzhu1")
    end
    if RougeUtil.hasTalent(player, "rouge_yuanzhu2") then
      RougeUtil.sendTalentLog(player, "rouge_yuanzhu2")
      player:drawCards(2, "rouge_yuanzhu2")
    end
    if RougeUtil.hasTalent(player, "rouge_yuanzhu3") then
      RougeUtil.sendTalentLog(player, "rouge_yuanzhu3")
      player:drawCards(3, "rouge_yuanzhu3")
    end

    if RougeUtil.hasTalent(player, "rouge_houfaxianzhi") then
      RougeUtil.sendTalentLog(player, "rouge_houfaxianzhi")
      player:drawCards(3, "rouge_houfaxianzhi")
    end

    if RougeUtil.hasTalent(player, "rouge_xvshi") then
      local play_ids = {}
      player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function(e)
        if e.data.phase == Player.Play and e.end_id then
          table.insert(play_ids, { e.id, e.end_id })
        end
        return false
      end, Player.HistoryTurn)
      if #play_ids == 0 then return true end
      local function PlayCheck(e)
        local in_play = false
        for _, ids in ipairs(play_ids) do
          if e.id > ids[1] and e.id < ids[2] then
            in_play = true
            break
          end
        end
        return in_play and e.data.from == player and e.data.card.trueName == "slash"
      end
      if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, PlayCheck, Player.HistoryTurn) == 0
          and #player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, PlayCheck, Player.HistoryTurn) == 0 then
        RougeUtil.sendTalentLog(player, "rouge_xvshi")
        player.room:setPlayerMark(player, "@@rouge_xvshi", 1) -- TODO:
      else
        if player:getMark("@@rouge_xvshi") > 0 then
          player.room:removePlayerMark(player, "@@rouge_xvshi")
        end
      end
    end

    if RougeUtil.hasTalent(player, "rouge_woxinchangdan") then
      if player:getMark("@rouge_woxinchangdan") > 0 then
        room:removePlayerMark(player, "@rouge_woxinchangdan", player:getMark("@rouge_woxinchangdan"))
      end
    end
  end
})

rule:addEffect("targetmod", {
  name = "#rougelike1v1_rule_tmod",
  residue_func = function(self, player, skill, scope, card, to)
    if not card then return end
    local room = Fk:currentRoom()
    if card.trueName == "slash" and scope == Player.HistoryPhase then
      local ret = 0

      local round = room:getBanner("RoundCount")
      for i = 1, 3 do
        if hasTalent(player, "rouge_chijiuzhan" .. i) and round >= (i - 2) * i + 4 then -- 1,3 2,4 3,7 troll!
          ret = ret + 1
        end
      end

      if hasTalent(player, "rouge_erlianji") then
        ret = ret + 1
      end
      if hasTalent(player, "rouge_sanlianji") then
        ret = ret + 2
      end

      if hasTalent(player, "rouge_chijiuzhan4") and player:getMark("rouge_money") >= 3 then
        ret = ret + 1
      end

      if hasTalent(player, "rouge_qianlong") then
        if player:getMark("rougelike1v1_skill_num") > #player:getTableMark("@[rouge_skills]") then
          ret = ret + (player:getMark("rougelike1v1_skill_num") - #player:getTableMark("@[rouge_skills]")) * 2
        end
      end

      if hasTalent(player, "rouge_woxinchangdan") then
        if player:getMark("@rouge_woxinchangdan") > 0 then
          ret = ret + player:getMark("@rouge_woxinchangdan")
        end
      end
      ret = ret - #table.filter(room.alive_players, function(p)
        return RougeUtil.isEnemy(player, p) and hasTalent(p, "rouge_danliangboduo") ~= nil
      end)

      return ret
    end

    if card.trueName == "analeptic" and scope == Player.HistoryTurn then
      local ret = 0

      local round = room:getBanner("RoundCount")

      if hasTalent(player, "rouge_hugujiu") then
        ret = ret + 1
      end
      if hasTalent(player, "rouge_hugujiu2") then
        ret = ret + 2
      end

      return ret
    end
    return 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    if hasTalent(player, "rouge_guandaozhiji") then
      return card and card.trueName == "slash" and card.suit == Card.Diamond
    end

    if hasTalent(player, "rouge_miaoshoukongkong") then
      return card and card.trueName == "snatch"
    end
  end,
  bypass_times = function(self, player, skill, scope, card, to)
    if not card then return end
    if hasTalent(player, "rouge_wendingjingong") then
      return card.trueName == "slash"
    end
    if hasTalent(player, "rouge_touxi") then
      return card.trueName == "slash" and card.suit == Card.Spade
    end
  end
})
rule:addEffect(fk.PreCardUse, {
  name = "#rougelike1v1_rule_wendingjingong_counter",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "rouge_wendingjingong_slash-turn")
  end,
})
rule:addEffect("prohibit", {
  name = "#rouge_wendingjingong_prohibit",
  prohibit_use = function(self, player, card)
    if not card then return end
    if hasTalent(player, "rouge_wendingjingong") then
      return card.trueName == "slash" and player:getMark("rouge_wendingjingong_slash-turn") >= 5
    end
  end
})


rule:addEffect("maxcards", {
  name = "#rougelike1v1_rule_maxcard",
  exclude_from = function(self, player, card)
    if hasTalent(player, "rouge_cangtaohu") and card.trueName == "peach" then
      return true
    end
    if hasTalent(player, "rouge_haoshenfa") and card.trueName == "jink" then
      return true
    end
  end,
  correct_func = function(self, player)
    local ret = 0
    if hasTalent(player, "rouge_pinang1") then
      ret = ret + 1
    end
    if hasTalent(player, "rouge_pinang2") then
      ret = ret + 2
    end
    if hasTalent(player, "rouge_pinang3") then
      ret = ret + 5
    end

    if hasTalent(player, "rouge_muniuliuma") then
      ret = ret - 1
    end

    if hasTalent(player, "rouge_jinnangji") then
      ret = ret + player:getMark("rouge_jinnangji-turn")
    end

    if hasTalent(player, "rouge_chijiuzhan1") then
      if player:getMark("rouge_money") >= 3 then ret = ret + 1 end
    end
    return ret
  end,
  fixed_func = function(self, player)
    if hasTalent(player, "rouge_wendingchengzai") then
      return 8
    end
    if hasTalent(player, "rouge_xinshounianlai") then
      return player.maxHp
    end
  end
})

rule:addEffect(fk.PreHpRecover, {
  name = "#rougelike1v1_rule_prehprecover",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and RougeUtil.hasOneOfTalents(player,
      { "rouge_jiemeng", "rouge_shixue", "rouge_yaoli1", "rouge_yaoli2" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalent(player, "rouge_shixue") then
      sendTalentLog(player, "rouge_shixue")
      player:drawCards(1, "rouge_shixue")
    end

    if hasTalent(player, "rouge_yaoli1") then
      sendTalentLog(player, "rouge_yaoli1")
      data.num = data.num + 1
    end
    if hasTalent(player, "rouge_yaoli2") then
      sendTalentLog(player, "rouge_yaoli2")
      data.num = data.num + 2
    end

    if hasTalent(player, "rouge_jiemeng") and data.card and data.card.trueName == "god_salvation" then
      local use = room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if use then
        use = use.data
        if use.from and not RougeUtil.isEnemy(use.from, player) then
          sendTalentLog(player, "rouge_jiemeng")
          data.num = data.num * 2
        end
      end
    end
  end
})


rule:addEffect(fk.BeforeMaxHpChanged, {
  name = "#rougelike1v1_rule_beforemaxhpchanged",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if RougeUtil.hasOneOfTalents(player, { "rouge_wendingtizhi", }) then
      if RougeUtil.hasTalent(player, "rouge_wendingtizhi") then
        return target == player
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if RougeUtil.hasTalent(player, "rouge_wendingtizhi") then
      RougeUtil.sendTalentLog(player, "rouge_wendingtizhi")
      if data.num ~= 7 - player.maxHp then
        data.prevented = true
      end
    end
  end
})

rule:addEffect(fk.DamageCaused, {
  name = "#rougelike1v1_zhongjiji",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    return (hasTalent(player, "rouge_zhongjiji") and data.damage >= 3 and
          RougeUtil.isEnemy(data.from, data.to)) or (hasTalent(player, "rouge_kuangbao1") and player.hp <= 2)
        or (hasTalent(player, "rouge_kuangbao2") and player.hp <= 3)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local talent = hasTalent(player, "rouge_zhongjiji")
    if talent then
      sendTalentLog(player, talent)
      player:drawCards(1, talent)
    end
    local n = 0
    if hasTalent(player, "rouge_kuangbao1") and player.hp <= 2 then
      sendTalentLog(player, "rouge_kuangbao1")
      n = n + 1
    end
    if hasTalent(player, "rouge_kuangbao2") and player.hp <= 3 then
      sendTalentLog(player, "rouge_kuangbao2")
      n = n + 1
    end
    if n > 0 then
      data.damage = data.damage + n
    end
  end
})
rule:addEffect(fk.DamageCaused, {
  name = "#rougelike1v1_DamageCaused_qiaoquhaoduo",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target or data.card == nil or data.card.trueName ~= "slash" then return end
    return table.find(player.room.alive_players, function(p)
      return hasTalent(p, "rouge_qiaoquhaoduo") ~= nil
    end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from and data.from == player and data.card and data.card.trueName == "slash" then
      local gameevent = room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if gameevent and gameevent:findParent(GameEvent.CardEffect) then
        local gameevent_parent = gameevent:findParent(GameEvent.CardEffect)
        if gameevent_parent then
          local effect = gameevent_parent.data
          local useplayers = table.filter(player.room.alive_players, function(p)
            return hasTalent(p, "rouge_qiaoquhaoduo") ~= nil
          end)
          if effect.from and #useplayers > 0 and table.contains(useplayers, effect.from) then
            sendTalentLog(effect.from, "rouge_qiaoquhaoduo")
            data.damage = (data.damage or 0) + 1
          end
        end
      end
    end
  end
})


rule:addEffect(fk.DamageCaused, {
  name = "#rougelike1v1_damagecaused",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    if hasTalent(player, "rouge_yuanjiji") then
      return player:distanceTo(data.to) > 1
    elseif hasTalent(player, "rouge_xvshi") then
      return data.card and data.card.trueName == "slash"
          and player:getMark("@@rouge_xvshi") > 0 and player.room.current == player
    elseif hasTalent(player, "rouge_yuzhanyuyong1") then
      return player.room:getBanner("RoundCount") >= 3
    elseif hasTalent(player, "rouge_yuzhanyuyong2") then
      return player.room:getBanner("RoundCount") >= 5
    elseif hasTalent(player, "rouge_yuzhanyuyong3") then
      return player.room:getBanner("RoundCount") >= 7
    elseif hasTalent(player, "rouge_tijiashu") then
      return data.to.shield > 0
    elseif hasTalentStart(player, "rouge_sanbanfu") then
      return data.card and data.card.trueName == "slash" and player:getMark("@rouge_sanbanfu") % 3 == 0
    elseif hasTalent(player, "rouge_ruoxi") then
      return player:getHandcardNum() < player.hp
    elseif hasTalent(player, "rouge_miaoji1") then
      return data.card and data.card.type == Card.TypeTrick and player:getMark("rouge_miaoji1-turn") == 0
    elseif hasTalent(player, "rouge_miaoji2") then
      return data.card and data.card.type == Card.TypeTrick and player:getMark("rouge_miaoji2-turn") < 2
    elseif hasTalent(player, "rouge_leihuoshi1") or hasTalent(player, "rouge_leihuoshi2") then
      return data.card and data.card.trueName == "slash" and player:getMark("rouge_leihuoshi-turn") == 0 and
          data.damageType ~= fk.NormalDamage
    elseif hasTalent(player, "rouge_jiyi1") or hasTalent(player, "rouge_jiyi2") then
      return not data.card
    elseif hasTalent(player, "rouge_guangongren") then
      return data.card and data.card.suit == Card.Heart and data.card.trueName == "slash"
    elseif hasTalentStart(player, "rouge_dangtouyibang") then
      if data.card and data.card.trueName == "slash" then -- 每轮首张
        local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data
          return use.from == player and use.card.trueName == "slash"
        end, Player.HistoryRound)
        return #events == 1 and events[1].id == player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard).id
      end
    elseif hasTalent(player, "rouge_wendingshiqi") then
      return true
    elseif hasTalentStart(player, "rouge_jingyumoulv") then
      if data.card and data.card.trueName == "slash" then
        return #player:getCardIds("h") < 6
      end
    elseif hasTalentStart(player, "rouge_badaoshu") then
      return true
    elseif hasTalent(player, "rouge_hengfeng1") or hasTalent(player, "rouge_hengfeng2") then
      return player.room.current == player and #player.room.logic:getActualDamageEvents(1, function(e) return e.data.from == player end) == 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if hasTalent(player, "rouge_wendingshiqi") then
      data.damage = 2 -- TODO: 固定？
      return false
    end

    local room = player.room
    local n = 0
    local function addDamage(talent, num)
      sendTalentLog(player, talent)
      n = n + (num or 1)
    end
    if hasTalent(player, "rouge_yuanjiji") and player:distanceTo(data.to) > 1 then
      addDamage("rouge_yuanjiji")
    end
    if hasTalent(player, "rouge_xvshi") and data.card and data.card.trueName == "slash"
        and player:getMark("@@rouge_xvshi") > 0 and room.current == player then
      addDamage("rouge_xvshi")
    end
    if hasTalentStart(player, "rouge_sanbanfu") and data.card and data.card.trueName == "slash" and player:getMark("@rouge_sanbanfu") % 3 == 0 then
      if hasTalent(player, "rouge_sanbanfu1") then
        addDamage("rouge_sanbanfu1")
      end
      if hasTalent(player, "rouge_sanbanfu2") then
        addDamage("rouge_sanbanfu2", 2)
      end
    end
    if hasTalent(player, "rouge_ruoxi") and player:getHandcardNum() < player.hp then
      addDamage("rouge_ruoxi")
    end
    if hasTalent(player, "rouge_miaoji1") and data.card and data.card.type == Card.TypeTrick and player:getMark("rouge_miaoji1-turn") == 0 then
      room:addPlayerMark(player, "rouge_miaoji1-turn", 1)
      addDamage("rouge_miaoji1")
    end
    if hasTalent(player, "rouge_miaoji2") and data.card and data.card.type == Card.TypeTrick and player:getMark("rouge_miaoji2-turn") == 0 then
      room:addPlayerMark(player, "rouge_miaoji2-turn", 1)
      addDamage("rouge_miaoji2")
    end
    if (hasTalentStart(player, "rouge_leihuoshi")) and data.card and data.card.trueName == "slash"
        and player:getMark("rouge_leihuoshi-turn") == 0 and data.damageType ~= fk.NormalDamage then
      room:addPlayerMark(player, "rouge_leihuoshi-turn", 1)
      if hasTalent(player, "rouge_leihuoshi1") then
        addDamage("rouge_leihuoshi1")
      end
      if hasTalent(player, "rouge_leihuoshi2") then
        addDamage("rouge_leihuoshi2", 2)
      end
    end
    if hasTalent(player, "rouge_jiyi1") and not data.card then
      addDamage("rouge_jiyi1")
    end
    if hasTalent(player, "rouge_jiyi2") and not data.card then
      addDamage("rouge_jiyi2", 2)
    end
    if hasTalent(player, "rouge_guangongren") and data.card and
        data.card.suit == Card.Heart and data.card.trueName == "slash" then
      addDamage("rouge_guangongren")
    end
    if hasTalentStart(player, "rouge_dangtouyibang") then
      if data.card and data.card.trueName == "slash" then -- 每轮首张
        local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data
          return use.from == player and use.card.trueName == "slash"
        end, Player.HistoryRound)
        if #events == 1 and events[1].id == player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard).id then
          if hasTalent(player, "rouge_dangtouyibang1") then
            addDamage("rouge_dangtouyibang1")
          end
          if hasTalent(player, "rouge_dangtouyibang2") then
            addDamage("rouge_dangtouyibang2", 2)
          end
        end
      end
    end
    for i = 1, 3 do
      local t = hasTalent(player, "rouge_yuzhanyuyong" .. i)
      if t and room:getBanner("RoundCount") >= i * 2 + 1 then
        addDamage(t)
      end
    end
    if hasTalent(player, "rouge_tijiashu") then
      sendTalentLog(player, "rouge_tijiashu")
      n = n * 2
    end

    if hasTalentStart(player, "rouge_jingyumoulv") then
      for i = 1, 2 do
        local t = hasTalent(player, "rouge_jingyumoulv" .. i)
        if t and #player:getCardIds("h") < 2 * (i + 1) then
          addDamage(t)
        end
      end
    end

    if hasTalentStart(player, "rouge_badaoshu") then
      local roundEvents = room.logic:getEventsByRule(GameEvent.Round, 2, Util.TrueFunc, 0)
      if #roundEvents == 2 then
        local damage_num = 0
        local damageEvent_num = #room.logic:getEventsByRule(GameEvent.Damage, 3, function(e)
          if e.id > roundEvents[1].id then return false end
          local use = e.data
          if use.from == player then
            damage_num = damage_num + use.damage
          end
        end, roundEvents[2].id)
        if hasTalent(player, "rouge_badaoshu1") and damage_num == 0 then
          addDamage("rouge_badaoshu1", 1)
        end
        if hasTalent(player, "rouge_badaoshu2") and damage_num < 3 then
          addDamage("rouge_badaoshu2", 1)
        end
      end
    end

    if hasTalentStart(player, "rouge_hengfeng") then
      if player.room.current == player and #player.room.logic:getActualDamageEvents(1, function(e) return e.data.from == player end) == 0 then
        if hasTalent(player, "rouge_hengfeng1") then
          addDamage("rouge_hengfeng1", 1)
        end
        if hasTalent(player, "rouge_hengfeng2") then
          addDamage("rouge_hengfeng2", 2)
        end
      end
    end

    if n > 0 then
      data.damage = data.damage + n
    end
  end,


})
rule:addEffect(fk.CardUsing, {
  priority = 0.002,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and hasTalentStart(player, "rouge_sanbanfu") -- 不考虑失去的情况
        and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@rouge_sanbanfu", 1)
  end,
})


rule:addEffect(fk.BeforeHpChanged, {
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target ~= player and data.damageEvent and data.damageEvent.from and data.damageEvent.from == player and
        hasTalent(player, "rouge_geshandaniu")
        and target and target.shield > 0 and data.shield_lost and data.shield_lost > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if hasTalent(player, "rouge_geshandaniu") and target.shield > 0 then
      sendTalentLog(player, "rouge_geshandaniu")
      data.num = data.num - data.shield_lost
      data.shield_lost = 0
    end
  end
})


rule:addEffect(fk.Damage, {
  name = "#rougelike1v1_damage",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    local room = player.room
    if hasTalentStart(player, "rouge_cedingtianxia") then
      return data.card and data.card.type == Card.TypeTrick and player.phase == Player.Play
    end
    if hasTalentStart(player, "rouge_cuixue") then
      if data.card and data.card.trueName == "slash" then
        local events = player.room.logic:getActualDamageEvents(2, function(e)
          return e.data.from == player and e.data.card ~= nil and e.data.card.trueName == "slash"
        end, Player.HistoryRound)
        return #events <= 1
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalentStart(player, "rouge_cedingtianxia") then
      for i = 1, 2 do
        if player:getMark("rouge_cedingtianxia" .. i .. "-phase") == 0 and hasTalent(player, "rouge_cedingtianxia" .. i) then
          sendTalentLog(player, "rouge_cedingtianxia" .. i)
          player:drawCards(i, "rouge_cedingtianxia" .. i)
          room:addPlayerMark(player, "rouge_cedingtianxia" .. i .. "-phase")
        end
      end
    end
    if hasTalentStart(player, "rouge_cuixue") then
      if data.card and data.card.trueName == "slash" then -- 每轮首张
        local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data
          return use.from == player and use.card.trueName == "slash"
        end, Player.HistoryRound)
        if #events == 1 and events[1].id == player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard).id then
          if hasTalent(player, "rouge_cuixue1") then
            sendTalentLog(player, "rouge_cuixue1")
            player:drawCards(1, "rouge_cuixue1")
          end
          if hasTalent(player, "rouge_cuixue2") then
            sendTalentLog(player, "rouge_cuixue2")
            player:drawCards(2, "rouge_cuixue2")
          end
        end
      end
    end
  end,

})

rule:addEffect(fk.PreCardUse, {
  name = "#rougelike1v1_PreCardUse",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not data.card then return end
    return RougeUtil.hasOneOfTalents(player, { "rouge_jueduiwuxie" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalent(player, "rouge_jueduiwuxie") then
      if data.card.trueName == "nullification" then
        sendTalentLog(player, "rouge_jueduiwuxie")
        data.disresponsiveList =
            table.connect(data.disresponsiveList or {}, room:getOtherPlayers(player, false))
      end
    end
  end
})


rule:addEffect(fk.AfterCardTargetDeclared, {
  name = "#rougelike1v1_AfterCardTargetDeclared",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and (hasTalent(player, "rouge_zuiquan") or hasTalentStart(player, "rouge_shuangren"))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalent(player, "rouge_zuiquan") then
      if data.card and data.card.trueName == "slash" and ((data.extra_data or {}).drankBuff or 0) > 0 then
        sendTalentLog(player, "rouge_zuiquan")
        data.unoffsetableList = room.alive_players
      end
    end
    if hasTalentStart(player, "rouge_shuangren") and
        data.card.trueName == "slash" and #player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
          return e.data.card and e.data.card.trueName == "slash" and data.from == player
        end, Player.HistoryRound) == 1 then
      local targets = table.filter(data:getExtraTargets(),
        function(p) return player:inMyAttackRange(p) end)
      if #targets > 0 then
        local n = 0
        if hasTalent(player, "rouge_shuangren1") then
          sendTalentLog(player, "rouge_shuangren1")
          n = 1
        end
        if hasTalent(player, "rouge_shuangren2") then
          sendTalentLog(player, "rouge_shuangren2")
          n = n + 2
        end
        local tos = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = n,
          prompt = "#rouge_shuangren-choose:::" .. n,
          skill_name = "rouge_shuangren" .. n,
          cancelable = true,
        })
        if #tos > 0 then
          data:addTarget(tos)
        end
      end
    end

    if hasTalent(player, "rouge_hengjiangsuo") then
      if data.card.trueName == "iron_chain" then
        local targets = {}
        for _, p in ipairs(room.alive_players) do
          if not table.contains(data.tos, p) and not player:isProhibited(p, data.card) then
            table.insertIfNeed(targets, p)
          end
        end
        if #targets > 0 then
          sendTalentLog(player, "rouge_hengjiangsuo")
          local tos = room:askToChoosePlayers(player, {
            targets = targets,
            min_num = 0,
            max_num = #targets,
            prompt = "#rouge_hengjiangsuo-choose",
            skill_name = "rouge_hengjiangsuo",
            cancelable = true,
          })
          if #tos > 0 then
            data:addTarget(tos)
          end
        end
      end
    end
  end
})


rule:addEffect(fk.PreCardEffect, {
  name = "#rougelike1v1_PreCardEffect_yinyangshufa",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    if RougeUtil.hasOneOfTalents(player, { "rouge_yinyangshufa" }) and data.card then
      if hasTalent(player, "rouge_yinyangshufa") and data.card.type == Card.TypeTrick and data.card.is_damage_card == true then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalent(player, "rouge_yinyangshufa") then
      sendTalentLog(player, "rouge_yinyangshufa")
      for _, to in ipairs(data.tos) do
        if RougeUtil.isEnemy(player, to) then
          data.disresponsiveList = data.disresponsiveList or {}
          table.insertIfNeed(data.disresponsiveList, to)
        end
      end
    end
  end
})

rule:addEffect(fk.TargetConfirming, {
  name = "#rougelike1v1_TargetConfirming",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    if RougeUtil.hasOneOfTalents(player, { "rouge_yingjifangan", "rouge_yingjizhanshu", "rouge_yingjizhanlv" })
        and data.card and data.from and not data.from:isNude() and
        #data:getAllTargets() == 1 and
        player.phase == Player.NotActive and RougeUtil.isEnemy(player, data.from) then
      if hasTalent(player, "rouge_yingjifangan") then
        return data.card.type == Card.TypeBasic
      elseif hasTalent(player, "rouge_yingjizhanshu") then
        return data.card.type == Card.TypeTrick
      elseif hasTalent(player, "rouge_yingjizhanlv") then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if RougeUtil.hasOneOfTalents(player, { "rouge_yingjifangan", "rouge_yingjizhanshu", "rouge_yingjizhanlv" }) then
      local skilName = ""
      local targetPlayer = data.from
      if hasTalent(player, "rouge_yingjifangan") and not targetPlayer:isNude() then
        skilName = "rouge_yingjifangan"
        sendTalentLog(player, skilName)
        room:throwCard(room:tableRandomPick(targetPlayer:getCardIds("he")), skilName, targetPlayer, player)
      end
      if hasTalent(player, "rouge_yingjizhanshu") and not targetPlayer:isNude() then
        skilName = "rouge_yingjizhanshu"
        sendTalentLog(player, skilName)
        room:throwCard(room:tableRandomPick(targetPlayer:getCardIds("he")), skilName, targetPlayer, player)
      end
      if hasTalent(player, "rouge_yingjizhanlv") and not targetPlayer:isNude() then
        skilName = "rouge_yingjizhanlv"
        sendTalentLog(player, skilName)
        room:throwCard(room:tableRandomPick(targetPlayer:getCardIds("he")), skilName, targetPlayer, player)
      end
    end
  end
})


rule:addEffect(fk.TargetSpecified, {
  name = "#rougelike1v1_targetspecified",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    if RougeUtil.hasOneOfTalents(player, { "rouge_hanzhan" }) and data.card then
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalent(player, "rouge_hanzhan") then
      if data.card.trueName == "duel" then
        sendTalentLog(player, "rouge_hanzhan")
        data:setResponseTimes(2, data.to)
      end
    end
  end
})


rule:addEffect(fk.CardUseFinished, {
  name = "#rougelike1v1_CardUseFinished",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    return RougeUtil.hasOneOfTalents(player, { "rouge_zhudao1", "rouge_zhudao2", "rouge_shoudaoqinlai1",
      "rouge_shoudaoqinlai2", "rouge_shoudaoqinlai3", "rouge_caochuanjiejian" }) and data.card
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room

    if hasTalent(player, "rouge_zhudao1") then
      if data.card.trueName == "slash" and not player:isNude() then
        sendTalentLog(player, "rouge_zhudao1")
        local choice_cards = room:askToCards(player, {
          max_num = 1,
          min_num = 1,
          skill_name = "rouge_zhudao1",
          cancelable = true,
          pattern = ".",
          prompt = "#rouge_zhudao:::" .. 1,
          include_equip = true,
        })
        room:recastCard(choice_cards, player, "rouge_zhudao1")
      end
    end

    if hasTalent(player, "rouge_zhudao2") then
      if data.card.trueName == "slash" and not player:isNude() then
        sendTalentLog(player, "rouge_zhudao2")
        local choice_cards = room:askToCards(player, {
          max_num = 2,
          min_num = 1,
          skill_name = "rouge_zhudao2",
          cancelable = true,
          pattern = ".",
          prompt = "#rouge_zhudao:::" .. 2,
          include_equip = true,
        })
        room:recastCard(choice_cards, player, "rouge_zhudao2")
      end
    end
    if hasTalent(player, "rouge_caochuanjiejian") then
      if data.card and data.card.trueName == "nullification" and data.responseToEvent and
          data.toCard and room:getCardArea(data.toCard) == Card.Processing then
        sendTalentLog(player, "rouge_caochuanjiejian")
        room:obtainCard(player, data.toCard, true, fk.ReasonJustMove)
      end
    end
    if hasTalent(player, "rouge_shoudaoqinlai1") then
      if #room.logic:getEventsOfScope(GameEvent.UseCard, 7, function(e)
            return e.data.card and e.data.from == player
          end, Player.HistoryTurn) == 7 and player:getMark("rouge_shoudaoqinlai1-turn") == 0 then
        sendTalentLog(player, "rouge_shoudaoqinlai1")
        player:drawCards(1, "rouge_shoudaoqinlai1")
        room:addPlayerMark(player, "rouge_shoudaoqinlai1-turn")
      end
    end
    if hasTalent(player, "rouge_shoudaoqinlai2") then
      if #room.logic:getEventsOfScope(GameEvent.UseCard, 5, function(e)
            return e.data.card and e.data.from == player
          end, Player.HistoryTurn) == 5 and player:getMark("rouge_shoudaoqinlai2-turn") == 0 then
        sendTalentLog(player, "rouge_shoudaoqinlai2")
        player:drawCards(1, "rouge_shoudaoqinlai2")
        room:addPlayerMark(player, "rouge_shoudaoqinlai2-turn")
      end
    end
    if hasTalent(player, "rouge_shoudaoqinlai2") then
      if #room.logic:getEventsOfScope(GameEvent.UseCard, 6, function(e)
            return e.data.card and e.data.from == player
          end, Player.HistoryTurn) == 6 and player:getMark("rouge_shoudaoqinlai3-turn") == 0 then
        sendTalentLog(player, "rouge_shoudaoqinlai3")
        player:drawCards(2, "rouge_shoudaoqinlai3")
        room:addPlayerMark(player, "rouge_shoudaoqinlai3-turn")
      end
    end
  end
})


rule:addEffect(fk.CardEffecting, {
  name = "#rougelike1v1_CardEffecting",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target and RougeUtil.hasOneOfTalents(player, { "rouge_fengshounian" }) and data.card then
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local user = data.from
    if user and hasTalent(user, "rouge_fengshounian") then
      if RougeUtil.isEnemy(user, target) and data.card.trueName == "amazing_grace" then
        sendTalentLog(user, "rouge_fengshounian")
        data:setNullified(target)
      end
    end
  end
})


rule:addEffect(fk.PreCardEffect, {
  name = "#rougelike1v1_precardEffect",
  mute = true,
  priority = 0.002,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    return RougeUtil.hasOneOfTalents(player, { "rouge_xvyan", "rouge_chenqibubei1", "rouge_chenqibubei2",
      "rouge_xvlijian" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local cardskill = data.card.skill.name
    local room = player.room
    if hasTalent(player, "rouge_xvyan") then
      if data.from == player and data.card.trueName == "fire_attack" then
        sendTalentLog(player, "rouge_xvyan")
        cardskill = "rouge_xvyan__fire_attack_skill"
      end
    end
    if hasTalentStart(player, "rouge_chenqibubei") then
      if data.from == player and data.card.trueName == "dismantlement" then
        local Talent_name = ""
        if hasTalent(player, "rouge_chenqibubei1") then
          Talent_name = "rouge_chenqibubei1"
        end
        if hasTalent(player, "rouge_chenqibubei2") then
          Talent_name = "rouge_chenqibubei2"
        end
        sendTalentLog(player, Talent_name)
        cardskill = "chenqibubei_dismantlement_skill"
      end
    end
    if hasTalent(player, "rouge_xvlijian") then
      if data.from == player and data.card.trueName == "archery_attack" then
        sendTalentLog(player, "rouge_xvlijian")
        cardskill = "rouge_xvlijian__archery_attack_skill"
      end
    end

    data:changeCardSkill(cardskill)
  end,
})

rule:addEffect(fk.AfterDying, {
  name = "#rougelike1v1_AfterDying",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and hasTalentStart(player, "rouge_yongzhan")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 1
    local skillName = "rouge_yongzhan1"
    if hasTalent(player, "rouge_yongzhan2") then
      skillName = "rouge_yongzhan2"
      num = 2
    end
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if RougeUtil.isEnemy(player, p) then
        sendTalentLog(player, skillName)
        room:damage({
          from = player,
          to = p,
          damage = num,
          skillName = skillName
        })
      end
    end
  end
})

rule:addEffect(fk.DamageInflicted, {
  name = "#rougelike1v1_DamageInflicted",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    if RougeUtil.hasOneOfTalents(player, { "rouge_houshi1", "rouge_houshi2" }) then
      return true
    elseif RougeUtil.hasOneOfTalents(player, { "rouge_hengfeng1", "rouge_hengfeng2" }) then
      return player.room.current ~= player and player:getMark("rouge_hengfeng") == 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalent(player, "rouge_houshi1") then
      if player:getMark("rouge_houshi1-round") == 0 then
        sendTalentLog(player, "rouge_houshi1")
        room:addPlayerMark(player, "rouge_houshi1-round")
        data.damage = data.damage - 1
        data.damage = data.damage < 0 and 0 or data.damage
      end
    end
    if hasTalent(player, "rouge_houshi2") then
      if player:getMark("rouge_houshi2-round") < 2 then
        room:addPlayerMark(player, "rouge_houshi2-round")
        sendTalentLog(player, "rouge_houshi2")
        data.damage = data.damage - 1
        data.damage = data.damage < 0 and 0 or data.damage
      end
    end
    if hasTalentStart(player, "rouge_hengfeng") and player:getMark("rouge_hengfeng") == 0 then
      if hasTalent(player, "rouge_hengfeng1") then
        sendTalentLog(player, "rouge_hengfeng1")
        data.damage = data.damage + 1
        data.damage = data.damage < 0 and 0 or data.damage
      end
      if hasTalent(player, "rouge_hengfeng2") then
        sendTalentLog(player, "rouge_hengfeng2")
        data.damage = data.damage + 2
        data.damage = data.damage < 0 and 0 or data.damage
      end
      room:setPlayerMark(player, "rouge_hengfeng", 1)
    end
  end
})

rule:addEffect(fk.Damaged, {
  name = "#rougelike1v1_Damaged",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    return RougeUtil.hasOneOfTalents(player, {
      "rouge_fanci", "rouge_jingjijia", "rouge_pianzhuanjia", "rouge_pofuchenzhou",
      "rouge_xialuxiangfeng", "rouge_woxinchangdan" })
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalent(player, "rouge_fanci") then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      local events = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == player
      end, Player.HistoryTurn)
      if #events == 1 and events[1].data == data then
        sendTalentLog(player, "rouge_fanci")
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if RougeUtil.isEnemy(player, p) and p:isAlive() then
            room:damage {
              from = player,
              to = p,
              damage = 1,
              skillName = "rouge_fanci"
            }
          end
        end
      end
    end
    if hasTalent(player, "rouge_jingjijia") then
      if data.from and data.from:isAlive() then
        sendTalentLog(player, "rouge_jingjijia")
        room:damage {
          from = player,
          to = data.from,
          damage = 1,
          skillName = "rouge_jingjijia"
        }
      end
    end
    if hasTalent(player, "rouge_pianzhuanjia") then
      local enemies = table.filter(room.alive_players, function(p) return RougeUtil.isEnemy(player, p) end)
      if #enemies ~= 0 then
        sendTalentLog(player, "rouge_pianzhuanjia")
        room:damage {
          from = player,
          to = room:tableRandomPick(enemies),
          damage = 1,
          skillName = "rouge_pianzhuanjia"
        }
      end
    end
    if hasTalent(player, "rouge_pofuchenzhou") then
      if room.current ~= player and data.from and data.from:isAlive() and
          data.damage >= 3 then
        sendTalentLog(player, "rouge_pofuchenzhou")
        room:damage {
          from = player,
          to = data.from,
          damage = data.damage,
          damageType = data.damageType,
          skillName = "rouge_pofuchenzhou"
        }
      end
    end
    if hasTalent(player, "rouge_xialuxiangfeng") then
      if data.card and data.card.trueName == "duel" then
        sendTalentLog(player, "rouge_xialuxiangfeng")
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = "rouge_xialuxiangfeng"
        })
      end
    end
    if hasTalent(player, "rouge_woxinchangdan") then
      if room.current ~= player then
        sendTalentLog(player, "rouge_woxinchangdan")
        room:addPlayerMark(player, "@rouge_woxinchangdan", 1)
      end
    end
  end
})

rule:addEffect(fk.Damaged, {
  name = "#rougelike1v1_Damaged_perpoint",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and hasTalent(player, "rouge_ruofankui")
  end,
  on_trigger = function(self, event, target, player, data)
    for _ = 1, data.damage do
      if player.dead then break end -- 不考虑失去的情况
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    sendTalentLog(player, "rouge_ruofankui")
    player:drawCards(1, "rouge_ruofankui")
  end
})


rule:addEffect(fk.BeforeCardsMove, {
  name = "#rougelike1v1_BeforeCardsMove",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if hasTalent(player, "rouge_laoguzhuangbei") then
      if #player:getCardIds("e") > 0 then
        for _, move in ipairs(data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard and move.proposer ~= player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalent(player, "rouge_laoguzhuangbei") then
      sendTalentLog(player, "rouge_laoguzhuangbei")
      local ids = {}
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard and move.proposer ~= player then
          local move_info = {}
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if info.fromArea == Card.PlayerEquip then
              table.insert(ids, id)
            else
              table.insert(move_info, info)
            end
          end
          if #ids > 0 then
            move.moveInfo = move_info
          end
        end
      end
      if #ids > 0 then
        player.room:sendLog {
          type = "#cancelDismantle",
          card = ids,
          arg = "rouge_laoguzhuangbei",
        }
      end
    end
  end
})


rule:addEffect(fk.AfterCardsMove, {
  name = "#rougelike1v1_AfterCardsMove",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if hasTalentStart(player, "rouge_shenlongbaiwei") or hasTalentStart(player, "rouge_duoduoyishan") then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand and move.moveReason == fk.ReasonDraw then
          return true
        end
      end
    end
    if hasTalent(player, "rouge_jishiyu") then
      if not player:isKongcheng() or player.phase ~= Player.NotActive then return end
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalentStart(player, "rouge_shenlongbaiwei") then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand and move.moveReason == fk.ReasonDraw then
          for i = 1, 2 do
            if hasTalent(player, "rouge_shenlongbaiwei" .. i) then
              room:addPlayerMark(player, "@rouge_shenlongbaiwei" .. i, #move.moveInfo)
              local n = 12 - 3 * i
              if player:getMark("@rouge_shenlongbaiwei" .. i) >= n then
                sendTalentLog(player, "rouge_shenlongbaiwei" .. i)
                local num = player:getMark("@rouge_shenlongbaiwei" .. i) // n
                room:removePlayerMark(player, "@rouge_shenlongbaiwei" .. i, num * n)
                for _ = 1, num do
                  local enemys = table.filter(room:getOtherPlayers(player, false), function(p)
                    return RougeUtil.isEnemy(player, p)
                  end)
                  if #enemys > 0 then
                    local targetPlayer = room:tableRandomPick(enemys)
                    room:damage({
                      from = player,
                      to = targetPlayer,
                      damage = 1,
                      skillName = "rouge_shenlongbaiwei" .. i,
                    })
                  end
                end
              end
            end
          end
        end
      end
    end

    if hasTalentStart(player, "rouge_duoduoyishan") then
      local nums, draws = { 5, 3, 3 }, { 1, 1, 2 }
      for i = 1, 3 do
        if hasTalent(player, "rouge_duoduoyishan" .. i) and player:getMark("rouge_duoduoyishan" .. i .. "-turn") == 0 then
          for _, move in ipairs(data) do
            if move.to == player and move.toArea == Card.PlayerHand and move.moveReason == fk.ReasonDraw then
              room:addPlayerMark(player, "@rouge_duoduoyishan" .. i .. "-turn")
              if player:getMark("@rouge_duoduoyishan" .. i .. "-turn") / nums[i] >= 1 then
                sendTalentLog(player, "rouge_duoduoyishan" .. i)
                room:addPlayerMark(player, "rouge_duoduoyishan" .. i .. "-turn")
                player:drawCards(draws[i], "rouge_duoduoyishan" .. i)
              end
              break
            end
          end
        end
      end
    end

    if RougeUtil.hasTalent(player, "rouge_jishiyu") and not player.dead then
      if not player:isKongcheng() or player.phase ~= Player.NotActive then return end
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              sendTalentLog(player, "rouge_jishiyu")
              player:drawCards(2, "rouge_jishiyu")
            end
          end
        end
      end
    end
  end
})


rule:addEffect("visibility", {
  name = "#rougelike1v1_Visibility",
  mute = true,
  card_visible = function(self, player, card)
    if (hasTalent(player, "rouge_yanxian") or hasTalent(player, "rouge_qiangquhaoduo")) and card:getMark("@rouge_yanxian") > 0 then
      return true
    end
  end
})

rule:addEffect(fk.PreCardEffect, {
  name = "#rougelike1v1_PreEffect_Visibility",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target then return end
    if hasTalent(player, "rouge_yanxian") then
      return data.card and data.card.trueName == "dismantlement"
    elseif hasTalent(player, "rouge_qiangquhaoduo") then
      return data.card and data.card.trueName == "snatch"
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, to in ipairs(data.tos) do
      local targetPlayer = to
      if targetPlayer:isKongcheng() then return end
      if data.card.trueName == "snatch" then
        sendTalentLog(player, "rouge_qiangquhaoduo")
      else
        sendTalentLog(player, "rouge_yanxian")
      end
      for _, cid in ipairs(targetPlayer:getCardIds("h")) do
        local card_true = Fk:getCardById(cid)
        room:setCardMark(card_true, "@rouge_yanxian", 1)
      end
    end
  end
})

rule:addEffect(fk.CardEffectFinished, {
  name = "#rouge_yanxian_effectfinished",
  priority = 0.002,
  mute = true,
  global = true,
  can_trigger = function(self, event, target, player, data)
    return data.card and (data.card.trueName == "dismantlement" or data.card.trueName == "snatch") and
        not player:isKongcheng()
        and table.find(player:getCardIds("h"), function(cid)
          return Fk:getCardById(cid):getMark("@rouge_yanxian") > 0
        end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, cid in ipairs(player:getCardIds("h")) do
      local card_true = Fk:getCardById(cid)
      room:removeCardMark(card_true, "@rouge_yanxian", card_true:getMark("@rouge_yanxian"))
    end
  end
})

rule:addEffect(fk.PindianCardsDisplayed, {
  name = "#rougelike1v1_dushu",
  priority = 0.002,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if hasTalentStart(player, "rouge_dushu") then
      return data.from == player or table.contains(data.tos, player)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasTalent(player, "rouge_dushu1") then
      room:changePindianNumber(data, player, 3, "rouge_dushu1")
    end
    if hasTalent(player, "rouge_dushu2") then
      room:changePindianNumber(data, player, 6, "rouge_dushu2")
    end
  end
})


return rule
