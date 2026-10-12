local shuangxiong = fk.CreateSkill{
  name = "m_ex__shuangxiong",
}

Fk:loadTranslationTable{
  ["m_ex__shuangxiong"] = "双雄",
  [":m_ex__shuangxiong"] = "摸牌阶段，你可以改为亮出牌堆顶两张牌，你获得其中一张牌，然后本回合你可以将颜色与之不同的手牌当【决斗】使用；"..
  "当你受到以此法使用的【决斗】的伤害后，你可以获得其他角色响应此【决斗】打出的【杀】。",

  ["#m_ex__shuangxiong-get"] = "双雄：获得其中一张牌，本回合可以将不同颜色的手牌当【决斗】使用",
  ["#m_ex__shuangxiong-invoke"] = "双雄：是否放弃摸牌，改为亮出牌堆顶两张牌并获得其中一张？",
  ["#m_ex__shuangxiong-prey"] = "双雄：是否获得对方打出的【杀】？",

  ["$m_ex__shuangxiong1"] = "哥哥，且看我与赵云一战！/且与他战个五十回合！",
  ["$m_ex__shuangxiong2"] = "此战，如有你我一人在此，何惧华雄！/定叫他有去无回！",
}

shuangxiong:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "duel",
  prompt = function(self, player)
    local mark = player:getMark("@shuangxiong-turn")
    local color = ""
    if #mark == 1 then
      if mark[1] == "red" then
        color = "black"
      else
        color = "red"
      end
    end
    return "#shuangxiong:::"..color
  end,
  handly_pile = true,
  filter_pattern = function (self, player, card_name, selected)
    local colors = player:getTableMark("@shuangxiong-turn")
    if #colors > 0 then
      local _colors = {}
      if table.contains(colors, "red") then
        table.insert(_colors, "black")
      end
      if table.contains(colors, "black") then
        table.insert(_colors, "red")
      end
      return {
        max_num = 1,
        min_num = 1,
        pattern = ".|.|" .. table.concat(_colors, ",") .."|^equip",
      }
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("duel")
    card:addSubcard(cards[1])
    card.skillName = shuangxiong.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@shuangxiong-turn") ~= 0
  end,
  enabled_at_response = function(self, player, response)
    return player:getMark("@shuangxiong-turn") ~= 0 and not response
  end,
})
shuangxiong:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shuangxiong.name) and player.phase == Player.Draw
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    local cards = room:getNCards(2)
    room:turnOverCardsFromDrawPile(player, cards, shuangxiong.name)
    room:delay(1000)
    local card = room:askToChooseCard(player, {
      target = player,
      flag = { card_data = {{ shuangxiong.name, cards }} },
      skill_name = shuangxiong.name,
      prompt = "#m_ex__shuangxiong-get",
    })
    local color = Fk:getCardById(card):getColorString()
    if color ~= "nocolor" then
      room:addTableMarkIfNeed(player, "@shuangxiong-turn", color)
    end
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, shuangxiong.name, nil, true, player)
    room:cleanProcessingArea(cards)
  end,
})
shuangxiong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shuangxiong.name) and
      data.card and table.contains(data.card.skillNames, shuangxiong.name) then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event == nil then return end
      local cards = {}
      room.logic:getEventsByRule(GameEvent.RespondCard, 1, function (e)
        local response = e.data
        if response.responseToEvent and response.responseToEvent.card and
          table.contains(response.responseToEvent.card.skillNames, shuangxiong.name) and
          response.responseToEvent.from == player and
          response.from ~= player then
          local ids = response.card:isVirtual() and response.card.subcards or { response.card.id }
          for _, id in ipairs(ids) do
            if room:getCardArea(id) == Card.DiscardPile then
              table.insertIfNeed(cards, id)
            end
          end
        end
      end, use_event.id)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = shuangxiong.name,
      prompt = "#m_ex__shuangxiong-prey",
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, player, fk.ReasonJustMove, shuangxiong.name, nil, true, player)
  end,
})

return shuangxiong
