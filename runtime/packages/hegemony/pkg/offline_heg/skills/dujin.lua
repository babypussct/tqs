local dujin = fk.CreateSkill{
  name = "ofl_heg__dujin",
}

Fk:loadTranslationTable{
  ["ofl_heg__dujin"] = "独进",
  [":ofl_heg__dujin"] = "摸牌阶段，你可以多摸X张牌（X为你装备区牌数的一半，向上取整）。"..
  "当你首次明置此武将牌后，若没有与你势力相同的其他角色和与你势力相同的已死亡角色，你获得1枚“先驱”标记。",

  ["$ofl_heg__dujin1"] = "带兵十万，不如老夫多甲一件！",
  ["$ofl_heg__dujin2"] = "轻舟独进，破敌先锋！",
}

local H = require "packages.hegemony.util"

dujin:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(dujin.name)
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + math.ceil(#player:getCardIds("e") / 2)
  end,
})

dujin:addEffect(fk.GeneralRevealed, {
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(dujin.name) and player:usedSkillTimes(dujin.name, Player.HistoryGame) == 0 and
      H.getKingdomPlayersNum(player.room, true)[H.getKingdom(player)] == 1 then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), dujin.name) then return true end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    H.addHegMark(player, "vanguard")
  end,
})

return dujin
