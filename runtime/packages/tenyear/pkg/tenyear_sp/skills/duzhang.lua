local duzhang = fk.CreateSkill {
  name = "duzhang",
}

Fk:loadTranslationTable{
  ["duzhang"] = "独仗",
  [":duzhang"] = "每回合限一次，当你使用黑色牌指定唯一目标后或成为黑色牌的唯一目标后，你可以摸一张牌并获得一枚“凛”。"..
  "你的手牌上限+X（X为你的“凛”数）。",

  ["$duzhang1"] = "黑水绕白雪，规日月之行次，自始绝地天通！",
  ["$duzhang2"] = "枷锁白驹，百代王侯，皆若蜉蝣！",
}

--实测时机均在成为目标后（晚于佐定）
duzhang:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return (data.from == player or data.to == player) and player:hasSkill(duzhang.name) and
      data:isOnlyTarget(data.to) and data.card.color == Card.Black and
      player:usedSkillTimes(duzhang.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@zhonghui_piercing", 1)
    player:drawCards(1, duzhang.name)
  end,
})

duzhang:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(duzhang.name) then
      return player:getMark("@zhonghui_piercing")
    end
  end,
})

local AI = Fk.Ltk.AI
duzhang:addAI(AI.reuse("biyue", AI.InvokeStrategy))

return duzhang
