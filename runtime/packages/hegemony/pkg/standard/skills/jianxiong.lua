local jianxiong = fk.CreateSkill{
  name = "hs__jianxiong",
}

Fk:loadTranslationTable{
  ["hs__jianxiong"] = "奸雄",
  [":hs__jianxiong"] = "当你受到伤害后，你可以选择一项：1.获得对你造成伤害的牌；2.摸一张牌。",

  ["#hs__jianxiong"] = "奸雄：选择一项",
  ["hs__jianxiong-obtain"] = "获得对你造成伤害的牌",

  ["$hs__jianxiong1"] = "燕雀，安知鸿鹄之志！",
  ["$hs__jianxiong2"] = "夫英雄者，胸怀大志，腹有良谋！",
}

jianxiong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = { "draw1" }
    if data.card and player.room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, "hs__jianxiong-obtain")
    end
    local choice = room:askToChoice(player,{
      choices = choices,
      prompt = "#hs__jianxiong",
      cancelable = true,
    })
    if choice == "hs__jianxiong-obtain" then
      player.room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, jianxiong.name)
    else
      player:drawCards(1, jianxiong.name)
    end
  end,
})

return jianxiong