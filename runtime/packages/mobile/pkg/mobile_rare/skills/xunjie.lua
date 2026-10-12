local xunjie = fk.CreateSkill {
  name = "mobile__xunjie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__xunjie"] = "逊节",
  [":mobile__xunjie"] = "锁定技，当你受到伤害时，若场上没有【大攻车·进击】或【大攻车·守御】，且伤害来源的体力值大于你，" ..
  "你进行判定，若结果为红色，则此伤害-1。",

  ["$mobile__xunjie1"] = "藏于心者竭爱，动于身者竭恭。",
  ["$mobile__xunjie2"] = "修身如藏器，大巧若无工。",
}

xunjie:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunjie.name) and
      data.from and data.from:isAlive() and data.from.hp > player.hp and
      not table.find(player.room.alive_players, function(p)
        return table.find(p:getCardIds("e"), function(id)
          return table.contains({ "offensive_siege_engine", "defensive_siege_engine" }, Fk:getCardById(id).name)
        end) ~= nil
      end
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = xunjie.name,
      pattern = ".|.|red",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      data:changeDamage(-1)
    end
  end,
})

return xunjie
