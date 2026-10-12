
local skill = fk.CreateSkill {
  name = "amazing_mushroom_skill",
}

skill:addEffect("cardskill", {
  prompt = "#amazing_mushroom_skill",
  can_use = Util.GlobalCanUse,
  on_use = function (self, room, cardUseEvent)
    return Util.AoeCardOnUse(self, cardUseEvent.from, cardUseEvent, true)
  end,
  mod_target_filter = Util.TrueFunc,
  on_action = function(self, room, use, finished)
    room:addSkill(skill.name)
    use.extra_data = use.extra_data or {}
    if not finished then
      --好坏与图片无关
      local mushrooms = room:tableRandomPick({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, 5)
      local results = { "good", "bad", "good", "bad", "good", "bad", "good", "bad", "good", "bad" }
      table.shuffle(mushrooms)
      table.shuffle(results)
      local ids = room:getBanner("amazing_mushroom") or {}
      if #ids == 0 then
        for _ = 1, 5 do
          table.insert(ids, room:printCard("mushroom").id)
        end
        room:setBanner("amazing_mushroom", ids)
      end
      for i = 1, 5 do
        local card = Fk:getCardById(ids[i])
        room:setCardMark(card, "amazing_mushroom_pic", mushrooms[i])
        room:setCardMark(card, "amazing_mushroom_result", results[i])
      end
      for _, p in ipairs(room.players) do
        room:fillAG(p, ids)
      end
      use.extra_data.AGFilled = ids
    else
      if use.extra_data and use.extra_data.AGFilled then
        for _, p in ipairs(room.players) do
          room:closeAG(p)
        end
      end
      use.extra_data.AGFilled = nil
    end
  end,
  on_effect = function(self, room, effect)
    local to = effect.to
    local cards = effect.extra_data.AGFilled or {}
    if #cards == 0 then
      room:loseHp(to, 1, skill.name)
    else
      --"能识别菌子效果"好菌子会显示👍，坏菌子会显示👎
      local chosen
      if to:hasSkill("junzhu") then
        for _, id in ipairs(cards) do
          local card = Fk:getCardById(id)
          room:setCardMark(card, "@!!"..card:getMark("amazing_mushroom_result").."_mushroom-turn", 1)
        end
        chosen = room:askToCards(to, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = skill.name,
          pattern = tostring(Exppattern{ id = cards }),
          prompt = "Please choose cards",
          cancelable = false,
          expand_pile = cards,
        })[1]
        for _, id in ipairs(cards) do
          local card = Fk:getCardById(id)
          room:setCardMark(card, "@!!"..card:getMark("amazing_mushroom_result").."_mushroom-turn", 0)
        end
      else
        chosen = room:askToAG(to, {
          id_list = cards,
          cancelable = false,
          skill_name = self.name,
        })
      end
      room:takeAG(to, chosen, room.players)
      local result = Fk:getCardById(chosen):getMark("amazing_mushroom_result")
      if room:getCurrent() == to then
        room:setPlayerMark(to, "@!!"..result.."_mushroom-turn", 1)
      else
        room:setPlayerMark(to, "@!!amazing_mushroom", 1)
        room:setPlayerMark(to, "amazing_mushroom", result)
      end
    end
  end,
})

skill:addEffect(fk.CardEffectCancelledOut, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return data.to == player and not player.dead and data.card.name == "amazing_mushroom"
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, 1, skill.name)
  end,
})

skill:addEffect("filter", {
  card_pic_filter = function (self, card)
    if card:getMark("amazing_mushroom_pic") ~= 0 then
      return "mushroom"..card:getMark("amazing_mushroom_pic")
    end
  end,
})

skill:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@!!amazing_mushroom") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@!!amazing_mushroom", 0)
    room:setPlayerMark(player, "@!!"..player:getMark("amazing_mushroom").."_mushroom-turn", 1)
    room:setPlayerMark(player, "amazing_mushroom", 0)
  end,
})

--本回合使用牌60%概率随机执行一个效果
--美味！：摸两张牌；回复1点体力，额外结算一次，分配2点伤害，本回合获得一个有用的技能（zhujiu qice lihun keji wusheng juesi）
--拉完！：随机弃置两张手牌；失去1点体力，随机指定目标，随机重铸一张手牌，本回合获得一个没用的技能（zaoxian ex__kurou ranshang）

skill:addEffect(fk.AfterCardUseDeclared, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.extra_data and
      (data.extra_data.amazing_mushroom or ""):endsWith("3")
  end,
  on_use = function (self, event, target, player, data)
    if data.extra_data.amazing_mushroom == "good3" then
      data.additionalEffect = (data.additionalEffect or 0) + 1
    else
      data.tos = player.room:tableRandomPick(data.card:getAvailableTargets(player), #data.tos)
    end
  end,

  can_refresh = function (self, event, target, player, data)
    return target == player and (player:getMark("@!!good_mushroom-turn") + player:getMark("@!!bad_mushroom-turn") > 0) and
      #data.tos > 0 and player.room:random() > 0.4
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    if player:getMark("@!!good_mushroom-turn") > 0 then
      data.extra_data.amazing_mushroom = "good"..player.room:random(5)
    else
      data.extra_data.amazing_mushroom = "bad"..player.room:random(5)
    end
  end,
})

skill:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target == player and data.extra_data and data.extra_data.amazing_mushroom and not player.dead then
      local choice = data.extra_data.amazing_mushroom
      if table.contains({ "good1", "good4", "good5", "bad2", "bad5" }, choice) then
        return true
      elseif choice == "good2" then
        return player:isWounded()
      else
        return not player:isKongcheng()
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = data.extra_data.amazing_mushroom
    if choice == "good1" then
      player:drawCards(2, skill.name)
    elseif choice == "good2" then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skill.name,
      }
    elseif choice == "good4" then
      local tos = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 2,
        prompt = "#amazing_mushroom-damage",
        skill_name = skill.name,
        cancelable = false,
      })
      if #tos == 1 then
        room:damage{
          from = player,
          to = tos[1],
          damage = 2,
          skill_name = skill.name,
        }
      else
        room:sortByAction(tos)
        for _, p in ipairs(tos) do
          if not p.dead then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skill_name = skill.name,
            }
          end
        end
      end
    elseif choice == "bad1" then
      local cards = table.filter(player:getCardIds("h"), function (id)
        return not player:prohibitDiscard(id)
      end)
      if #cards > 0 then
        room:throwCard(room:tableRandomPick(cards, 2), skill.name, player, player)
      end
    elseif choice == "bad2" then
      room:loseHp(player, 1, skill.name)
    elseif choice == "bad4" then
      room:recastCard(room:tableRandomPick(player:getCardIds("h"), 1), player, skill.name)
    else
      local skills = {}
      if choice == "good5" then
        skills = { "qice", "wusheng", "lihun", "anguo", "keji", "zhujiu", "juesi", "mashu" }
      elseif choice == "bad5" then
        skills = { "zili", "zaoxian", "juyi", "ol__hongju", "ex__kurou", "ranshang", "dushi", "fanxiang" }
      end
      skills = table.filter(skills, function (s)
        return not player:hasSkill(s, true)
      end)
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event and #skills > 0 then
        local s = room:tableRandomPick(skills)
        room:handleAddLoseSkills(player, s)
        turn_event:addCleaner(function()
          room:handleAddLoseSkills(player, "-"..s)
        end)
      end
    end
  end,
})

return skill
