local zhengxian = fk.CreateSkill{
  name = "ol_heg__zhengxian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_heg__zhengxian"] = "争先",
  [":ol_heg__zhengxian"] = "锁定技，当你首次明置此武将牌后，你获得一枚“先驱”标记。同势力角色的回合开始时，若其有“先驱”标记，"..
  "你令其执行一个额外的出牌阶段。",

  ["$ol_heg__zhengxian1"] = "先锋就由老夫来当！",
  ["$ol_heg__zhengxian2"] = "看我先行破敌！",
}

local H = require "packages.hegemony.util"

zhengxian:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhengxian.name) and
      target:getMark("@!!vanguard") > 0 and H.compareKingdomWith(target, player)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = {target} })
    return true
  end,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraPhase(Player.Play)
  end,
})

zhengxian:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(zhengxian.name) then return false end
    if player:usedSkillTimes(zhengxian.name, Player.HistoryGame) == 0 then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), zhengxian.name) then return true end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    H.addHegMark(player, "vanguard")
  end
})

return zhengxian
