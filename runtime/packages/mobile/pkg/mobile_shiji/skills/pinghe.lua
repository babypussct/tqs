local pinghe = fk.CreateSkill {
  name = "pinghe",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["pinghe"] = "冯河",
  [":pinghe"] = "锁定技，你的手牌上限基值为你已损失的体力值；当你受到其他角色造成的伤害时，若你的体力上限大于1且你有手牌，你防止此伤害，"..
  "减1点体力上限并将一张手牌交给一名其他角色，然后若你有技能〖英霸〗，伤害来源获得一枚“平定”标记。",

  ["#pinghe-give"] = "冯河：请交给一名其他角色一张手牌",

  ["$pinghe1"] = "不过胆小鼠辈，吾等有何惧哉！",
  ["$pinghe2"] = "只可得胜而返，岂能败战而归！",
}

pinghe:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pinghe.name) and
      player.maxHp > 1 and not player:isKongcheng() and
      data.from and data.from ~= player and data.from:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.prevented = true
    room:changeMaxHp(player, -1)
    if player.dead or #room:getOtherPlayers(player, false) == 0 or player:isKongcheng() then return end
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|.|hand",
      skill_name = pinghe.name,
      prompt = "#pinghe-give",
      cancelable = false,
    })
    room:obtainCard(tos[1], cards, false, fk.ReasonGive, player, pinghe.name)
    if player:hasSkill("yingba", true) and not data.from.dead then
      room:addPlayerMark(data.from, "@yingba_pingding")
    end
  end,
})
pinghe:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:hasSkill(pinghe.name) then
      return player:getLostHp()
    end
  end,
})

return pinghe
