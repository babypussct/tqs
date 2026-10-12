local pinghe = fk.CreateSkill {
  name = "os__pinghe",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["os__pinghe"] = "冯河",
  [":os__pinghe"] = "锁定技，你的手牌上限基值为你的体力上限；当你受到其他角色造成的伤害时，若你的体力上限大于1且你有手牌，你防止此伤害，" ..
      "减1点体力上限，选择一项：1.将一张牌交给一名其他角色；2.重铸一张牌。然后若你有技能〖英霸〗，伤害来源获得一枚“平定”标记。",

  ["#os__pinghe-give"] = "冯河：选择一张牌，交给一名其他角色或直接“确认”以重铸",

  ["$os__pinghe1"] = "此番扫平群寇，只需凭勇，不必依谋。",
  ["$os__pinghe2"] = "以勇力为先，纵有奇险，万事可平。",
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
    data:preventDamage()
    room:changeMaxHp(player, -1)
    if player.dead or #room:getOtherPlayers(player, false) == 0 or player:isKongcheng() then return end
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 0,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".",
      skill_name = pinghe.name,
      prompt = "#os__pinghe-give",
      cancelable = false,
    })
    if #tos > 0 then
      room:obtainCard(tos[1], cards, false, fk.ReasonGive, player, pinghe.name)
    else
      room:recastCard(cards, player, pinghe.name)
    end
    if player:hasSkill("os__yingba", true) and not data.from.dead then
      room:addPlayerMark(data.from, "@os__yingba_pingding")
    end
  end,
})
pinghe:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:hasSkill(pinghe.name) then
      return player.maxHp
    end
  end,
})

return pinghe
