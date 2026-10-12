local jishi = fk.CreateSkill {
  name = "jishi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jishi"] = "济世",
  [":jishi"] = "锁定技，你使用牌结算后，若此牌没有造成伤害，则将之置入<a href='RenPile_href'>“仁”区</a>；"..
  "当“仁”牌不因溢出而离开“仁”区后，你摸一张牌。",

  ["$jishi1"] = "勤求古训，常怀济人之志。",
  ["$jishi2"] = "博采众方，不随趋势之徒。",
}

local U = require "packages.utility.utility"

jishi:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jishi.name) and not data.damageDealt and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    U.AddToRenPile(player, data.card, jishi.name)
  end,
})
jishi:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jishi.name) then
      for _, move in ipairs(data) do
        if move.extra_data and move.extra_data.removefromrenpile and move.skillName ~= "ren_overflow" then
          return true
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, jishi.name)
  end,
})

return jishi
