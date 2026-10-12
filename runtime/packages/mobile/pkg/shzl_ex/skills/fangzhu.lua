local fangzhu = fk.CreateSkill{
  name = "m_ex__fangzhu",
}

Fk:loadTranslationTable{
  ["m_ex__fangzhu"] = "放逐",
  [":m_ex__fangzhu"] = "当你受到伤害后，你可以令一名其他角色选择一项：1.弃置X张牌并失去1点体力；2.摸X张牌并翻面（X为你已损失的体力值）。",

  ["#m_ex__fangzhu-choose"] = "放逐：令一名角色选择：摸%arg张牌并翻面，或弃置%arg张牌并失去1点体力",
  ["#m_ex__fangzhu-ask"] = "放逐：弃置%arg张牌并失去1点体力，或点“取消”摸%arg张牌并翻面",

  ["$m_ex__fangzhu1"] = "国法不可废耳，汝先退去。",
  ["$m_ex__fangzhu2"] = "将军征战辛苦，孤当赠以良宅。",
}

fangzhu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(fangzhu.name) and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = fangzhu.name,
      prompt = "#m_ex__fangzhu-choose:::" .. player:getLostHp(),
      cancelable = true,
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
      min_num = num,
      max_num = num,
      include_equip = true,
      skill_name = fangzhu.name,
      prompt = "#m_ex__fangzhu-ask:::" .. num,
      cancelable = true,
    }) > 0 then
      if not to.dead then
        room:loseHp(to, 1, fangzhu.name)
      end
    else
      to:drawCards(num, fangzhu.name)
      if not to.dead then
        to:turnOver()
      end
    end
  end,
})

return fangzhu
