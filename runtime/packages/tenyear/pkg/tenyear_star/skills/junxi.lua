local junxi = fk.CreateSkill{
  name = "junxi",
}

Fk:loadTranslationTable{
  ["junxi"] = "峻袭",
  [":junxi"] = "出牌阶段开始时，你可以选择一名其他角色并记录你此时的手牌数。此阶段结束时，该角色需弃置牌并失去体力，"..
  "弃牌和失去体力总数为X（X为你此时手牌数和此阶段开始时手牌数之差）；若X为0，你弃置两张牌。",

  ["#junxi-choose"] = "峻袭：选择一名角色，此阶段结束时其需弃牌并失去体力",
  ["@junxi-phase"] = "峻袭",
  ["#junxi-discard"] = "峻袭：请弃置%arg张牌，每少弃置一张失去1点体力",

  ["$junxi1"] = "进亦死，退亦死，向死而生可乎！",
  ["$junxi2"] = "与其坐以待毙，何不放手一搏！",
}

junxi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(junxi.name) and player.phase == Player.Play and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#junxi-choose",
      skill_name = junxi.name,
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
    room:setPlayerMark(player, "@junxi-phase", { to.general, " ", player:getHandcardNum() })
    room:setPlayerMark(player, "junxi-phase", to.id)
  end,
})

junxi:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(junxi.name) and player.phase == Player.Play and
      player:getMark("@junxi-phase") ~= 0 and not player.room:getPlayerById(player:getMark("junxi-phase")).dead
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { player.room:getPlayerById(player:getMark("junxi-phase")) }})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = math.abs(player:getMark("@junxi-phase")[3] - player:getHandcardNum())
    if n == 0 then
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = junxi.name,
        cancelable = false,
      })
    else
      local cards = room:askToDiscard(to, {
        min_num = 1,
        max_num = n,
        include_equip = true,
        skill_name = junxi.name,
        cancelable = true,
        prompt = "#junxi-discard:::"..n,
      })
      n = n - #cards
      if n > 0 and not to.dead then
        room:loseHp(to, n, junxi.name, player)
      end
    end
  end,
})

return junxi
