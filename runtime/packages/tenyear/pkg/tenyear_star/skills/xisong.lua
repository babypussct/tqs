
local xisong = fk.CreateSkill {
  name = "xisong",
}

Fk:loadTranslationTable{
  ["xisong"] = "悉诵",
  [":xisong"] = "每轮限一次，其他角色的出牌阶段开始时，你可以观看其手牌，若如此做，此阶段结束时，你声明一个类别、花色和点数并展示其手牌，"..
  "若其中有完全符合你声明的牌，此技能视为未发动过，然后其弃置此牌，若你能使用则使用之。",

  ["#xisong-invoke"] = "悉诵：你可以观看 %dest 的手牌",
  ["#xisong-type"] = "悉诵：声名类别，若 %dest 手牌中有完全符合的牌则执行效果",
  ["#xisong-suit"] = "悉诵：声名花色，若 %dest 手牌中有完全符合的牌则执行效果",
  ["#xisong-number"] = "悉诵：声名点数，若 %dest 手牌中有完全符合的牌则执行效果",
  ["#xisong-use"] = "悉诵：请使用此牌",

  ["$xisong1"] = "一目十行，速而不漏，博而不杂。",
  ["$xisong2"] = "张目可阅三千牍，弹舌能辨二百误！",
}

xisong:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
  return target ~= player and player:hasSkill(xisong.name) and target.phase == Player.Play and
    not target:isKongcheng() and player:usedSkillTimes(xisong.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = xisong.name,
      prompt = "#xisong-invoke::"..target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "xisong-phase", target)
    room:viewCards(player, {
      cards = target:getCardIds("h"),
      skill_name = xisong.name,
      prompt = "$ViewCardsFrom:"..target.id,
    })
  end,
})

xisong:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
  return player:hasSkill(xisong.name) and player:getMark("xisong-phase") == target and
    target.phase == Player.Play and not target:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local type = room:askToChoice(player, {
      skill_name = xisong.name,
      choices = { "basic", "trick", "equip" },
      prompt = "#xisong-type::"..target.id,
    })
    local suit = room:askToChoice(player, {
      skill_name = xisong.name,
      choices = { "log_spade", "log_heart", "log_club", "log_diamond" },
      prompt = "#xisong-suit::"..target.id,
    })
    local number = room:askToChoice(player, {
      skill_name = xisong.name,
      choices = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" },
      prompt = "#xisong-number::"..target.id,
    })
    local card = table.find(target:getCardIds("h"), function (id)
      local card = Fk:getCardById(id)
      return card:getTypeString() == type and card:getSuitString(true) == suit and card:getNumberStr() == number
    end)
    if card then
      player:setSkillUseHistory(xisong.name, 0, Player.HistoryRound)
      room:throwCard(card, xisong.name, target, target)
      if not player.dead and table.contains(room.discard_pile, card) then
        room:askToUseRealCard(player, {
          pattern = { card },
          skill_name = xisong.name,
          prompt = "#xisong-use",
          expand_pile = { card },
          cancelable = false,
        })
      end
    end
  end,
})

return xisong
