
local jinlan = fk.CreateSkill{
  name = "jinlan",
}

Fk:loadTranslationTable{
  ["jinlan"] = "尽览",
  [":jinlan"] = "当你于回合内使用♠/<font color='red'>♥</font>/♣/<font color='red'>♦</font>牌后，"..
  "你可以绘制东/西/南/北方位的所有“地图”。你绘制一座城市后，执行对应城市的效果。",

  ["#jinlan-invoke"] = "尽览：是否向%arg方向绘制地图？",

  ["$jinlan1"] = "绘湖海于一苇，览山河于一叶。",
  ["$jinlan2"] = "堪舆之经纬，国家之方圆。",
}

local M = require "packages.ol.pkg.ol_sp.peixiu_util"

local direction_map = {
  [Card.Spade] = "R",
  [Card.Heart] = "L",
  [Card.Club] = "D",
  [Card.Diamond] = "U",
}
jinlan:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jinlan.name) and player.phase ~= Player.NotActive and
      player:getMark("@[maozhu]") ~= 0 and M.canMoveTo(player:getMark("@[maozhu]").map, direction_map[data.card.suit])
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return room:askToSkillInvoke(player, {
      skill_name = jinlan.name,
      prompt = "#jinlan-invoke:::map_direction" .. direction_map[data.card.suit],
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@[maozhu]")
    local direction = direction_map[data.card.suit]
    local effects = M.walkDirection(mark.map, direction)
    for _, effect in ipairs(effects) do
      M.executeMapEffect(player, effect)
    end
    if M.effectToBeDone(mark.map) == 0 then
      M.maozhuEffect(player)
    else
      room:setPlayerMark(player, "@[maozhu]", mark)
    end
  end,
})

return jinlan
