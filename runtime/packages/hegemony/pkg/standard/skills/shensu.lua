local shensu = fk.CreateSkill{
  name = "hs__shensu",
}

Fk:loadTranslationTable{
  ["hs__shensu"] = "神速",
  [":hs__shensu"] = "你可以作出如下选择：<br>"..
  "1.跳过判定阶段和摸牌阶段；<br>2.跳过出牌阶段并弃置一张装备牌；<br>3.跳过弃牌阶段并失去1点体力。<br>"..
  "你每执行一项，视为使用一张无距离限制的【杀】。",

  ["#hs__shensu1-choose"] = "神速：你可以跳过判定阶段和摸牌阶段，视为使用一张无距离限制的【杀】",
  ["#hs__shensu2-choose"] = "神速：你可以跳过出牌阶段并弃置一张装备牌，视为使用一张无距离限制的【杀】",
  ["#hs__shensu3-choose"] = "神速：你可以跳过弃牌阶段并失去1点体力，视为使用一张无距离限制的【杀】",

  ["$hs__shensu1"] = "吾善于千里袭人！",
  ["$hs__shensu2"] = "取汝首级，有如探囊取物！",
}

shensu:addEffect(fk.EventPhaseChanging, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shensu.name) and not data.skipped then
      if data.phase == Player.Judge then
        if not player:canSkip(Player.Draw) then return end
      elseif data.phase == Player.Play then
        if player:isNude() then return end
      elseif data.phase == Player.Discard then
        if player.hp < 1 then return end
      else
        return
      end
      return table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canUseTo(Fk:cloneCard("slash", nil, nil, shensu.name), p, { bypass_distances = true, bypass_times = true })
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local slash = Fk:cloneCard("slash", nil, nil, shensu.name)
    local max_num = slash.skill:getMaxTargetNum(player, slash)
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return player:canUseTo(slash, p, { bypass_distances = true, bypass_times = true })
    end)
    if #targets == 0 or max_num == 0 then return end
    if data.phase == Player.Judge then
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = max_num,
        prompt = "#hs__shensu1-choose",
        skill_name = shensu.name,
        cancelable = true,
      })
      if #tos > 0 then
        event:setCostData(self, {tos = tos})
        return true
      end
    elseif data.phase == Player.Play then
      local tos, id = room:askToChooseCardsAndPlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = max_num,
        pattern = ".|.|.|.|.|equip",
        prompt = "#hs__shensu2-choose",
        skill_name = shensu.name,
        cancelable = true,
        max_card_num = 1,
        min_card_num = 1,
        will_throw = true,
      })
      if #tos > 0 and id then
        event:setCostData(self, { tos = tos, cards = id })
        return true
      end
    elseif data.phase == Player.Discard then
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = max_num,
        prompt = "#hs__shensu3-choose",
        skill_name = shensu.name,
        cancelable = true,
      })
      if #tos > 0 then
        room:sortByAction(tos)
        event:setCostData(self, {tos = tos})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.skipped = true
    if data.phase == Player.Judge then
      player:skip(Player.Draw)
    elseif data.phase == Player.Play then
      player:skip(Player.Play)
      room:throwCard(event:getCostData(self).cards, shensu.name, player, player)
    elseif data.phase == Player.Discard then
      room:loseHp(player, 1, shensu.name)
    end
    if player.dead then return end
    room:useVirtualCard("slash", nil, player, event:getCostData(self).tos, shensu.name, true)
  end,
})

return shensu
