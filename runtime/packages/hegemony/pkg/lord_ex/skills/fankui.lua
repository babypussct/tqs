local fankui = fk.CreateSkill {
  name = "ld__simazhao__fankui",
}

Fk:loadTranslationTable {
  ["ld__simazhao__fankui"] = "反馈",
  [":ld__simazhao__fankui"] = "当你受到伤害后，你可获得来源的一张牌。",

  ["$ld__simazhao__fankui1"] = "胆敢谤言惑众，这就是下场！",
  ["$ld__simazhao__fankui2"] = "今天，就拿你来杀鸡儆猴。",
}

fankui:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fankui.name) and data.from and not data.from.dead then
      if data.from == player then
        return #player:getCardIds("he") > 0
      else
        return not data.from:isNude()
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, { data.from.id })
    local flag = data.from == player and "e" or "he"
    local card = room:askToChooseCard(player, {
      target = data.from,
      flag = flag,
      skill_name = fankui.name,
    })
    room:obtainCard(player, card, false, fk.ReasonPrey)
  end
})

return fankui
