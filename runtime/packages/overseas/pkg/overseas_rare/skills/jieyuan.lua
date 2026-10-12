local jieyuan = fk.CreateSkill{
  name = "os__jieyuan",
  dynamic_desc = function(self, player)
    return player:getMark("os__jieyuan_updated") == 0 and "os__jieyuan" or "os__jieyuan_update"
  end,
}

Fk:loadTranslationTable{
  ["os__jieyuan"] = "竭缘",
  [":os__jieyuan"] = "当你对其他角色造成伤害时，若其体力值不小于你，你可以弃置一张黑色手牌，令此伤害+1；"..
    "当你受到其他角色造成的伤害时，若其体力值不小于你，你可以弃置一张红色手牌，令此伤害-1。",

  [":os__jieyuan_update"] = "当你对其他角色造成伤害时，若其体力值不小于你，你可以重铸一张牌，令此伤害+1。" ..
    "当你受到其他角色造成的伤害时，若其体力值不小于你，你可以重铸一张牌，令此伤害-1。",

  ["#os__jieyuan1-invoke"] = "竭缘：你可以弃置一张黑色手牌令对 %dest 造成的伤害+1",
  ["#os__jieyuan2-invoke"] = "竭缘：你可以弃置一张红色手牌令你受到的伤害-1",
  ["#os__jieyuan1_update-invoke"] = "竭缘：你可以重铸一张牌令对 %dest 造成的伤害+1",
  ["#os__jieyuan2_update-invoke"] = "竭缘：你可以重铸一张牌令你受到的伤害-1",

  ["$os__jieyuan1"] = "",
  ["$os__jieyuan2"] = "",
}

jieyuan:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieyuan.name) and data.to ~= player and not player:isNude() and
      data.to.hp >= player.hp
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards
    if player:getMark("os__jieyuan_updated") == 0 then
      cards = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = jieyuan.name,
        pattern = ".|.|spade,club|hand",
        prompt = "#os__jieyuan1-invoke::"..data.to.id,
        cancelable = true,
        skip = true,
      })
    else
      cards = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = jieyuan.name,
        prompt = "#os__jieyuan1_update-invoke::"..data.to.id,
        cancelable = true,
      })
    end
    if #cards > 0 then
      event:setCostData(self, {tos = {data.to}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = event:getCostData(self).cards ---@type integer[]
    data:changeDamage(1)
    if player.dead then return end
    if player:getMark("os__jieyuan_updated") == 0 then
      room:throwCard(card, jieyuan.name, player, player)
    else
      room:recastCard(card, player, jieyuan.name)
    end
  end,
})

jieyuan:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieyuan.name) and data.from and data.from ~= player and not player:isNude() and
      data.from.hp >= player.hp
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards
    if player:getMark("os__jieyuan_updated") == 0 then
      cards = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = jieyuan.name,
        pattern = ".|.|heart,diamond|hand",
        prompt = "#os__jieyuan2-invoke",
        cancelable = true,
        skip = true,
      })
    else
      cards = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = jieyuan.name,
        prompt = "#os__jieyuan2_update-invoke",
        cancelable = true,
      })
    end
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = event:getCostData(self).cards ---@type integer[]
    data:changeDamage(-1)
    if player.dead then return end
    if player:getMark("os__jieyuan_updated") == 0 then
      room:throwCard(card, jieyuan.name, player, player)
    else
      room:recastCard(card, player, jieyuan.name)
    end
  end,
})

jieyuan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "os__jieyuan_updated", 0)
end)

return jieyuan
