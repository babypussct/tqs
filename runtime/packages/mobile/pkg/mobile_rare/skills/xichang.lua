local xichang = fk.CreateSkill {
  name = "xichang",
  tags = { Skill.Compulsory },
}

---@type mobileUtil
local mobileUtil = require "packages.mobile.mobile_util"

Fk:loadTranslationTable{
  ["xichang"] = "袭裳",
  [":xichang"] = "锁定技，游戏开始时，你选择本局形象，获得对应的“褽装”；当你不因摸牌而获得牌时，<a href='#DisplayCardsDesc'>明置</a>之；" ..
  "你的明置手牌于被其他角色选择时不可见。<br />" ..
  "<a href=':weizhuang'>褽装（桂殿）</a><br />" ..
  "<a href=':mobile_dongjiao__weizhuang'>褽装（东郊）</a><br />" ..
  "<a href=':mobile_xiuge__weizhuang'>褽装（绣阁）</a>",

  ["#xichang-choose"] = "袭裳：选择一个〖褽装〗获得",

  ["$xichang1"] = "此次观礼，我定可艳压群芳。",
  ["$xichang2"] = "妾身天生丽质，岂可对镜独赏。",
  ["$xichang3"] = "此等霓裳，方配此山野之趣。",
  ["$xichang4"] = "既未逾礼，此衣何不可服？",
  ["$xichang5"] = "虽身处闺阁，亦不可自屈。",
  ["$xichang6"] = "炫服靓装，不过聊以自愉。",
  ["$xichang7"] = "珠以蚌蔽之，衣以箧藏之。",
  ["$xichang8"] = "宝衣自当示人，然非等闲可观。",
}

xichang:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xichang.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skill = room:askToChoice(
      player,
      {
        choices = { "weizhuang", "mobile_dongjiao__weizhuang", "mobile_xiuge__weizhuang" },
        skill_name = xichang.name,
        prompt = "#xichang-choose",
        detailed = true,
      }
    )

    if skill == "mobile_dongjiao__weizhuang" then
      player:broadcastSkillInvoke(xichang.name, math.random(3, 4))

      if player.general == "mobile__cuilingyi" then
        player.general = "mobile_dongjiao__cuilingyi"
        room:broadcastProperty(player, "general")
      elseif player.deputyGeneral == "mobile__cuilingyi" then
        player.deputyGeneral = "mobile_dongjiao__cuilingyi"
        room:broadcastProperty(player, "deputyGeneral")
      end
    elseif skill == "mobile_xiuge__weizhuang" then
      player:broadcastSkillInvoke(xichang.name, math.random(5, 6))

      if player.general == "mobile__cuilingyi" then
        player.general = "mobile_xiuge__cuilingyi"
        room:broadcastProperty(player, "general")
      elseif player.deputyGeneral == "mobile__cuilingyi" then
        player.deputyGeneral = "mobile_xiuge__cuilingyi"
        room:broadcastProperty(player, "deputyGeneral")
      end
    else
      player:broadcastSkillInvoke(xichang.name, math.random(1, 2))
    end

    room:handleAddLoseSkills(player, skill)
  end,
})

xichang:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(xichang.name) and
      table.find(data, function(move)
        if move.to == player and move.toArea == Card.PlayerHand and move.moveReason ~= fk.ReasonDraw then
          return table.find(move.moveInfo, function(info)
            local cardId = info.cardId
            local room = player.room
            return
              room:getCardArea(cardId) == move.toArea and
              room:getCardOwner(cardId) == player and
              not mobileUtil.cardIsVisible(room, cardId)
          end) ~= nil
        end
      end)
  end,
  on_use = function(self, event, target, player, data)
    local toDisplay = {}
    table.forEach(data, function(move)
      if move.to == player and move.toArea == Card.PlayerHand and move.moveReason ~= fk.ReasonDraw then
        table.forEach(move.moveInfo, function(info)
          local cardId = info.cardId
          local room = player.room
          if
            room:getCardArea(cardId) == move.toArea and
            room:getCardOwner(cardId) == player and
            not mobileUtil.cardIsVisible(room, cardId)
          then
            table.insert(toDisplay, cardId)
          end
        end)
      end
    end)

    mobileUtil.displayCards(player, toDisplay)
  end,
})

-- 先这样，后面整合成公共机制
xichang:addEffect("visibility", {
  card_visible = function (self, player, card, toChoose)
    local p = Fk:currentRoom():getCardOwner(card)
    if
      p and
      mobileUtil.cardIsVisible(Fk:currentRoom(), card) and
      p:hasSkill(xichang.name) and
      player ~= p and
      not toChoose
    then
      return true
    end
  end,
})

return xichang
