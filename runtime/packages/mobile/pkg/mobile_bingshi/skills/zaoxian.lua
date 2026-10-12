local zaoxian = fk.CreateSkill {
  name = "m_shi__zaoxian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_shi__zaoxian"] = "凿险",
  [":m_shi__zaoxian"] = "锁定技，当你一次性消耗的蓄力点数不小于对应值时，你从弃牌堆获得一张对应牌：3，【无中生有】；5，【无懈可击】；7，【五谷丰登】。",

  ["$m_shi__zaoxian1"] = "乘胜进击，一鼓作气。",
  ["$m_shi__zaoxian2"] = "未建破蜀之功，何惧丧身之险？",
}

local U = require "packages.utility.utility"

zaoxian:addEffect(U.SkillChargeChanged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.num < -2 and
      player:hasSkill(zaoxian.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = data.num
    local toObtain = {}

    if num < -2 then
      local exNihilo = room:getCardsFromPileByRule("ex_nihilo", 1, "discardPile")
      if #exNihilo > 0 then
        table.insert(toObtain, room:tableRandomPick(exNihilo))
      end
    end

    if num < -4 then
      local nullification = room:getCardsFromPileByRule("nullification", 1, "discardPile")
      if #nullification > 0 then
        table.insert(toObtain, room:tableRandomPick(nullification))
      end
    end

    if num < -6 then
      local amazingGrace = room:getCardsFromPileByRule("amazing_grace", 1, "discardPile")
      if #amazingGrace > 0 then
        table.insert(toObtain, room:tableRandomPick(amazingGrace))
      end
    end

    if #toObtain > 0 then
      room:obtainCard(player, toObtain, false, fk.ReasonPrey, player, zaoxian.name)
    end
  end,
})

return zaoxian
