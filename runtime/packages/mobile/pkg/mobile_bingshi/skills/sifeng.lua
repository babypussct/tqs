
local sifeng = fk.CreateSkill({
  name = "sifeng",
})

Fk:loadTranslationTable{
  ["sifeng"] = "伺锋",
  [":sifeng"] = "结束阶段，你可以将牌堆顶的三张牌以任意顺序分配并扣置在至多两名其他角色的武将牌上，称为“伺锋”。<br>"..
  "武将牌上有“伺锋”的角色：于其回合内使用牌后，你移去其武将牌上的首张“伺锋”，若其使用的牌与移去的“伺锋”颜色不同，其弃置一张手牌；"..
  "其回合结束时，若有“伺锋”未被移去，你选择一项：1.获得其武将牌上的“伺锋”；2.移去其武将牌上剩余的“伺锋”，然后对其造成1点伤害。",

  ["$sifeng"] = "伺锋",
  ["#sifeng-give"] = "伺锋：请将这些牌分配给至多两名其他角色",
  ["sifeng_prey"] = "获得%dest的“伺锋”",
  ["sifeng_damage"] = "移去%dest的“伺锋”，对其造成1点伤害",

  ["$sifeng1"] = "各路坚守自固，蜀军疲而自退矣。",
  ["$sifeng2"] = "我军十倍于贼，又有何惧之有。",
  ["$sifeng3"] = "哼！以此观之，蜀军不过尔尔。",
  ["$sifeng4"] = "蜀军惯用此计，焉能再诈于我。",
  ["$sifeng5"] = "速割陇上之粮，勿教蜀军清获。",
  ["$sifeng6"] = "蜀军兵败溃散，正宜吾等追击。",
}

sifeng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sifeng.name) and player.phase == Player.Finish and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    local all_cards = table.simpleClone(cards)
    local targets, result = {}, { {}, {} }
    while #cards > 0 do
      local to, ids = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = #cards,
        min_num = 1,
        max_num = 1,
        targets = #targets == 2 and targets or room:getOtherPlayers(player, false),
        pattern = tostring(Exppattern{ id = cards }),
        skill_name = sifeng.name,
        prompt = "#sifeng-give",
        cancelable = false,
        expand_pile = all_cards,
        no_indicate = true,
      })
      table.insertIfNeed(targets, to[1])
      table.insertTable(result[table.indexOf(targets, to[1])], ids)
      for _, id in ipairs(ids) do
        table.removeOne(cards, id)
        if #cards == 0 then
          break
        end
        room:setCardMark(Fk:getCardById(id), "@DistributionTo",
          Fk:translate(to[1].general == "anjiang" and "seat#" .. tostring(to[1].seat) or to[1].general))
      end
    end
    for _, id in ipairs(all_cards) do
      room:setCardMark(Fk:getCardById(id), "@DistributionTo", 0)
    end
    local moves = {}
    for i = 1, #targets do
      table.insert(moves, {
        ids = result[i],
        to = targets[i],
        toArea = Card.PlayerSpecial,
        moveReason = fk.ReasonJustMove,
        skillName = sifeng.name,
        specialName = "$sifeng",
        proposer = player,
        moveVisible = false,
      })
    end
    room:moveCards(table.unpack(moves))
  end,
})

sifeng:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  audio_index = { 3, 4 },
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(sifeng.name) and
      #target:getPile("$sifeng") > 0 and target == player.room:getCurrent()
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local yes = Fk:getCardById(target:getPile("$sifeng")[1]).color ~= data.card.color
    room:moveCardTo(target:getPile("$sifeng")[1], Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, sifeng.name, nil, true, player)
    if yes and not target:isKongcheng() then
      room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = sifeng.name,
        cancelable = false,
      })
    end
  end,
})

sifeng:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  audio_index = { 5, 6 },
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(sifeng.name) and #target:getPile("$sifeng") > 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = { target } })
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      skill_name = sifeng.name,
      choices = { "sifeng_prey::"..target.id, "sifeng_damage::"..target.id },
    })
    if choice:startsWith("sifeng_prey") then
      room:moveCardTo(target:getPile("$sifeng"), Card.PlayerHand, player, fk.ReasonJustMove, sifeng.name, nil, false, player)
    else
      room:moveCardTo(target:getPile("$sifeng"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, sifeng.name, nil, true, player)
      if not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = sifeng.name,
        }
      end
    end
  end,
})

sifeng:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if not table.find(room.alive_players, function (p)
    return p:hasSkill(sifeng.name, true)
  end) then
    for _, p in ipairs(room:getAlivePlayers()) do
      room:moveCardTo(p:getPile("$sifeng"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile)
    end
  end
end)

return sifeng
