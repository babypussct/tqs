local luanqun = fk.CreateSkill{
  name = "luanqun",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("role_mode") then
      return "luanqun_role_mode"
    else
      return "luanqun_1v2"
    end
  end,
}

Fk:loadTranslationTable{
  ["luanqun"] = "乱群",
  [":luanqun"] = "出牌阶段限一次，若你有手牌，你可以令所有角色同时展示一张手牌，然后你可以获得其中至多两张（若为身份模式，则改为至多四张）"..
  "与你展示牌颜色相同的牌。令所有与你展示牌颜色不同的角色于其下回合出牌阶段使用第一张【杀】只能指定你为目标，且你不能响应其下回合使用的【杀】。",

  [":luanqun_1v2"] = "出牌阶段限一次，若你有手牌，你可以令所有角色同时展示一张手牌，然后你可以获得其中至多两张"..
  "与你展示牌颜色相同的牌。令所有与你展示牌颜色不同的角色于其下回合出牌阶段使用第一张【杀】只能指定你为目标，且你不能响应其下回合使用的【杀】。",
  [":luanqun_role_mode"] = "出牌阶段限一次，若你有手牌，你可以令所有角色同时展示一张手牌，然后你可以获得其中至多四张"..
  "与你展示牌颜色相同的牌。令所有与你展示牌颜色不同的角色于其下回合出牌阶段使用第一张【杀】只能指定你为目标，且你不能响应其下回合使用的【杀】。",

  ["#luanqun"] = "乱群：令所有角色展示一张手牌，你可以获得其中一张与你展示颜色相同的牌",
  ["#luanqun-card"] = "乱群：请展示一张手牌",
  ["#luanqun-get"] = "乱群：你可以获得其中至多%arg张牌",

  ["$luanqun1"] = "年过杖朝，自是从心所欲，何来逾矩之理？",
  ["$luanqun2"] = "位居执慎，博涉多闻，更应秉性而论！",
}

luanqun:addEffect("active", {
  anim_type = "control",
  prompt = "#luanqun",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(luanqun.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:doIndicate(player, room.alive_players)
    local targets = table.filter(room.alive_players, function(p)
      return not p:isKongcheng()
    end)
    local result = room:askToJointCards(player, {
      players = targets,
      min_num = 1,
      max_num = 1,
      cancelable = false,
      include_equip = false,
      skill_name = luanqun.name,
      prompt = "#luanqun-card",
    })
    local all_cards = {}
    for _, p in ipairs(targets) do
      local id = result[p][1]
      if not p.dead and table.contains(p:getCardIds("h"), id) then
        p:showCards(id)
        if table.contains(p:getCardIds("h"), id) then
          table.insertIfNeed(all_cards, id)
        end
      end
    end
    if player.dead or #all_cards == 0 then return end
    local my_card = Fk:getCardById(result[player][1])
    local available_cards = table.filter(all_cards, function(id)
      return Fk:getCardById(id).color == my_card.color
    end)
    table.removeOne(available_cards, my_card.id)
    local maxNum = room:isGameMode("role_mode") and 4 or 2
    local cards = room:askToChooseCards(player, {
      target = player,
      min = 0,
      max = maxNum,
      flag = { card_data = {{ luanqun.name, available_cards }} },
      skill_name = luanqun.name,
      prompt = "#luanqun-get:::"..maxNum,
    })
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, luanqun.name, nil, true, player)
    end
    local mark = player:getTableMark(luanqun.name)
    for _, p in ipairs(targets) do
      if not p.dead then
        local card = Fk:getCardById(result[p][1])
        if card.color ~= my_card.color then
          table.insert(mark, p.id)
        end
      end
    end
    if not player.dead and #mark > 0 then
      room:setPlayerMark(player, luanqun.name, mark)
    end
  end,
})
luanqun:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return table.contains(player:getTableMark(luanqun.name), target.id)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:removeTableMark(player, luanqun.name, target.id)
    room:setPlayerMark(target, "luanqun-turn", player.id)
    room:addTableMark(target, "luanqun_target-turn", player.id)
  end
})
luanqun:addEffect(fk.TargetConfirmed, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and
      data.from:getMark("luanqun-turn") == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:removeTableMark(data.from, "luanqun_target-turn", player.id)
    data.use.disresponsiveList = data.use.disresponsiveList or {}
    table.insertIfNeed(data.use.disresponsiveList, player)
  end,
})
luanqun:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    if card.trueName == "slash" and from and from.phase == Player.Play then
      local targets = table.filter(Fk:currentRoom().alive_players, function(p)
        return table.contains(from:getTableMark("luanqun_target-turn"), p.id)
      end)
      return #targets > 0 and not table.contains(targets, to)
    end
  end,
})

return luanqun
