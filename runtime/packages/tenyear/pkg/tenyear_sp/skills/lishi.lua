local lishi = fk.CreateSkill {
  name = "lishi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["lishi"] = "立世",
  [":lishi"] = "锁定技，结束阶段，若你没有“凛”，你受到1点雷电伤害；若你有“凛”，你失去任意个“凛”并选择等量选项令所有其他角色执行：<br>"..
    "1.下个准备和结束阶段非锁定技失效；<br>"..
    "2.下个判定阶段在【闪电】、【乐不思蜀】和【兵粮寸断】中选择两个并依次进行判定；<br>"..
    "3.下个摸牌阶段摸到的牌若颜色相同，则全部弃置；<br>"..
    "4.下个出牌阶段每种类型的手牌仅能使用一张；<br>"..
    "5.下个弃牌阶段弃置的牌改为被你获得。",

  ["#lishi-choice"] = "立世：选择至多%arg项，移去等量“凛”，令所有其他角色下个阶段执行对应效果",
  ["lishi_start"] = "准备阶段和结束阶段：非锁定技失效",
  ["lishi_judge"] = "判定阶段：选择两种延时锦囊进行判定",
  ["lishi_draw"] = "摸牌阶段：摸到的牌颜色相同则弃置",
  ["lishi_play"] = "出牌阶段：每种类别手牌只能使用一张",
  ["lishi_discard"] = "弃牌阶段：你获得其弃置的牌",
  ["@lishi"] = "立世",
  ["#lishi_judge-choice"] = "立世：请选择两种延时锦囊进行判定",

  ["$lishi1"] = "天时未到？可花时已到！",
  ["$lishi2"] = "我于九州洗砚，如何不染人间？",
}

local function setLishiMark(player)
  local mark = player:getTableMark(lishi.name)
  player.room:setPlayerMark(player, "@lishi", #mark > 0 and table.concat(table.map(mark, function(choice)
    return Fk:translate("lishi_"..choice)[1]
  end), "") or 0)
end

lishi:addEffect(fk.EventPhaseStart, {
  --priority = 2,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lishi.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(lishi.name)
    if player:getMark("@zhonghui_piercing") == 0 then
      room:notifySkillInvoked(player, lishi.name, "negative")
      room:damage{
        from = player,
        to = player,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = lishi.name,
      }
    else
      local phases = {"start", "judge", "draw", "play", "discard"}
      local choices = room:askToChoices(player, {
        choices = table.map(phases, function(phase)
          return "lishi_"..phase
        end),
        min_num = 1,
        max_num = player:getMark("@zhonghui_piercing"),
        skill_name = lishi.name,
        prompt = "#lishi-choice:::"..player:getMark("@zhonghui_piercing"),
        cancelable = false,
      })
      room:removePlayerMark(player, "@zhonghui_piercing", #choices)
      choices = table.map(choices, function(choice)
        return string.split(choice, "_")[2]
      end)
      room:notifySkillInvoked(player, lishi.name, "offensive", room:getOtherPlayers(player))
      room:doIndicate(player, room:getOtherPlayers(player, false))
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        local mark = p:getTableMark(lishi.name)
        table.insertTableIfNeed(mark, choices)
        room:setPlayerMark(p, lishi.name, mark)
        if table.contains(choices, "start") then
          room:setPlayerMark(p, "lishi_start", {"start", "finish"})
        end
        if table.contains(choices, "discard") then
          room:setPlayerMark(p, "lishi_discard", player)
        end
        setLishiMark(p)
      end
    end
  end,
})

--线上，每次立世发动时覆盖标记，回合结束时会清除标记，只对第一个阶段生效
lishi:addEffect(fk.EventPhaseEnd, {
  late_refresh = true,
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local mark = player:getTableMark("lishi_start")
      if table.removeOne(mark, "start") then
        if #mark == 0 then
          room:setPlayerMark(player, "lishi_start", 0)
          room:removeTableMark(player, lishi.name, "start")
          setLishiMark(player)
        else
          room:setPlayerMark(player, "lishi_start", mark)
        end
      end
    elseif player.phase == Player.Judge then
      if room:removeTableMark(player, lishi.name, "judge") then
        setLishiMark(player)
      end
    elseif player.phase == Player.Draw then
      if room:removeTableMark(player, lishi.name, "draw") then
        setLishiMark(player)
      end
    elseif player.phase == Player.Play then
      if room:removeTableMark(player, lishi.name, "play") then
        setLishiMark(player)
      end
    elseif player.phase == Player.Discard then
      if room:removeTableMark(player, lishi.name, "discard") then
        room:setPlayerMark(player, "lishi_discard", 0)
        setLishiMark(player)
      end
    elseif player.phase == Player.Finish then
      local mark = player:getTableMark("lishi_start")
      if table.removeOne(mark, "finish") then
        if #mark == 0 then
          room:setPlayerMark(player, "lishi_start", 0)
          room:removeTableMark(player, lishi.name, "start")
          setLishiMark(player)
        else
          room:setPlayerMark(player, "lishi_start", mark)
        end
      end
    end
  end
})

lishi:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Judge and table.contains(player:getTableMark(lishi.name), "judge")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = room:askToChoices(player, {
      choices = {"lightning", "indulgence", "supply_shortage"},
      min_num = 2,
      max_num = 2,
      skill_name = lishi.name,
      prompt = "#lishi_judge-choice",
      cancelable = false,
    })
    --按点击选项的顺序依次判定
    for _, name in ipairs(choices) do
      if name == "lightning" then
        local judge = {
          who = player,
          reason = "lightning",
          pattern = ".|2~9|spade",
        }
        room:judge(judge)
        if judge:matchPattern() and not player.dead then
          room:damage{
            to = player,
            damage = 3,
            damageType = Fk:getDamageNature(fk.ThunderDamage) and fk.ThunderDamage or fk.NormalDamage,
            skillName = "lightning_skill",
          }
        end
      elseif name == "indulgence" then
        local judge = {
          who = player,
          reason = "indulgence",
          pattern = ".|.|spade,club,diamond",
        }
        room:judge(judge)
        if judge:matchPattern() and not player.dead then
          player:skip(Player.Play)
        end
      elseif name == "supply_shortage" then
        local judge = {
          who = player,
          reason = "supply_shortage",
          pattern = ".|.|spade,heart,diamond",
        }
        room:judge(judge)
        if judge:matchPattern() and not player.dead then
          player:skip(Player.Draw)
        end
      end
    end
  end,
})

lishi:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    if not skill:hasTag(Skill.Compulsory) and skill:isPlayerSkill(from) then
      if from.phase == Player.Start then
        return table.contains(from:getTableMark("lishi_start"), "start")
      elseif from.phase == Player.Finish then
        return table.contains(from:getTableMark("lishi_start"), "finish")
      end
    end
  end
})

--只限制对于手牌的使用
lishi:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and
      table.contains(player:getTableMark(lishi.name), "play") and
      data:isUsingHandcard(player)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "lishi_play_record-phase", data.card.type)
  end,
})

--只限制对于手牌的使用
lishi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if card and table.contains(player:getTableMark("lishi_play_record-phase"), card.type) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and
        table.every(subcards, function(id)
          return table.contains(player:getCardIds("h"), id)
        end)
    end
  end,
})

--当你于摸牌阶段内因摸牌而得到牌后，若这些牌颜色相同，你弃置这些牌
lishi:addEffect(fk.AfterCardsMove, {
  anim_type = "negative",
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if table.contains(player:getTableMark(lishi.name), "draw") and player.phase == Player.Draw then
      local cards = {}
      local color
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand and move.moveReason == fk.ReasonDraw then
          for _, info in ipairs(move.moveInfo) do
            --待定：无色？小乔？
            if color == nil then
              color = Fk:getCardById(info.cardId).color
            elseif color ~= Fk:getCardById(info.cardId).color then
              return false
            end
            table.insert(cards, info.cardId)
          end
        end
      end
      if #cards > 0 then
        event:setCostData(self, { cards = cards })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local handcards = player:getCardIds("h")
    local cards = table.filter(event:getCostData(self).cards, function(id)
      return table.contains(handcards, id) and not player:prohibitDiscard(id)
    end)
    if #cards > 0 then
      player.room:throwCard(cards, lishi.name, player, player)
    end
  end,
})

--当你于弃牌阶段因游戏规则而弃置牌前，你防止此移动，令神钟会获得这些牌（背面朝上移动，可奋激）。
--线上实测不会防止移动，可以正常发动旋风、琴音，十分离谱
lishi:addEffect(fk.BeforeCardsMove, {
  anim_type = "negative",
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if table.contains(player:getTableMark(lishi.name), "discard") and player.phase == Player.Discard then
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player and move.toArea == Card.DiscardPile and
          move.moveReason == fk.ReasonDiscard and move.skillName == "phase_discard" then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insert(cards, info.cardId)
            end
          end
        end
      end
      if #cards > 0 then
        local src = player:getMark("lishi_discard")
        if src ~= 0 and not src.dead then
          event:setCostData(self, { cards = cards, tos = { src } })
        end
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local handcards = player:getCardIds("h")
    local cards = table.filter(event:getCostData(self).cards, function(id)
      return table.contains(handcards, id)
    end)
    if #cards > 0 then
      room:cancelMove(data, cards)
      local src = event:getCostData(self).tos[1]
      room:obtainCard(src, cards, false, fk.ReasonPrey, src, lishi.name)
    end
  end,
})

return lishi
