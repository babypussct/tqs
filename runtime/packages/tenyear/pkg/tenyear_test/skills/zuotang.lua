
local zuotang = fk.CreateSkill {
  name = "zuotang",
}

Fk:loadTranslationTable{
  ["zuotang"] = "坐堂",
  [":zuotang"] = "每轮限两次，其他角色出牌阶段开始时，你可以令其交给你至多两张手牌，你可以交给其等量手牌并令其回复1点体力，"..
  "若其未交给你牌，直到其下个回合开始，其受到伤害后失去1点体力。",

  ["#zuotang-invoke"] = "坐堂：令 %dest 交给你牌，你可以交给其等量牌并令其回复1点体力，若其不交出则受到伤害后失去体力",
  ["#zuotang-give"] = "坐堂：交给 %src 至多两张手牌，若不交出则受到伤害后失去体力",
  ["@@zuotang"] = "坐堂",
  ["#zuotang-ask"] = "坐堂：你可以交给 %dest %arg张手牌并令其回复1点体力",

  ["$zuotang1"] = "",
  ["$zuotang2"] = "",
}

zuotang:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(zuotang.name) and target.phase == Player.Play and
      not target.dead and player:usedEffectTimes(self.name, Player.HistoryRound) < 2
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zuotang.name,
      prompt = "#zuotang-invoke::"..target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(target, {
      min_num = 1,
      max_num = 2,
      include_equip = false,
      skill_name = zuotang.name,
      prompt = "#zuotang-give:"..player.id,
      cancelable = true,
    })
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, zuotang.name, nil, false, target)
      if player:getHandcardNum() < #cards or target.dead then return end
      cards = room:askToCards(player, {
        min_num = #cards,
        max_num = #cards,
        include_equip = false,
        skill_name = zuotang.name,
        prompt = "#zuotang-ask::"..target.id..":"..#cards,
        cancelable = true,
      })
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, zuotang.name, nil, false, player)
        if not target.dead then
          room:recover{
            who = target,
            num = 1,
            recoverBy = player,
            skillName = zuotang.name,
          }
        end
      end
    else
      room:addTableMark(target, "@@zuotang", player)
    end
  end,
})

zuotang:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(zuotang.name) and
      table.contains(target:getTableMark("@@zuotang"), player)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = { target } })
    return true
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(target, 1, zuotang.name, player)
  end,
})

zuotang:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zuotang", 0)
  end,
})

return zuotang
