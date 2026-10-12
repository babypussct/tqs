
local xingshen = fk.CreateSkill {
  name = "ol__xingshen",
}

Fk:loadTranslationTable{
  ["ol__xingshen"] = "省身",
  [":ol__xingshen"] = "当你受到伤害后，你可以摸随机1~2张牌且令下一次发动〖严教〗亮出的牌数+X（X为你已损失体力值，至多亮出十张）。",

  ["$ol__xingshen1"] = "定省清温，笙磬同音。",
  ["$ol__xingshen2"] = "省烦从简，烦扰皆除。",
}

xingshen:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(room:tableRandomPick({ 1, 2 }), xingshen.name)
    if player.dead or player:getMark("@yanjiao") > 5 or not player:hasSkill("yanjiao", true) then return end
    room:addPlayerMark(player, "@yanjiao", math.min(6 - player:getMark("@yanjiao"), player:getLostHp()))
  end,
})

local AI = Fk.Ltk.AI
xingshen:addAI(AI.reuse("biyue", AI.InvokeStrategy))

return xingshen
