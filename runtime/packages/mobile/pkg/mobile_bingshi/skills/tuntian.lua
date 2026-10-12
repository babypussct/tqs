local tuntian = fk.CreateSkill({
  name = "m_shi__tuntian",
  tags = { Skill.Charge },
})

Fk:loadTranslationTable{
  ["m_shi__tuntian"] = "屯田",
  [":m_shi__tuntian"] = "蓄力技（0/0），当你失去非伤害牌后，你获得1点蓄力点；出牌阶段限一次，你可以消耗至少1点蓄力点，" ..
  "令至多等量名角色随机获得一张<font color='red'>♥</font>牌；一名角色的回合开始时，若你蓄力点已满，你摸一张牌且蓄力点上限+1。",

  ["#m_shi__tuntian"] = "屯田：你可以消耗任意点蓄力点，令至多等量名角色各获得1张<font color='red'>♥</font>牌",
  ["#m_shi__tuntian-choose"] = "屯田：请选择至多%arg名角色各获得1张<font color='red'>♥</font>牌",

  ["$m_shi__tuntian1"] = "屯田开渠，为军农要用。",
  ["$m_shi__tuntian2"] = "农者，胜之本也。",
}

local U = require "packages.utility.utility"

tuntian:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#m_shi__tuntian",
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    return UI.Spin { from = 1, to = player:getMark("skill_charge") }
  end,
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0 and player:getMark("skill_charge") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = tuntian.name
    local player = effect.from
    local num = self.interaction.data

    U.skillCharged(player, -num)
    local tos = room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = num,
        targets = room:getAlivePlayers(false),
        skill_name = skillName,
        prompt = "#m_shi__tuntian-choose:::" .. num,
      }
    )

    if #tos > 0 then
      room:sortByAction(tos)
      table.forEach(tos, function(p)
        local heartCards = room:getCardsFromPileByRule(".|.|heart")
        if p:isAlive() and #heartCards > 0 then
          room:obtainCard(p, heartCards, false, fk.ReasonPrey, p, skillName)
        end
      end)
    end
  end,
})

tuntian:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tuntian.name) and player:getMark("skill_charge") < player:getMark("skill_charge_max") then
      for _, move in ipairs(data) do
        if
          move.from == player and
          not (move.to == player and table.contains({ Card.PlayerHand, Card.PlayerEquip }, move.toArea))
        then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if
              (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              not (card.is_damage_card or card.name == "lightning") and
              not (card.type == Card.TypeEquip and move.moveReason == fk.ReasonUse)
            then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    U.skillCharged(player, 1)
  end,
})

tuntian:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return
      player:hasSkill(tuntian.name) and
      player:getMark("skill_charge") >= player:getMark("skill_charge_max")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, tuntian.name)
    if player:isAlive() then
      U.skillCharged(player, 0, 1)
      player.room:addPlayerMark(player, "m_shi__tuntian_max")
    end
  end,
})

tuntian:addAcquireEffect(function (self, player)
  U.skillCharged(player, 0, 0)
end)

tuntian:addLoseEffect(function (self, player)
  U.skillCharged(player, 0, -player:getMark("m_shi__tuntian_max"))
end)

return tuntian
