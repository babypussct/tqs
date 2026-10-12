local fangzhu = fk.CreateSkill{
  name = "hs__fangzhu",
}

Fk:loadTranslationTable{
  ["hs__fangzhu"] = "放逐",
  [":hs__fangzhu"] = "当你受到伤害后，你可以令一名其他角色选择一项：1.摸X张牌并叠置；2.弃置X张牌并失去1点体力（X为你已损失的体力值）。",

  ["#hs__fangzhu-choose"] = "放逐：你可以令一名其他角色选择摸%arg张牌并叠置，或弃牌并失去1点体力",
  ["hs__fangzhu_ask"] = "放逐：弃置%arg张牌并失去1点体力，或点“取消”摸牌并叠置",

  ["$hs__fangzhu1"] = "死罪可免，活罪难赦！",
  ["$hs__fangzhu2"] = "给我翻过来！",
}

fangzhu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = player.room:getOtherPlayers(player, false),
      min_num = 1, max_num = 1, prompt = "#hs__fangzhu-choose:::"..player:getLostHp(),
      skill_name = fangzhu.name, cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local num = player:getLostHp()
    if to.hp > 0 and #room:askToDiscard(to, {
      min_num = num, max_num = num, include_equip = true, skill_name = fangzhu.name,
      cancelable = true, prompt = "hs__fangzhu_ask:::" .. num
    }) > 0 then
      if not to.dead then room:loseHp(to, 1, fangzhu.name) end
    else
      to:drawCards(num, fangzhu.name)
      if not to.dead then to:turnOver() end
    end
  end,
})

return fangzhu
