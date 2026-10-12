
local dangxian = fk.CreateSkill{
  name = "m_heg__dangxian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__dangxian"] = "当先",
  [":m_heg__dangxian"] = "锁定技，当你首次明置此武将牌后，摸一张牌并获得一个“先驱”标记；回合开始时，你执行一个额外的出牌阶段。",

  ["$m_heg__dangxian1"] = "谁言蜀汉已无大将？",
  ["$m_heg__dangxian2"] = "老将虽白发，宝刀刃犹锋！",
}

local H = require "packages.hegemony.util"

dangxian:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  on_use = function(self, event, target, player, data)
    player:gainAnExtraPhase(Player.Play)
  end
})

dangxian:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(dangxian.name) then return false end
    if player:usedSkillTimes(dangxian.name, Player.HistoryGame) == 0 then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), dangxian.name) then return true end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, dangxian.name)
    if not player.dead then
      H.addHegMark(player, "vanguard")
    end
  end
})

return dangxian
