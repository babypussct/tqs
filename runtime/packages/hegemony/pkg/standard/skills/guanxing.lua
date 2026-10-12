
local guanxing = fk.CreateSkill{
  name = "hs__guanxing",
}

Fk:loadTranslationTable{
  ["hs__guanxing"] = "观星",
  [":hs__guanxing"] = "准备阶段，你可以观看牌堆顶的X张牌，以任意顺序置于牌堆顶或牌堆底（X为存活角色数且至多为5）。",

  ["$hs__guanxing1"] = "观今夜天象，知天下大事。",
  ["$hs__guanxing2"] = "知天易，逆天难。",
}

local H = require "packages.hegemony.util"

guanxing:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = (H.inGeneralSkills(player, self.name) == "m" and player:hasShownSkill("yizhi"))
      and 5 or math.min(5, #room.alive_players)
    room:askToGuanxing(player, { cards = room:getNCards(num) })
  end,
})

guanxing:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return guanxing
