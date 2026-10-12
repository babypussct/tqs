
local jieyuan = fk.CreateSkill {
  name = "mobile__jieyuan",
  dynamic_desc = function (self, player, lang)
    if player:getMark("mobile__jieyuan_red") > 0 then
      return "mobile__jieyuan_red"
    elseif player:getMark("mobile__jieyuan_black") > 0 then
      return "mobile__jieyuan_black"
    end
  end,
}

Fk:loadTranslationTable {
  ["mobile__jieyuan"] = "竭缘",
  [":mobile__jieyuan"] = "当你造成伤害时，你可以选择一项：1.获得牌堆中的一张黑色牌；2.弃置一张黑色牌，此伤害+1。"..
  "当你受到伤害时，你可以选择一项：1.获得牌堆中的一张红色牌；2.弃置一张红色牌，此伤害-1。"..
  "背水：删除另一个发动时机下的所有效果并升级此技能，获得牌数改为两张，伤害增减数改为2。",

  [":mobile__jieyuan_black"] = "当你造成伤害时，你可以选择一项：1.获得牌堆中的两张黑色牌；2.弃置一张黑色牌，此伤害+2。",
  [":mobile__jieyuan_red"] = "当你受到伤害时，你可以选择一项：1.获得牌堆中的两张红色牌；2.弃置一张红色牌，此伤害-2。",

  ["#mobile__jieyuan1-invoke"] = "竭缘：你对 %dest 造成伤害，你可以选择一项",
  ["#mobile__jieyuan2-invoke"] = "竭缘：你受到伤害，可以选择一项",
  ["mobile__jieyuan_draw"] = "摸%arg张%arg2牌",
  ["mobile__jieyuan_discard"] = "弃置一张%arg2牌，此伤害%arg",
  ["mobile__jieyuan_beishui"] = "背水：升级此技能",

  ["$mobile__jieyuan1"] = "你我之缘，本就是个罪孽。",
  ["$mobile__jieyuan2"] = "是时候，做个了结了。",
}

jieyuan:addAuxActiveSkill("#mobile__jieyuan_active", {
  interaction = function (self, player)
    local event = self.event
    local n = (player:getMark("mobile__jieyuan_black") > 0 or player:getMark("mobile__jieyuan_red") > 0) and 2 or 1
    local choices = {}
    if event == 1 then
      choices = { "mobile__jieyuan_draw:::"..n..":black", "mobile__jieyuan_discard:::+"..n..":black" }
    else
      choices = { "mobile__jieyuan_draw:::"..n..":red", "mobile__jieyuan_discard:::-"..n..":red" }
    end
    if n == 1 then
      table.insert(choices, "mobile__jieyuan_beishui")
    end
    return UI.ComboBox { choices = choices }
  end,
  min_card_num = 0,
  max_card_num = 0,
  target_num = 0,
  card_filter = function (self, player, to_select, selected)
    if #selected == 0 and not player:prohibitDiscard(to_select) and
      self.interaction.data:startsWith("mobile__jieyuan_discard") then
      if self.event == 1 then
        return Fk:getCardById(to_select).color == Card.Black
      else
        return Fk:getCardById(to_select).color == Card.Red
      end
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if self.interaction.data:startsWith("mobile__jieyuan_discard") then
      return #selected_cards == 1
    else
      return #selected_cards == 0
    end
  end,
})

jieyuan:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieyuan.name) and
      player:getMark("mobile__jieyuan_red") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#mobile__jieyuan_active",
      prompt = "#mobile__jieyuan1-invoke::"..data.to.id,
      extra_data = {
        event = 1,
      }
    })
    if success and dat then
      event:setCostData(self, { cards = dat.cards, choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local n = player:getMark("mobile__jieyuan_black") > 0 and 2 or 1
    if choice:startsWith("mobile__jieyuan_discard") then
      room:throwCard(event:getCostData(self).cards, jieyuan.name, player, player)
      data:changeDamage(n)
    else
      local cards = room:getCardsFromPileByRule(".|.|black", n)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, jieyuan.name, nil, false, player)
        if player.dead then return end
      end
    end
    if choice == "mobile__jieyuan_beishui" then
      if #room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|black",
        include_equip = true,
        skill_name = jieyuan.name,
        cancelable = true,
        prompt = "mobile__jieyuan_discard:::" .. "+" .. n .. ":black",
      }) > 0 then
        data:changeDamage(n)
      end
      if player:hasSkill(jieyuan.name, true) then
        room:setPlayerMark(player, "mobile__jieyuan_black", 1)
      end
    end
  end,
})

jieyuan:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieyuan.name) and
      player:getMark("mobile__jieyuan_black") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#mobile__jieyuan_active",
      prompt = "#mobile__jieyuan2-invoke",
      extra_data = {
        event = 2,
      }
    })
    if success and dat then
      event:setCostData(self, { cards = dat.cards, choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local n = player:getMark("mobile__jieyuan_red") > 0 and 2 or 1
    if choice:startsWith("mobile__jieyuan_discard") then
      room:throwCard(event:getCostData(self).cards, jieyuan.name, player, player)
      data:changeDamage(-n)
    else
      local cards = room:getCardsFromPileByRule(".|.|red", n)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, jieyuan.name, nil, false, player)
        if player.dead then return end
      end
    end
    if choice == "mobile__jieyuan_beishui" then
      if #room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|red",
        include_equip = true,
        skill_name = jieyuan.name,
        cancelable = true,
        prompt = "mobile__jieyuan_discard:::"..-n..":red",
      }) > 0 then
        data:changeDamage(-n)
      end
      if player:hasSkill(jieyuan.name, true) then
        room:setPlayerMark(player, "mobile__jieyuan_red", 1)
      end
    end
  end,
})

return jieyuan
