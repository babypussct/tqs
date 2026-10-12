local chengye = fk.CreateSkill {
  name = "chengye",
  derived_piles = "chengye_classic",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chengye"] = "承业",
  [":chengye"] = "锁定技，当其他角色使用一张非转化牌结算结束后，或一张其他角色区域内的装备牌或延时锦囊牌进入弃牌堆后，"..
  "若你对应的<a href='chengye_href'>“六经”</a>处于缺失状态，你将此牌置于你的武将牌上，称为“典”；"..
  "出牌阶段开始时，若你没有“六经”处于缺失状态，你获得所有“典”。",

  ["chengye_href"] = "诗-伤害类锦囊牌；<br>书-基本牌；<br>礼-【无懈可击】；<br>易-【无中生有】；<br>乐-【乐不思蜀】；<br>春秋-装备牌",
  ["chengye_classic"] = "典",
  ["#chengye-put"] = "承业：将其中一张牌作为“典”",

  ["$chengye1"] = "勤学于未长，立志于未壮。",
  ["$chengye2"] = "志在坚且行，学在勤且久。",
  ["$chengye3"] = "承继族贤之业，弘彰孔儒之学。",
}

local getClassicsType = function (cardId)
  local card = Fk:getCardById(cardId, true)
  if card.type == Card.TypeBasic then
    return "cy_classic_basic"
  elseif card.type == Card.TypeEquip then
    return "cy_classic_equip"
  elseif card.name == "nullification" or card.name == "ex_nihilo" or card.name == "indulgence" then
    return "cy_classic_"..card.name
  elseif card.is_damage_card then
    return "cy_classic_damage"
  end
  return ""
end

local getLackClassics = function (player)
  local classic = {
    "cy_classic_basic",
    "cy_classic_equip",
    "cy_classic_damage",
    "cy_classic_nullification",
    "cy_classic_ex_nihilo",
    "cy_classic_indulgence",
  }
  for _, id in ipairs(player:getPile("chengye_classic")) do
    local c = getClassicsType(id)
    table.removeOne(classic, c)
  end
  return classic
end

local chengyeRecordOnUse = function(self, event, target, player, data)
  local skillName = chengye.name
  local room = player.room
  room:notifySkillInvoked(player, skillName, "drawcard")
  player:broadcastSkillInvoke(skillName, math.random(2))

  local moves = {}
  local moveMap = {}
  for _, id in ipairs(event:getCostData(self).cards) do
    local ctype = getClassicsType(id)
    moveMap[ctype] = moveMap[ctype] or {}
    table.insert(moveMap[ctype], id)
  end
  for _, v in pairs(moveMap) do
    local put = #v == 1 and
      v[1] or
      room:askToChooseCard(
        player,
        {
          target = player,
          flag = { card_data = { { "AskForCardChosen", v } } },
          skill_name = skillName,
          prompt = "#chengye-put",
        }
      )
    table.insert(moves, {
      ids = { put },
      from = room:getCardOwner(put),
      to = player,
      toArea = Card.PlayerSpecial,
      moveReason = fk.ReasonPut,
      skillName = skillName,
      specialName = "chengye_classic",
      proposer = player,
    })
  end
  room:moveCards(table.unpack(moves))
end

chengye:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chengye.name) and target ~= player and not data.card:isConverted() then
      local id = data.card:getEffectiveId()
      if player.room:getCardArea(id) == Card.Processing and table.contains(getLackClassics(player), getClassicsType(id)) then
        event:setCostData(self, { cards = {id} })
        return true
      end
    end
  end,
  on_use = chengyeRecordOnUse
})

chengye:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chengye.name) then
      local ids = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.from ~= player then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            local delayedTrickMoveByUse = not move.from and move.moveReason == fk.ReasonUse and card.sub_type == Card.SubtypeDelayedTrick
            if
              (
                delayedTrickMoveByUse or
                (
                  move.from and
                  table.contains({ Card.PlayerEquip, Card.PlayerHand, Card.PlayerJudge }, info.fromArea) and
                  (card.sub_type == Card.SubtypeDelayedTrick or card.type == Card.TypeEquip)
                )
              ) and
              player.room:getCardArea(info.cardId) == Card.DiscardPile and
              table.contains(getLackClassics(player), getClassicsType(info.cardId))
            then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
      if #ids > 0 then
        event:setCostData(self, { cards = ids })
        return true
      end
    end
  end,
  on_use = chengyeRecordOnUse,
})

chengye:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(chengye.name) and
      target == player and
      player.phase == Player.Play and
      #player:getPile("chengye_classic") == 6
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = chengye.name
    local room = player.room
    room:notifySkillInvoked(player, skillName, "drawcard")
    player:broadcastSkillInvoke(skillName, 3)
    room:obtainCard(player, player:getPile("chengye_classic"), true, fk.ReasonPrey, player, skillName)
  end,
})

return chengye
