local wuxin = fk.CreateSkill{
  name = "wuxin",
}

Fk:loadTranslationTable{
  ["wuxin"] = "悟心",
  [":wuxin"] = "摸牌阶段开始时，你可观看牌堆顶的X张牌（X为群势力角色数）并可改变这些牌的顺序。",

  ["$wuxin1"] = "冀悟迷惑之心。",
  ["$wuxin2"] = "吾已明此救世之术矣。",
}

local H = require "packages.hegemony.util"

wuxin:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wuxin.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = H.getSameKingdomPlayersNum(room, nil, "qun")
    if player:hasSkill("hongfa") then
      num = num + #player:getPile("heavenly_army")
    end
    room:askToGuanxing(player, {
      cards = room:getNCards(num),
      bottom_limit = {0, 0},
      skill_name = wuxin.name,
    })
  end,
})

return wuxin
