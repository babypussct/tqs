local xichang = fk.CreateSkill {
  name = "os__xichang",
  tags = { Skill.Compulsory },
}

---@type mobileUtil
local mobileUtil = require "packages.mobile.mobile_util"

Fk:loadTranslationTable{
  ["os__xichang"] = "袭裳",
  [":os__xichang"] = "锁定技，游戏开始时，你选择本局形象，获得对应的“褽装”；当你不因摸牌而获得牌时，<a href='#DisplayCardsDesc'>明置</a>之；" ..
  "你的明置手牌于被其他角色选择时不可见。<br />" ..
  "<a href=':os__weizhuang'>褽装（桂殿）</a><br />" ..
  "<a href=':mobile_dongjiao__weizhuang'>褽装（东郊）</a><br />" ..
  "<a href=':mobile_xiuge__weizhuang'>褽装（绣阁）</a>",

  ["#os__xichang-choose"] = "袭裳：选择一个〖褽装〗获得",
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
        choices = { "os__weizhuang", "mobile_dongjiao__weizhuang", "mobile_xiuge__weizhuang" },
        skill_name = xichang.name,
        prompt = "#os__xichang-choose",
        detailed = true,
      }
    )

    local function henshin(player, avatar)
      if player.general == "mobile__cuilingyi" then
        room:setPlayerProperty(player, "general", avatar)
      elseif player.deputyGeneral == "mobile__cuilingyi" then
        room:setPlayerProperty(player, "deputyGeneral", avatar)
      end
    end

    if skill == "mobile_dongjiao__weizhuang" then
      player:broadcastSkillInvoke(xichang.name, math.random(3, 4))
      henshin(player, "mobile_dongjiao__cuilingyi")
    elseif skill == "mobile_xiuge__weizhuang" then
      player:broadcastSkillInvoke(xichang.name, math.random(5, 6))
      henshin(player, "mobile_xiuge__cuilingyi")
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
