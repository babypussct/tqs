local huaiyuan = fk.CreateSkill{
  name = "huaiyuan",
}

Fk:loadTranslationTable{
  ["huaiyuan"] = "怀远",
  [":huaiyuan"] = "你的初始手牌称为“绥”。你每失去一张“绥”时，令一名角色手牌上限+1或攻击范围+1或摸一张牌。当你死亡时，"..
  "你可以令一名其他角色获得你以此法增加的手牌上限和攻击范围。",

  ["@@appease-inhand"] = "绥",
  ["#huaiyuan-invoke"] = "怀远：令一名角色手牌上限+1/攻击范围+1/摸一张牌",
  ["@huaiyuan_maxcards"] = "手牌上限+",
  ["@huaiyuan_attackrange"] = "攻击范围+",
  ["huaiyuan_maxcards"] = "手牌上限+1",
  ["huaiyuan_attackrange"] = "攻击范围+1",
  ["#huaiyuan-choose"] = "怀远：你可以令一名其他角色获得“怀远”增加的手牌上限和攻击范围",

  ["$huaiyuan1"] = "当怀远志，砥砺奋进。",
  ["$huaiyuan2"] = "举有成资，谋有全策。",
}

huaiyuan:addAuxActiveSkill("huaiyuan_active", {
  interaction = UI.OptionBox { options = { "huaiyuan_maxcards", "huaiyuan_attackrange", "draw1" }, direct_send = true },
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
})

huaiyuan:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  trigger_times = function(self, event, target, player, data)
    local x = 0
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and info.beforeCard:getMark("@@appease-inhand") > 0 then
            x = x + 1
          end
        end
      end
    end
    return x
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(huaiyuan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "huaiyuan_active",
      prompt = "#huaiyuan-invoke",
      cancelable = false,
      no_indicate = false,
    })
    if not (success and dat) then
      dat = {}
      dat.targets = {player}
      dat.interaction = "draw1"
    end
    local to = dat.targets[1]
    local choice = dat.interaction
    if choice == "draw1" then
      to:drawCards(1, huaiyuan.name)
    else
      room:addPlayerMark(to, "@"..choice, 1)
    end
  end,
})

huaiyuan:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huaiyuan.name, false, true) and
      player:getMark("@huaiyuan_maxcards") + player:getMark("@huaiyuan_attackrange") > 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = huaiyuan.name,
      prompt = "#huaiyuan-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addPlayerMark(to, "@huaiyuan_maxcards", player:getMark("@huaiyuan_maxcards"))
    room:addPlayerMark(to, "@huaiyuan_attackrange", player:getMark("@huaiyuan_attackrange"))
  end,
})

huaiyuan:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(huaiyuan.name) and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("h")
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@appease-inhand", 1)
    end
  end,
})

huaiyuan:addEffect("atkrange", {
  correct_func = function (self, from, to)
    return from:getMark("@huaiyuan_attackrange")
  end,
})
huaiyuan:addEffect("maxcards", {
  correct_func = function(self, player)
    return player:getMark("@huaiyuan_maxcards")
  end,
})


return huaiyuan
