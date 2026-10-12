
local shuangxiong = fk.CreateSkill {
  name = "hs__shuangxiong",
}

Fk:loadTranslationTable{
  ["hs__shuangxiong"] = "双雄",
  [":hs__shuangxiong"] = "出牌阶段开始时，你可以令一名角色弃置一张牌，本回合你可以将一张与弃置牌颜色不同的手牌当【决斗】使用。",

  ["@hs__shuangxiong-turn"] = "双雄",
  ["#hs__shuangxiong"] = "双雄：你可以将一张%arg手牌当【决斗】使用",
  ["#hs__shuangxiong-choose"] = "双雄：令一名角色弃置一张牌，此阶段你可以将与之颜色不同的手牌当【决斗】使用",
  ["#hs__shuangxiong-discard"] = "双雄：请弃置一张牌，此阶段 %src 可以将与之颜色不同的手牌当【决斗】使用",

  ["$hs__shuangxiong1"] = "",
  ["$hs__shuangxiong2"] = "",
}

shuangxiong:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "duel",
  prompt = function(self, player)
    local color = "red"
    if player:getMark("@hs__shuangxiong-turn") == "red" then
      color = "black"
    end
    return "#hs__shuangxiong:::"..color
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    local color = Fk:getCardById(to_select):getColorString()
    if color == "red" then
      color = "black"
    elseif color == "black" then
      color = "red"
    else
      return false
    end
    return table.contains(player:getHandlyIds(), to_select) and player:getMark("@hs__shuangxiong-turn") == color
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("duel")
    c:addSubcard(cards[1])
    c.skillName = shuangxiong.name
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@hs__shuangxiong-turn") ~= 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:getMark("@hs__shuangxiong-turn") ~= 0
  end,
})

shuangxiong:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shuangxiong.name) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#hs__shuangxiong-choose",
      skill_name = shuangxiong.name,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToDiscard(to, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = shuangxiong.name,
      prompt = "#hs__shuangxiong-discard:"..player.id,
      cancelable = false,
    })
    if #card > 0 and not player.dead then
      local color = Fk:getCardById(card[1]):getColorString()
      if color ~= "nocolor" then
        room:setPlayerMark(player, "@hs__shuangxiong-turn", color)
      end
    end
  end,
})

return shuangxiong
