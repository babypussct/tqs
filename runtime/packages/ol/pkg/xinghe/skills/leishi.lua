local leishi = fk.CreateSkill{
  name = "leishi",
}

Fk:loadTranslationTable{
  ["leishi"] = "雷噬",
  [":leishi"] = "出牌阶段限X次（X为你上次发动〖狂信〗展示牌的数量），你使用本回合展示过的牌结算完成后，"..
    "可进行一次判定并获得判定牌，若判定结果与使用牌的花色：相同，你对一名角色造成一点雷电伤害；"..
    "不同，你展示一张牌，本回合下次判定时，若此牌在你的手牌区内，将此牌作为判定牌。",

  ["#leishi-choose"] = "雷噬：对一名角色造成1点雷电伤害",
  ["#leishi-show"] = "雷噬：请展示一张手牌，本回合下次判定改为用此牌作为判定牌",
  ["@@leishi-inhand-turn"] = "展示",
  ["@@leishi_judge-inhand-turn"] = "雷噬",

  ["$leishi1"] = "雷芒裂苍穹，群山已撼，试问谁能挡？	",
  ["$leishi2"] = "天公降怒，雷光闪处，万物皆夷灭！",
}

leishi:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  times = function(self, player)
    return player.phase == Player.Play and player:getMark("kuangxin") - player:usedSkillTimes(leishi.name, Player.HistoryPhase) or -1
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(leishi.name) and player.phase == Player.Play and
      player:usedSkillTimes(leishi.name, Player.HistoryPhase) < player:getMark("kuangxin") and
      data:hasMark("@@leishi-inhand-turn", true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pattern = ".|.|"..data.card:getSuitString()
    if data.card.suit == Card.NoSuit then
      pattern = "false"
    end
    local judge = {
      who = player,
      reason = leishi.name,
      pattern = pattern,
    }
    room:judge(judge)
    if player.dead then return end
    if judge:matchPattern() then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        skill_name = leishi.name,
        prompt = "#leishi-choose",
        cancelable = false,
      })[1]
      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = leishi.name,
      }
    elseif not player:isKongcheng() then
      local cards = player:getCardIds("h")
      if #cards > 1 then
        cards = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = leishi.name,
          prompt = "#leishi-show",
          cancelable = false,
        })
      end
      room:setCardMark(Fk:getCardById(cards[1]), "@@leishi_judge-inhand-turn", 1)
      player:showCards(cards)
    end
  end,
})

leishi:addEffect(fk.FinishJudge, {
  mute = true,
  is_delay_effect = true,
  priority = 5,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.reason == leishi.name and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove, nil, leishi.name)
  end,
})

leishi:addEffect(fk.CardShown, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(leishi.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local handCards = player:getCardIds("h")
    for _, id in ipairs(data.cardIds) do
      if table.contains(handCards, id) then
        room:setCardMark(Fk:getCardById(id), "@@leishi-inhand-turn", 1)
      end
    end
  end,
})

leishi:addEffect(fk.StartJudge, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.card == nil and not player.dead and table.find(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getMark("@@leishi_judge-inhand-turn") > 0
    end)
  end,
  on_use = function(self, event, target, player, data)
    local handCards = player:getCardIds("h")
    for _, id in ipairs(handCards) do
      local card = Fk:getCardById(id, true)
      if card:getMark("@@leishi_judge-inhand-turn") > 0 then
        --FIXME:应在技能中移动到处理区（变成虚拟牌？）
        data.card = card
        return
      end
    end
  end,
})

return leishi
