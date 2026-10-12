local xingqi = fk.CreateSkill {
  name = "os__xingqi",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["os__xingqi"] = "星启",
  [":os__xingqi"] = "觉醒技，准备阶段，若场上的牌数大于你的体力值，你回复1点体力，然后若〖秘备〗未完成，你从牌堆中获得每种类别的牌各一张；"..
  "若〖秘备〗已完成，本局游戏你使用牌无距离限制。",

  ["@@os__xingqi"] = "星启无距离限制",

  ["$os__xingqi1"] = "司马氏虽权尊势重，吾等徐图亦无不可！",
  ["$os__xingqi2"] = "先谋后事者昌，先事后谋者亡！",
}

xingqi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingqi.name) and player.phase == Player.Start and
      player:usedSkillTimes(xingqi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local num = 0
    for _, p in ipairs(player.room.alive_players) do
      num = num + #p:getCardIds("ej")
    end
    return num > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = xingqi.name,
    }
    end
    if player:getQuestSkillState("os__mibei") ~= "succeed" then
      local cards = {}
      for _, type in ipairs({"basic", "trick", "equip"}) do
        table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|"..type))
      end
      if #cards > 0 then
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player, xingqi.name)
      end
    else
      room:setPlayerMark(player, "@@os__xingqi", 1)
    end
  end,
})

xingqi:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card)
    return card and player:getMark("@@os__xingqi") > 0
  end,
})

return xingqi
