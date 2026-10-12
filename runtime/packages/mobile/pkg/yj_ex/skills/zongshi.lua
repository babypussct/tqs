local zongshi = fk.CreateSkill{
  name = "m_ex__zongshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_ex__zongshi"] = "宗室",
  [":m_ex__zongshi"] = "锁定技，你的手牌上限+X（X为势力数）。准备阶段，若你的手牌数大于体力值，本回合你使用【杀】无次数限制。",

  ["@@m_ex__zongshi-turn"] = "宗室",

  ["$m_ex__zongshi1"] = "这天下，尽是大汉疆土！",
  ["$m_ex__zongshi2"] = "汉室之威，犹然彰存！",
}

zongshi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:hasSkill(zongshi.name) and
    player:getHandcardNum() > player.hp
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@@m_ex__zongshi-turn")
  end,
})

zongshi:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(zongshi.name) then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms
    else
      return 0
    end
  end,
})

zongshi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.trueName == "slash" and player:getMark("@@m_ex__zongshi-turn") > 0
  end,
})

return zongshi
