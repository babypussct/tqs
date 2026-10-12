
local fangzheng = fk.CreateSkill{
  name = "fangzheng",
}

Fk:loadTranslationTable{
  ["fangzheng"] = "方整",
  [":fangzheng"] = "准备阶段，若你手牌的花色数为偶数，你可以观看牌堆顶四张牌，并以任意顺序将这些牌置于牌堆顶或牌堆底；"..
  "出牌阶段每个数字限一次，若你的手牌数为偶数，你使用下一张牌时可以令至多两名角色各摸两张牌，且因此摸的牌本回合不计入手牌上限。",

  ["#fangzheng-choose"] = "方整：你可以令至多两名角色各摸两张牌",
  ["@@fangzheng-inhand-turn"] = "不计上限",

  ["$fangzheng1"] = "",
  ["$fangzheng2"] = "",
}

fangzheng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fangzheng.name) and player.phase == Player.Start and
      player:getHandcardNum() % 2 == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToGuanxing(player, { cards = room:getNCards(4) })
  end,
})

fangzheng:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(fangzheng.name) and
      player.phase == Player.Play and
      data.extra_data and data.extra_data.fangzheng
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 2,
      targets = room.alive_players,
      skill_name = fangzheng.name,
      prompt = "#fangzheng-choose",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        p:drawCards(2, fangzheng.name, nil, "@@fangzheng-inhand-turn")
      end
    end
  end,

  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(fangzheng.name, true) and
      player.phase == Player.Play and player:getMark("fangzheng_invoke-phase") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    data.extra_data = data.extra_data or {}
    data.extra_data.fangzheng = true
    room:setPlayerMark(player, "fangzheng_invoke-phase", 0)
  end,
})

fangzheng:addEffect(fk.CardUsing, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(fangzheng.name, true) and
      player.phase == Player.Play and player:getHandcardNum() % 2 == 0 and
      not table.contains(player:getTableMark("fangzheng-phase"), player:getHandcardNum())
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "fangzheng-phase", player:getHandcardNum())
    room:setPlayerMark(player, "fangzheng_invoke-phase", 1)
  end,
})

fangzheng:addEffect("maxcards", {
  exclude_from = function (self, player, card)
    return card:getMark("@@fangzheng-inhand-turn") > 0
  end,
})

return fangzheng
