local zhiyu = fk.CreateSkill{
  name = "ld__zhiyu",
}
zhiyu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, zhiyu.name)
    local cards = player:getCardIds("h")
    player:showCards(cards)
    local from = data.from
    if from and not from.dead and not from:isKongcheng() and
      table.every(cards, function(id)
        return #cards == 0 or Fk:getCardById(id):compareColorWith(Fk:getCardById(cards[1]))
      end) then
      room:askToDiscard(data.from, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = zhiyu.name,
        cancelable = false,
      })
    end
  end,
})

Fk:loadTranslationTable{
  ["ld__zhiyu"] = "智愚",
  [":ld__zhiyu"] = "当你受到伤害后，你可以摸一张牌，然后展示所有手牌，若颜色均相同，伤害来源弃置一张手牌。",

  ["$ld__zhiyu1"] = "大勇若怯，大智如愚。",
  ["$ld__zhiyu2"] = "愚者既出，智者何存？",
}
return zhiyu
