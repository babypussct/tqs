local danxin = fk.CreateSkill {
  name = "ty_ex__danxin",
}

Fk:loadTranslationTable{
  ["ty_ex__danxin"] = "殚心",

  [":ty_ex__danxin"] = "当你受到伤害后，你可以摸一张牌并修改〖矫诏〗。第1次修改：将“一名距离最近的其他角色”改为“你”；第2次修改："..
  "删去“不能指定自己为目标”并将“出牌阶段限一次”改为“出牌阶段每种类型限声明一次”。",

  ["$ty_ex__danxin1"] = "殚精出谋，以保社稷。",
  ["$ty_ex__danxin2"] = "竭心筹划，求续魏统。",
}

danxin:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    if player:getMark(danxin.name) < 2 then
      player.room:addPlayerMark(player, danxin.name, 1)
    end
    player:drawCards(1, danxin.name)
  end,
})

local AI = Fk.Ltk.AI
danxin:addAI(AI.reuse("biyue", AI.InvokeStrategy))

return danxin
