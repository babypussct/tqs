local changjun = fk.CreateSkill {
  name = "v11__changjun",
}

Fk:loadTranslationTable{
  ["v11__changjun"] = "畅军",
  [":v11__changjun"] = "出牌阶段开始时，你可以将至多X张牌置于你的武将牌上（X为你的登场角色序数），"..
  "你可以将与“畅军”牌花色相同的牌当【杀】或【闪】使用或打出；准备阶段，你获得所有“畅军”牌。",

  ["#v11__changjun"] = "畅军：你可以将与“畅军”牌花色相同的牌当【杀】或【闪】使用或打出",
  ["#v11__changjun-card"] = "畅军：你可以将至多 %arg 张牌置于武将牌上，<br>你可将与“畅军”牌花色相同的牌当【杀】或【闪】使用或打出",
}

changjun:addEffect("viewas", {
  pattern = "slash,jink",
  prompt = "#v11__changjun",
  interaction = function(self, player)
    local all_names = {{"slash","jink"}}
    local names = player:getViewAsCardNames(changjun.name, all_names)
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  handly_pile = true,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and
      table.find(player:getPile(changjun.name), function (id)
        return Fk:getCardById(id).suit == Fk:getCardById(to_select).suit
      end)
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data or #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = changjun.name
    return card
  end,
  enabled_at_play = function(self, player)
    return #player:getPile(changjun.name) > 0
  end,
  enabled_at_response = function(self, player)
    return #player:getPile(changjun.name) > 0
  end,
})

changjun:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(changjun.name) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local x = 1 + tonumber((room:getBanner(player.role == "lord" and "@firstFallen" or "@secondFallen") or "0")[1])
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = x,
      prompt = "#v11__changjun-card:::"..x,
      skill_name = changjun.name,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(changjun.name, event:getCostData(self).cards, true, changjun.name)
  end,
})

changjun:addEffect(fk.EventPhaseStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and #player:getPile(changjun.name) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, player:getPile(changjun.name), true, fk.ReasonJustMove, player, changjun.name)
  end,
})

return changjun
