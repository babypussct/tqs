local chengfeng = fk.CreateSkill {
  name = "chengfeng",
}

Fk:loadTranslationTable{
  ["chengfeng"] = "承奉",
  [":chengfeng"] = "每回合限一次，你可以将一张红色“匡祚”牌当【闪】或黑色“匡祚”牌当【无懈可击】对即将对你生效的牌使用，此牌结算后，"..
  "若“匡祚”不足两种颜色，你可以将牌堆顶一张牌置为“匡祚”。",

  ["#chengfeng"] = "承奉：你可以将红色“匡祚”当【闪】、黑色“匡祚”当【无懈可击】对即将对你生效的牌使用",
  ["#chengfeng-put"] = "承奉：是否将牌堆顶一张牌置为“匡祚”？",

  ["$chengfeng1"] = "臣簇于君侧，为耳目，为股肱。",
  ["$chengfeng2"] = "承臣子之任，奉天子之统。",
}

chengfeng:addEffect("viewas", {
  anim_type = "defensive",
  pattern = "jink,nullification",
  prompt = "#chengfeng",
  expand_pile = "kuangzuo",
  filter_pattern = function (self, player, card_name)
    local vs_pattern = {
      max_num = 1,
      min_num = 1,
      pattern = ".|.|.|kuangzuo",
    }
    if card_name == "jink" then
      vs_pattern.pattern = ".|.|red|kuangzuo"
    elseif card_name == "jink" then
      vs_pattern.pattern = ".|.|black|kuangzuo"
    end
    return vs_pattern
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card
    if Fk:getCardById(cards[1]).color == Card.Red then
      card = Fk:cloneCard("jink")
    elseif Fk:getCardById(cards[1]).color == Card.Black then
      card = Fk:cloneCard("nullification")
    end
    card.skillName = chengfeng.name
    card:addSubcard(cards[1])
    return card
  end,
  after_use = function(self, player, use)
    local room = player.room
    if not player.dead then
      local colors = {}
      for _, id in ipairs(player:getPile("kuangzuo")) do
        table.insertIfNeed(colors, Fk:getCardById(id).color)
      end
      table.removeOne(colors, Card.NoColor)
      if #colors < 2 and room:askToSkillInvoke(player, {
        skill_name = chengfeng.name,
        prompt = "#chengfeng-put",
      }) then
        player:addToPile("kuangzuo", room:getNCards(1), true, chengfeng.name, player)
      end
    end
  end,
  times = function (self, player)
    return 1 - player:usedSkillTimes(chengfeng.name, Player.HistoryTurn)
  end,
  enabled_at_response = function(self, player, response)
    if not response and player:usedSkillTimes(chengfeng.name, Player.HistoryTurn) == 0 then
      for _, id in ipairs(player:getPile("kuangzuo")) do
        if Fk:getCardById(id).color == Card.Red and #player:getViewAsCardNames(chengfeng.name, {"jink"}, {id}) > 0 then
          return true
        end
        if Fk:getCardById(id).color == Card.Black and #player:getViewAsCardNames(chengfeng.name, {"nullification"}, {id}) > 0
          and player:getMark("chengfeng_activated") ~= 0 then
          return true
        end
      end
    end
  end,
  enabled_at_nullification = function (self, player, data)
    return data and data.to == player and player:usedSkillTimes(chengfeng.name, Player.HistoryTurn) == 0 and
      table.find(player:getPile("kuangzuo"), function (id)
        return Fk:getCardById(id).color == Card.Black
      end) ~= nil
  end,
})

chengfeng:addEffect(fk.HandleAskForPlayCard, {
  can_refresh = function(self, event, target, player, data)
    if data.afterRequest and (data.extra_data or {}).chengfeng_effected then
      return player:getMark("chengfeng_activated") ~= 0
    end

    return
      player:hasSkill(chengfeng.name) and
      data.eventData and
      data.eventData.to == player and
      Exppattern:Parse(data.pattern):match(Fk:cloneCard("nullification"))
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.afterRequest then
      room:setPlayerMark(player, "chengfeng_activated", 0)
    else
      room:setPlayerMark(player, "chengfeng_activated", 1)
      data.extra_data = data.extra_data or {}
      data.extra_data.chengfeng_effected = true
    end
  end,
})

return chengfeng
