local osQiongji = fk.CreateSkill {
  name = "os__qiongji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__qiongji"] = "穷技",
  [":os__qiongji"] = "锁定技，当你受到伤害时，若你没有“威”，伤害值+1；每回合限一次，当你使用或打出“威”时，你摸一张牌。",

  ["$os__qiongji1"] = "吾计虽穷，势不可衰！",
  ["$os__qiongji2"] = "战在其势，何妨技穷？",
}

osQiongji:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osQiongji.name) and #player:getPile("os__pomp") == 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

local osQiongjiDrawSpec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osQiongji.name) and
      player:usedEffectTimes("#" .. osQiongji.name .. "_2_trig") +
      player:usedEffectTimes("#" .. osQiongji.name .. "_3_trig") == 0 and
      player:getMark("_os__pomp") ~= 0 and
      table.find(Card:getIdList(data.card), function(id)
        return table.contains(player:getMark("_os__pomp"), id)
      end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, osQiongji.name)
  end,
}

osQiongji:addEffect(fk.CardUsing, osQiongjiDrawSpec)
osQiongji:addEffect(fk.CardResponding, osQiongjiDrawSpec)

return osQiongji
