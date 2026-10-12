local osZhouhu = fk.CreateSkill {
  name = "os__zhouhu"
}

Fk:loadTranslationTable{
  ["os__zhouhu"] = "咒护",
  [":os__zhouhu"] = "出牌阶段结束时，你可弃置一张红色手牌，选择一名角色并施法：令其回复X点体力。",

  ["@os__zhouhu"] = "咒护",
  ["#os__zhouhu-ask"] = "咒护：你可弃置一张红色手牌，点击“确定”后选择一名角色并施法：令其回复X点体力",
  ["#os__zhouhu-target"] = "咒护：选择一名角色，点击“确定”后施法：令其回复X点体力",
  ["#os__zhouhu-conjure"] = "咒护：施法：令其回复X点体力",
}

osZhouhu:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osZhouhu.name) and
      player.phase == Player.Play and
      not player:isNude() and
      player:getMark("@os__zhouhu") == 0
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = osZhouhu.name
    local room = player.room
    local tos, cids = room:askToChooseCardsAndPlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        min_card_num = 1,
        max_card_num = 1,
        targets = room:getAlivePlayers(false),
        skill_name = skillName,
        pattern = ".|.|heart,diamond",
        prompt = "#os__zhouhu-ask",
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
    local skillName = osZhouhu.name
    local room = player.room
    room:throwCard(event:getCostData(self)[1], skillName, player)
    local num = room:askToChoice(
      player,
      {
        choices = { "1", "2", "3" },
        skill_name = skillName,
        prompt = "#os__zhouhu-conjure",
      }
    )
    local to = event:getCostData(self)[2]
    room:setPlayerMark(player, "@os__zhouhu", { to.general, num .. "-" .. num })
    room:setPlayerMark(player, "_os__zhouhu", to.id)
  end,
})

osZhouhu:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__zhouhu") ~= 0 and string.sub(player:getMark("@os__zhouhu")[2], -1) == "0"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zhouhu")[2], "-")
    local num = tonumber(nums[1])
    local to = room:getPlayerById(player:getMark("_os__zhouhu"))

    if to:isWounded() then
      room:recover{ who = to, num = num, recoverBy = player, skillName = osZhouhu.name }
    end
    room:setPlayerMark(player, "@os__zhouhu", 0)
    room:setPlayerMark(player, "_os__zhouhu", 0)
  end,

  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__zhouhu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zhouhu")[2], "-")
    room:setPlayerMark(
      player,
      "@os__zhouhu",
      { player:getMark("@os__zhouhu")[1], nums[1] .. "-" .. tonumber(nums[2]) - 1 }
    )
  end,
})

return osZhouhu
