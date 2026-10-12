local osZuhuo = fk.CreateSkill {
  name = "os__zuhuo"
}

Fk:loadTranslationTable{
  ["os__zuhuo"] = "阻祸",
  [":os__zuhuo"] = "出牌阶段结束时，你可弃置一张非基本牌并施法：防止你受到的下X次伤害。",

  ["@os__zuhuo"] = "阻祸",
  ["#os__zuhuo-ask"] = "阻祸：你可弃置一张非基本牌并施法：防止你受到的下X次伤害",
  ["#os__zuhuo-conjure"] = "阻祸：施法：防止你受到的下X次伤害",
  ["@os__zuhuo_defend"] = "阻祸防伤",
}

osZuhuo:addEffect(fk.EventPhaseEnd, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osZuhuo.name) and
      player.phase == Player.Play and
      not player:isNude() and
      player:getMark("@os__zuhuo") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cids = room:askToDiscard(
      player,
      {
        min_num = 1,
        max_num = 1,
        skill_name = osZuhuo.name,
        pattern = ".|.|.|.|.|^basic",
        prompt = "#os__zuhuo-ask",
        skip = true,
      }
    )
    if #cids > 0 then
      event:setCostData(self, cids)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osZuhuo.name
    local room = player.room
    room:throwCard(event:getCostData(self), skillName, player)
    local num = room:askToChoice(
      player,
      {
        choices = { "1", "2", "3" },
        skill_name = skillName,
        prompt = "#os__zuhuo-conjure",
      }
    )
    room:setPlayerMark(player, "@os__zuhuo", num .. "-" .. num)
  end,
})

osZuhuo:addEffect(fk.TurnEnd, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__zuhuo") ~= 0 and string.sub(player:getMark("@os__zuhuo"), -1) == "0"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zuhuo"), "-")
    local num = tonumber(nums[1])

    room:addPlayerMark(player, "@os__zuhuo_defend", num)
    room:setPlayerMark(player, "@os__zuhuo", 0)
  end,

  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__zuhuo") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zuhuo"), "-")
    room:setPlayerMark(player, "@os__zuhuo", nums[1] .. "-" .. tonumber(nums[2]) - 1)
  end,
})

osZuhuo:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@os__zuhuo_defend") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@os__zuhuo_defend")
    data:preventDamage()
  end,
})

return osZuhuo
