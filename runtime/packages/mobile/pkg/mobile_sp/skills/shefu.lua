
local shefu = fk.CreateSkill{
  name = "mobile__shefu",
  derived_piles = "$mobile__shefu",
}

Fk:loadTranslationTable{
  ["mobile__shefu"] = "设伏",
  [":mobile__shefu"] = "结束阶段，你可以扣置一张牌，并记录一个未设伏的非装备牌名，称为“伏兵”；"..
  "你的回合外其他角色使用牌时，你可以移去一张记录牌名相同的“伏兵”，令此牌无效并摸一张牌。",

  ["#mobile__shefu-ask"] = "设伏：你可以将一张牌扣置为“伏兵”",
  ["$mobile__shefu"] = "伏兵",
  ["@mobile__shefu"] = "伏兵",
  ["#mobile__shefu-invoke"] = "设伏：是否令 %dest 使用的%arg无效并摸一张牌？",

  ["$mobile__shefu1"] = "待敌不备之机，便是其命丧之时。",
  ["$mobile__shefu2"] = "伏兵之要，神出而鬼行。",
}

shefu:addAuxActiveSkill("#mobile__shefu_active", {
  card_num = 1,
  target_num = 0,
  interaction = function (self, player)
    local all_names = Fk:getAllCardNames("btd", true)
    local names = table.filter(all_names, function (name)
      return not table.find(player:getPile("$mobile__shefu"), function (id)
        return Fk:getCardById(id):getMark("@mobile__shefu") == Fk:translate(name)
      end)
    end)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0
  end,
})

shefu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shefu.name) and player.phase == Player.Finish and
      not player:isNude() and #player:getPile("$mobile__shefu") < #Fk:getAllCardNames("btd")
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#mobile__shefu_active",
      prompt = "#mobile__shefu-ask",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, { cards = dat.cards, choice = dat.interaction })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = event:getCostData(self).cards or {}
    local name = event:getCostData(self).choice
    room:moveCardTo(card, Card.PlayerSpecial, player, fk.ReasonJustMove, shefu.name, "$mobile__shefu", false, player,
      { "@mobile__shefu", Fk:translate(name) })
  end,
})

shefu:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shefu.name) and
      target ~= player and player.room:getCurrent() ~= player and
      (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and
      data:isUsingHandcard(target) and
      table.find(player:getPile("$mobile__shefu"), function (id)
        return Fk:getCardById(id):getMark("@mobile__shefu") == Fk:translate(data.card.trueName)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = shefu.name,
      prompt = "#mobile__shefu-invoke::"..target.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.toCard = nil
    data:removeAllTargets()
    local id = table.filter(player:getPile("$mobile__shefu"), function (id)
      return Fk:getCardById(id):getMark("@mobile__shefu") == Fk:translate(data.card.trueName)
    end)
    room:moveCardTo(id, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, shefu.name, nil, true, player)
    if not player.dead then
      player:drawCards(1, shefu.name)
    end
  end,
})

shefu:addEffect(fk.AfterCardsMove, {
  can_refresh = Util.TrueFunc,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from then
        for _, info in ipairs(move.moveInfo) do
          if info.fromSpecialName == "$mobile__shefu" then
            player.room:setCardMark(Fk:getCardById(info.cardId), "@mobile__shefu", 0)
          end
        end
      end
    end
  end,
})

return shefu
