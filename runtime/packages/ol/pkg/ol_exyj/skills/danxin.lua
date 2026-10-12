local danxin = fk.CreateSkill {
  name = "ol_ex__danxin",
}

Fk:loadTranslationTable{
  ["ol_ex__danxin"] = "殚心",
  [":ol_ex__danxin"] = "当你受到伤害后，你可以摸X张牌，然后<a href='ol_ex__jiaozhao_href'>修改〖矫诏〗</a>（X为你修改〖矫诏〗的次数）。",

  ["ol_ex__jiaozhao_href"] = "第1次修改：每轮限一次，你可以将一张牌当任意基本牌或普通锦囊牌使用；<br>"..
  "第2次修改：每轮限一次，你可以视为使用一张基本牌或普通锦囊牌。",

  ["$ol_ex__danxin1"] = "据府库，戮忠良，此命臣之所为？",
  ["$ol_ex__danxin2"] = "有子不孝，今岂复成人主邪？",
}

danxin:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local n = player:getMark(danxin.name)
    if n > 0 then
      player:drawCards(n, danxin.name)
    end
    if n < 2 and player:hasSkill("ol_ex__jiaozhao", true) then
      player.room:addPlayerMark(player, danxin.name, 1)
    end
  end,
})

local AI = Fk.Ltk.AI
danxin:addAI(AI.reuse("biyue", AI.InvokeStrategy))

return danxin
