local tribladeSkill = fk.CreateSkill{
  name = "#triblade_skill",
  attached_equip = "triblade",
}
tribladeSkill:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tribladeSkill.name) and data.card and data.card.trueName == "slash" and not data.to.dead and not data.chain and
      not player:isKongcheng() and table.find(player.room.alive_players, function(p) return data.to:distanceTo(p) == 1 and p ~= player end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return data.to:distanceTo(p) == 1 and p ~= player end)
    if #targets == 0 then return false end
    local cards = table.filter(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id)
    end)
    local to, card = room:askToChooseCardsAndPlayers(player, {targets = targets, min_num = 1, max_num = 1, skill_name = "triblade",
      pattern = tostring(Exppattern{ id = cards }), min_card_num = 1, max_card_num = 1, prompt = "#triblade-invoke::"..data.to.id, cancelable = true})
    if #to > 0 then
      event:setCostData(self, { tos = to, cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:throwCard(event:getCostData(self).cards, "triblade", player, player)
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = "triblade",
    }
  end
})

tribladeSkill:addTest(function(room, me)
  local card = room:printCard("triblade")
  local chitu = room:printCard("chitu")
  local comp2, comp3 = room.players[2], room.players[3]

  FkTest.setNextReplies(me, { json.encode {
    card = { skill = "choose_players_skill", subcards = {1} },
    targets = { comp3.id }
  } })
  FkTest.setNextReplies(comp2, { "__cancel" })
  FkTest.setRoomBreakpoint(me, "AskForUseActiveSkill") -- 断点
  FkTest.runInRoom(function()
    room:obtainCard(me, {1})
    room:useCard {
      from = me,
      tos = { me },
      card = chitu,
    }
    room:useCard {
      from = me,
      tos = { me },
      card = card,
    }
    room:useCard {
      from = me,
      tos = { comp2 },
      card = Fk:cloneCard("slash"),
    }
  end)
  local handler = ClientInstance.current_request_handler --[[@as ReqActiveSkill]]
  lu.assertIsTrue(handler:cardValidity(1)) -- 可以手牌
  lu.assertEvalToFalse(handler:cardValidity(chitu.id)) -- 不能装备区的牌
  FkTest.resumeRoom()
  lu.assertEquals(comp3.hp, 3)
  lu.assertIsTrue(me:isKongcheng())
end)

Fk:loadTranslationTable{
  ["triblade"] = "三尖两刃刀",
  ["#triblade_skill"] = "三尖两刃刀",
  [":triblade"] = "装备牌·武器<br/><b>攻击范围</b>：３ <br/><b>武器技能</b>：当你使用【杀】对目标角色造成伤害后，你可以弃置一张手牌，"..
  "对其距离1的一名其他角色造成1点伤害。",
  ["#triblade-invoke"] = "三尖两刃刀：你可以弃置一张手牌，对 %dest 距离1的一名其他角色造成1点伤害",
}

return tribladeSkill
