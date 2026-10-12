local yinyangfishSkill = fk.CreateSkill{
  name = "yinyangfish_skill&",
}
local H = require "packages.hegemony.util"
yinyangfishSkill:addEffect("active", {
  prompt = "#yinyangfish_skill&",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:getMark("@!!yinyangfish") > 0
  end,
  card_filter = Util.FalseFunc,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = effect.from
    H.removeHegMark(room, player, "yinyangfish", 1)
    player:drawCards(1, yinyangfishSkill.name)
  end,
})
yinyangfishSkill:addEffect(fk.EventPhaseStart, {
  priority = 0.1,
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard
      and player:hasSkill(yinyangfishSkill.name)
      and player:getMark("@!!yinyangfish") > 0
      and player:getHandcardNum() > player:getMaxCards()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yinyangfishSkill.name,
      prompt = "#yinyangfish_max-ask",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    H.removeHegMark(room, player, "yinyangfish", 1)
    room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 2)
    room:broadcastProperty(player, "MaxCards")
  end,
})
Fk:loadTranslationTable{
  ["yinyangfish_skill&"] = "阴阳鱼",
  ["#yinyangfish_skill&"] = "你可弃一枚“阴阳鱼”，摸一张牌",
  ["#yinyangfish_max-ask"] = "你可弃一枚“阴阳鱼”，此回合手牌上限+2",
  [":yinyangfish_skill&"] = "出牌阶段，你可弃一枚“阴阳鱼”，摸一张牌；弃牌阶段开始时，你可弃一枚“阴阳鱼”，此回合手牌上限+2。",
  ["yinyangfish"] = "阴阳鱼",
}

return yinyangfishSkill
