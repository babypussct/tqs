local osFengqi = fk.CreateSkill {
  name = "os__fengqi"
}

Fk:loadTranslationTable{
  ["os__fengqi"] = "丰祈",
  [":os__fengqi"] = "出牌阶段结束时，你可弃置一张黑色手牌，选择一名角色并施法：其摸2X张牌。",

  ["@os__fengqi"] = "丰祈",
  ["#os__fengqi-ask"] = "丰祈：你可弃置一张黑色手牌，点击“确定”后选择一名角色并施法：其摸2X张牌",
  ["#os__fengqi-target"] = "丰祈：选择一名角色，点击“确定”后施法：其摸2X张牌",
  ["#os__fengqi-conjure"] = "丰祈：施法：摸2X张牌",
}

osFengqi:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osFengqi.name) and
      player.phase == Player.Play and
      not player:isNude() and
      player:getMark("@os__fengqi") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos, cids = room:askToChooseCardsAndPlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        min_card_num = 1,
        max_card_num = 1,
        targets = room:getAlivePlayers(false),
        skill_name = osFengqi.name,
        pattern = ".|.|spade,club",
        prompt = "#os__fengqi-ask",
        will_throw = true,
        skip = true,
      }
    )
    if #tos > 0 and #cids > 0 then
      event:setCostData(self, { cids, tos[1] })
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osFengqi.name
    local room = player.room
    room:throwCard(event:getCostData(self)[1], skillName, player)
    local num = room:askToChoice(
      player,
      {
        choices = { "1", "2", "3" },
        skill_name = skillName,
        prompt = "#os__fengqi-conjure",
      }
    )
    local to = event:getCostData(self)[2]
    room:setPlayerMark(player, "@os__fengqi", { to.general, num .. "-" .. num })
    room:setPlayerMark(player, "_os__fengqi", to.id)
  end,
})

osFengqi:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__fengqi") ~= 0 and string.sub(player:getMark("@os__fengqi")[2], -1) == "0"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengqi")[2], "-")
    local num = tonumber(nums[1])
    local to = room:getPlayerById(player:getMark("_os__fengqi"))

    to:drawCards(2 * num, osFengqi.name)
    room:setPlayerMark(player, "@os__fengqi", 0)
    room:setPlayerMark(player, "_os__fengqi", 0)
  end,

  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__fengqi") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengqi")[2], "-")
    room:setPlayerMark(
      player,
      "@os__fengqi",
      { player:getMark("@os__fengqi")[1], nums[1] .. "-" .. tonumber(nums[2]) - 1}
    )
  end,
})

return osFengqi
