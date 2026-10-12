local qingzheng = fk.CreateSkill {
  name = "mobile_qianlong__qingzheng",
  tags = { Skill.Permanent },
}

Fk:loadTranslationTable{
  ["mobile_qianlong__qingzheng"] = "清正",
  [":mobile_qianlong__qingzheng"] = "持恒技，出牌阶段开始时，你可以选择一名有手牌的其他角色，你弃置一种花色的所有手牌，" ..
  "然后观看其手牌并选择一种花色的牌，其弃置所有该花色的手牌。若如此做且你以此法弃置的牌数大于其弃置的手牌，你对其造成1点伤害。",

  ["#mobile_qianlong__qingzheng-card"] = "清正：你可以弃置一种花色的手牌，观看一名角色的手牌并弃置其中一种花色",
  ["#mobile_qianlong__qingzheng-choose"] = "清正：选择一名其他角色，观看其手牌并弃置其中一种花色",
  ["#mobile_qianlong__qingzheng-throw"] = "清正：弃置 %dest 一种花色的手牌，若弃置张数小于%arg，对其造成伤害",

  ["$mobile_qianlong__qingzheng1"] = "朕虽不德，昧于大道，思与宇内共臻兹路。",
  ["$mobile_qianlong__qingzheng2"] = "愿遵前人教诲，为一国明帝贤君。",
}

local U = require "packages.utility.utility"

qingzheng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingzheng.name) and player.phase == Player.Play and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).suit ~= Card.NoSuit
      end) and table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isKongcheng()
    end)
    local listNames = {"log_spade", "log_club", "log_heart", "log_diamond"}
    local listCards = { {}, {}, {}, {} }
    for _, id in ipairs(player:getCardIds("h")) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit and not player:prohibitDiscard(id) then
        table.insertIfNeed(listCards[suit], id)
      end
    end
    local choices = U.askForChooseCardList(room, player, listNames, listCards, 1, 1, qingzheng.name, "#mobile_qianlong__qingzheng-card")
    if #choices == 1 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = qingzheng.name,
        prompt = "#mobile_qianlong__qingzheng-choose",
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to, choice = choices[1]})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local to = event:getCostData(self).tos[1]
    local my_throw = table.filter(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(Fk:getCardById(id)) and Fk:getCardById(id):getSuitString(true) == choice
    end)
    room:throwCard(my_throw, qingzheng.name, player, player)
    if player.dead then return end
    local to_throw = {}
    local listNames = {"log_spade", "log_club", "log_heart", "log_diamond"}
    local listCards = { {}, {}, {}, {} }
    local can_throw
    for _, id in ipairs(to:getCardIds("h")) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(listCards[suit], id)
        can_throw = true
      end
    end
    if can_throw then
      choice = U.askForChooseCardList(room, player, listNames, listCards, 1, 1, qingzheng.name,
        "#mobile_qianlong__qingzheng-throw::"..to.id..":"..#my_throw, false, false)
      if #choice == 1 then
        to_throw = table.filter(to:getCardIds("h"), function(id)
          return Fk:getCardById(id):getSuitString(true) == choice[1]
        end)
      end
    end
    room:throwCard(to_throw, qingzheng.name, to, player)
    if #my_throw > #to_throw then
      if not to.dead then
        room:doIndicate(player, {to})
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = qingzheng.name,
        }
      end
    end
  end,
})

return qingzheng
