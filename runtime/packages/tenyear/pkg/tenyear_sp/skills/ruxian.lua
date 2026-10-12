local ruxian = fk.CreateSkill {
  name = "ruxian",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ruxian"] = "儒贤",
  [":ruxian"] = "限定技，出牌阶段，你可以将〖彰才〗改为所有点数均可触发摸牌直到你的下回合开始。",

  ["#ruxian"] = "儒贤：令你发动“彰才”没有点数限制直到下个回合开始！",
  ["@@ruxian"] = "儒贤",

  ["$ruxian1"] = "儒道尚仁而有礼，贤者知命而独悟。",
  ["$ruxian2"] = "儒门有言，仁为己任，此生不负孔孟之礼。",
}

ruxian:addEffect("active", {
  name = "ruxian",
  prompt = "#ruxian",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(ruxian.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    room:setPlayerMark(effect.from, "@@ruxian", 1)
  end,
})

ruxian:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@ruxian") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ruxian", 0)
  end,
})

ruxian:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    if ai.player:hasSkill("zhangcai") and ai.player:getHandcardNum() > 2 then
      local n = 0
      for i = 1, ai.player:getHandcardNum() - 1 do
        local id = ai.player:getCardIds("h")[i]
        if ai.player:canUse(Fk:getCardById(id)) then
          for j = i + 1, ai.player:getHandcardNum() do
            if Fk:getCardById(id):compareNumberWith(Fk:getCardById(ai.player:getCardIds("h")[j])) then
              n = n + 1
            end
          end
        end
      end
      print(n)
      if n > 2 then
        return { }, ai:getBenefitOfEvents(function(logic)
          logic:drawCards(ai.player, n, self.skill_name)
        end)
      end
    end
  end,
})

return ruxian
