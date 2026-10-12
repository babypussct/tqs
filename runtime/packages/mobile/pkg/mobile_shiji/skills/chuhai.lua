local chuhai = fk.CreateSkill {
  name = "chuhai",
  tags = { Skill.Quest },
  related_skills = { "zhangming" },
}

Fk:loadTranslationTable{
  ["chuhai"] = "除害",
  [":chuhai"] = "使命技，出牌阶段限一次，你可以摸一张牌，并与一名其他角色拼点，此次你的拼点牌点数增加X（X为4减去你装备区的装备数量）。"..
  "若你赢：你观看其手牌，从牌堆或弃牌堆随机获得其手牌中拥有的类别牌各一张；"..
  "你于此阶段对其造成伤害后，将牌堆或弃牌堆中一张你空置装备栏对应类型的装备牌，置入你对应的装备区。<br>"..
  "⬤　成功：当一张装备牌进入你的装备区后，若你的装备区有不少于3张装备，则你将体力值回复至上限，获得〖彰名〗，失去〖乡害〗。<br>"..
  "⬤　失败：若你于使命达成前，你使用〖除害〗拼点没赢，且你的拼点结果不大于6点，则使命失败。",

  ["#chuhai"] = "除害：摸一张牌，与一名角色拼点，若赢则根据其手牌类别获得牌，且本阶段对其造成伤害后获得装备",
  ["@@chuhai-phase"] = "除害",

  ["$chuhai1"] = "有我在此，安敢为害？！",
  ["$chuhai2"] = "小小孽畜，还不伏诛？！",
  ["$chuhai3"] = "此番不成，明日再战！",
}

chuhai:addEffect("active", {
  anim_type = "offensive",
  audio_index = 1,
  prompt = "#chuhai",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(chuhai.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select, true)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    player:drawCards(1, chuhai.name)
    if player.dead or target.dead or not player:canPindian(target) then return end
    local pindian = player:pindian({target}, chuhai.name)
    if player.dead or target.dead then return end
    if pindian.results[target].winner == player then
      if not target:isKongcheng() then
        room:viewCards(player, { cards = target:getCardIds("h"), skill_name = chuhai.name, prompt = "$ViewCardsFrom:"..target.id })
        local types = {}
        for _, id in ipairs(target:getCardIds("h")) do
          table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
        end

        local cards = {}
        for _, type_name in ipairs(types) do
          local card = room:getCardsFromPileByRule(".|.|.|.|.|" .. type_name)
          if #card == 0 then
            card = room:getCardsFromPileByRule(".|.|.|.|.|" .. type_name, 1, "discardPile")
          end
          if #card > 0 then
            table.insert(cards, card[1])
          end
        end
        if #cards > 0 then
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, chuhai.name, nil, false, player)
        end
        if player.dead or target.dead then return end
      end
      room:setPlayerMark(target, "@@chuhai-phase", 1)
      room:addTableMarkIfNeed(player, "chuhai_target-phase", target.id)
    end
  end,
})
chuhai:addEffect(fk.AfterCardsMove, {
  audio_index = 2,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chuhai.name) and player:getQuestSkillState(chuhai.name) == nil and #player:getCardIds("e") > 2 then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Equip then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:updateQuestSkillState(player, chuhai.name, false)
    room:invalidateSkill(player, chuhai.name)
    if player:isWounded() then
      room:recover{
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = chuhai.name
      }
      if player.dead then return end
    end
    room:handleAddLoseSkills(player, "-xianghai|zhangming")
  end,
})
chuhai:addEffect(fk.PindianResultConfirmed, {
  anim_type = "negative",
  audio_index = 3,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chuhai.name) and player:getQuestSkillState(chuhai.name) == nil and
      data.reason == chuhai.name and data.from == player and data.winner ~= player and data.fromCard.number < 7
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:updateQuestSkillState(player, chuhai.name, true)
    room:invalidateSkill(player, chuhai.name)
  end,
})
chuhai:addEffect(fk.PindianCardsDisplayed, {
  can_refresh = function(self, event, target, player, data)
    return data.reason == chuhai.name and data.from == player and #player:getCardIds("e") < 4
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:changePindianNumber(data, player, 4 - #player:getCardIds("e"), chuhai.name)
  end,
})
chuhai:addEffect(fk.Damage, {
  anim_type = "drawcard",
  audio_index = 1,
  can_trigger = function(self, event, target, player, data)
    return data.from == player and table.contains(player:getTableMark("chuhai_target-phase"), data.to.id) and
      player:hasSkill(chuhai.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = table.filter({Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide,
      Card.SubtypeOffensiveRide, Card.SubtypeTreasure}, function (type_name) return player:hasEmptyEquipSlot(type_name) end)
    if #types == 0 then return false end
    local cards1, cards2 = {}, {}
    for _ = 1, #types, 1 do
      table.insert(cards1, {})
      table.insert(cards2, {})
    end
    for i = 1, #room.draw_pile, 1 do
      local card = Fk:getCardById(room.draw_pile[i])
      if card.type == Card.TypeEquip and table.contains(types, card.sub_type) then
        table.insert(cards1[table.indexOf(types, card.sub_type)], card.id)
      end
    end
    for i = 1, #room.discard_pile, 1 do
      local card = Fk:getCardById(room.discard_pile[i])
      if card.type == Card.TypeEquip and table.contains(types, card.sub_type) then
        table.insert(cards2[table.indexOf(types, card.sub_type)], card.id)
      end
    end

    for i = 1, #types, 1 do
      if #cards1[i] > 0 then
        room:moveCardTo(room:tableRandomPick(cards1[i]), Card.PlayerEquip, player, fk.ReasonPut, chuhai.name, nil, true, player)
        break
      end
      if #cards2[i] > 0 then
        room:moveCardTo(room:tableRandomPick(cards2[i]), Card.PlayerEquip, player, fk.ReasonPut, chuhai.name, nil, true, player)
        break
      end
    end

    if player:hasSkill("zhangming", true) then
      --除害成功的那次伤害不能发动彰名，姑且乱写
      data.extra_data = data.extra_data or {}
      data.extra_data.zhangmingInvalidate = true
    end
  end,
})

return chuhai
