local duanti = fk.CreateSkill{
  name = "ol__duanti",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol__duanti"] = "锻体",
  [":ol__duanti"] = "锁定技，当你从牌堆摸牌后，若你的体力值大于1，你受到1点无来源伤害。"..
  "当你发动〖称象〗时，若体力值为全场最低，则必定亮出一张【桃】或【酒】（每轮各限一次）；若体力值为全场最高，则必定亮出一张武器牌或伤害牌。",

  ["$ol__duanti1"] = "饭后练一练，称象不打颤。",
  ["$ol__duanti2"] = "饭前蹲一蹲，膂力破万钧。",
}

duanti:addEffect(fk.AfterCardsMove, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(duanti.name) and player.hp > 1 then
      for _, move in ipairs(data) do
        if move.to == player and move.moveReason == fk.ReasonDraw then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.DrawPile then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = nil,
      to = player,
      damage = 1,
      skillName = duanti.name,
    }
  end,
})

return duanti
