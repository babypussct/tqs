
local huihong = fk.CreateSkill{
  name = "m_heg__huihong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__huihong"] = "恢弘",
  [":m_heg__huihong"] = "锁定技，你登场时，获得场上蜀势力武将牌数个“弘”标记：其他蜀势力角色的武将牌明置后，你获得等量“弘”。",

  ["@m_heg__huihong"] = "弘",

  ["$m_heg__huihong1"] = "满朝皆追先帝之殊遇，无不奋命于此时。",
  ["$m_heg__huihong2"] = "众士赤心烈烈，此志不可改也。",
  ["$m_heg__huihong3"] = "忠士之心不可寒，汉室之荣犹可继。",
  ["$m_heg__huihong4"] = "朕当察纳雅言，以致各尽其用。",
}

local H = require "packages.hegemony.util"

huihong:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(huihong.name) and
      player:usedEffectTimes(self.name, Player.HistoryGame) == 0 then
      for _, p in ipairs(player.room.alive_players) do
        if Fk.generals[p.general]:hasKingdom("shu") then
          return true
        end
        if p.deputyGeneral and Fk.generals[p.deputyGeneral]:hasKingdom("shu") then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if Fk.generals[p.general]:hasKingdom("shu") then
        n = n + 1
      end
      if p.deputyGeneral and Fk.generals[p.deputyGeneral]:hasKingdom("shu") then
        n = n + 1
      end
    end
    room:addPlayerMark(player, "@m_heg__huihong", n)
  end,
})

huihong:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(huihong.name) and
      H.getKingdom(target) == "shu" then
      for _, v in pairs(data) do
        if Fk.generals[v]:hasKingdom("shu") then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = 0
    for _, v in pairs(data) do
      if Fk.generals[v]:hasKingdom("shu") then
        n = n + 1
      end
    end
    player.room:addPlayerMark(player, "@m_heg__huihong", n)
  end,
})

return huihong
