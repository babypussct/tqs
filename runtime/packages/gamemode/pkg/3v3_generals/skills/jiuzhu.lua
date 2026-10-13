local jiuzhu = fk.CreateSkill {
  name = "jiuzhu",
}

Fk:loadTranslationTable{
  ["jiuzhu"] = "救主",
  [":jiuzhu"] = "当己方一名其他角色处于濒死状态时，若你的体力值大于1，你可以弃置一张牌并失去1点体力，令该角色回复1点体力。",

  ["#jiuzhu-invoke"] = "救主：你可以弃一张牌并失去1点体力，令 %dest 回复1点体力",
}

jiuzhu:addEffect(fk.AskForPeaches, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiuzhu.name) and
      data.who:isFriend(player) and
      player.hp > 1 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = jiuzhu.name,
      cancelable = true,
      prompt = "#jiuzhu-invoke::" .. data.who,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {data.who}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, jiuzhu.name, player, player)
    if not player.dead then
      room:loseHp(player, 1, jiuzhu.name)
    end
    if not data.who.dead and data.who:isWounded() then
      room:recover{
        who = data.who,
        num = 1,
        recoverBy = player,
        skillName = jiuzhu.name,
      }
    end
  end,
})

return jiuzhu
