---@param room AbstractRoom
---@param player Player
---@param friend string
---@return boolean
local function GongliFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
    not not table.find(room.alive_players, function (p)
      return p.role == player.role and (p.general:endsWith(friend) or p.deputyGeneral:endsWith(friend))
    end)
end

local gongli = fk.CreateSkill {
  name = "xushu__gongli",
  tags = { Skill.Compulsory },
  dynamic_desc = function(self, player)
    local zhuge, pangtong = GongliFriend(Fk:currentRoom(), player, "friend__zhugeliang"), GongliFriend(Fk:currentRoom(), player, "friend__pangtong")
    if zhuge and pangtong then
      return "xushu__gongli"
    elseif zhuge then
      return "xushu__gongli_zhugeliang"
    elseif pangtong then
      return "xushu__gongli_pangtong"
    end
    return "dummyskill"
  end,
}

Fk:loadTranslationTable{
  ["xushu__gongli"] = "共砺",
  [":xushu__gongli"] = "锁定技，若友方友诸葛亮在场，你发动〖玄剑〗改为将一张手牌当【杀】使用；"..
  "若友方友庞统在场，你发动〖玄剑〗使用的【杀】无距离限制。（仅斗地主和2v2模式生效）",

  [":xushu__gongli_zhugeliang"] = "锁定技，若友方友诸葛亮在场，你发动〖玄剑〗改为将一张手牌当【杀】使用。",
  [":xushu__gongli_pangtong"] = "锁定技，若友方友庞统在场，你发动〖玄剑〗使用的【杀】无距离限制。",

  ["$xushu__gongli1"] = "吾等并力同心相通，大事何不可成哉。",
  ["$xushu__gongli2"] = "以吾等之才，何不同辅一主，共成王霸之业。",
}

gongli:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return player:hasSkill(gongli.name) and GongliFriend(Fk:currentRoom(), player, "friend__pangtong") and card and
      table.contains(card.skillNames, "xuanjian_sword")
  end,
})

return gongli
