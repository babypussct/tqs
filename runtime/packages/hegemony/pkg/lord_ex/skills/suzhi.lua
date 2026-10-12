local suzhi = fk.CreateSkill {
  name = "ld__suzhi",
  tags = { Skill.Compulsory },
  related_skills = { "ld__simazhao__fankui" },
}

Fk:loadTranslationTable {
  ["ld__suzhi"] = "夙智",
  [":ld__suzhi"] = "锁定技，你的回合内：1.你执行【杀】或【决斗】的效果而造成伤害时，此伤害+1；2.你使用非转化锦囊牌时摸一张牌且无距离限制；" ..
      "3.其他角色的牌被弃置后，你获得其一张牌。当你于一回合内触发上述效果三次后，此技能于此回合内失效。回合结束时，你获得〖反馈〗直至回合开始。",
  ["@ld__suzhi-turn"] = "夙智",
  ["@@ld__fankui_simazhao"] = "夙智 反馈",

  ["$ld__suzhi1"] = "敌军势大与否，无碍我自计定施。",
  ["$ld__suzhi2"] = "汝竭力强攻，也只是徒燥军心。",
}

--用锦囊摸一张牌
suzhi:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(suzhi.name) and player:getMark("@ld__suzhi-turn") < 3 and player.room.current == player then
      return target == player and data.card.type == Card.TypeTrick and
      (not data.card:isConverted() or #data.card.subcards == 0)
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ld__suzhi-turn", 1)
    player:drawCards(1, suzhi.name)
  end,
})

--加伤
suzhi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(suzhi.name) and player:getMark("@ld__suzhi-turn") < 3 and player.room.current == player then
      return target == player and data.card and (data.card.trueName == "slash" or data.card.name == "duel") and
      not data.chain
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@ld__suzhi-turn", 1)
    room:doIndicate(player.id, { data.to.id })
    data:changeDamage(1)
  end,
})

--丢牌得牌
suzhi:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(suzhi.name) and player:getMark("@ld__suzhi-turn") < 3 and player.room.current == player then
      for _, move in ipairs(data) do
        if move.from and move.from ~= player and move.moveReason == fk.ReasonDiscard then
          --FIXME:国战暂时没有同时两名角色弃置牌的情况，先鸽
          local from = move.from
          if from and not (from.dead or from:isNude()) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                event:setCostData(self, { from = move.from })
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@ld__suzhi-turn", 1)
    room:doIndicate(player.id, { event:getCostData(self).from.id })
    local card = room:askToChooseCard(player, {
      target = event:getCostData(self).from,
      flag = "he",
      skill_name = suzhi.name,
    })
    room:obtainCard(player, card, false, fk.ReasonPrey)
  end,
})

suzhi:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(suzhi.name) and player:getMark("@ld__suzhi-turn") < 3 and player.room.current == player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ld__fankui_simazhao", 1)
    room:handleAddLoseSkills(player, "ld__simazhao__fankui", nil)
    return false
  end,
})

suzhi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@ld__fankui_simazhao") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ld__fankui_simazhao", 0)
    room:handleAddLoseSkills(player, "-ld__simazhao__fankui", nil)
  end,
})

suzhi:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card)
    return card and player:hasSkill(suzhi.name) and player.phase ~= Player.NotActive and
        player:getMark("@ld__suzhi-turn") < 3 and
        card.type == Card.TypeTrick and (not card:isConverted() or #card.subcards == 0) and
        player:hasShownSkill(suzhi.name)
  end,
})

return suzhi
