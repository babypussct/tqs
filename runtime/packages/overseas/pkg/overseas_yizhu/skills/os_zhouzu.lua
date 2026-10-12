local osZhouzu = fk.CreateSkill {
  name = "os__zhouzu"
}

Fk:loadTranslationTable{
  ["os__zhouzu"] = "咒诅",
  [":os__zhouzu"] = "出牌阶段限一次，你可选择一名其他角色并施法：令其弃置X张牌，若牌数不足则全部弃置并对其造成1点雷电伤害。",

  ["#os__zhouzu"] = "咒诅：选择一名其他角色并施法X，其须弃牌否则受到雷伤",
  ["@os__zhouzu"] = "咒诅",
  ["#os__zhouzu_conjure"] = "咒诅",
}

osZhouzu:addEffect("active", {
  anim_type = "control",
  prompt = "#os__zhouzu",
  times = function (self, player)
    return 1 - player:usedSkillTimes(osZhouzu.name, Player.HistoryPhase)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(osZhouzu.name, Player.HistoryPhase) < 1 and player:getMark("@os__zhouzu") == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  interaction = UI.Spin {
    from = 1, to = 3,
  },
  on_use = function(self, room, effect)
    local num = self.interaction.data
    if not num then
      return false
    end

    local player = effect.from
    local target = effect.tos[1]
    room:setPlayerMark(player, "@os__zhouzu", { target.general, num .. "-" .. num })
    room:setPlayerMark(player, "_os__zhouzu", target.id)
  end,
})

osZhouzu:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__zhouzu") ~= 0 and string.sub(player:getMark("@os__zhouzu")[2], -1) == "0"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osZhouzu.name
    local room = player.room
    local nums = string.split(player:getMark("@os__zhouzu")[2], "-")
    local num = tonumber(nums[1])

    local to = room:getPlayerById(player:getMark("_os__zhouzu"))
    if #to:getCardIds("he") < num then
      to:throwAllCards("he")
      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = skillName,
      }
    else
      room:askToDiscard(
        to,
        {
          min_num = num,
          max_num = num,
          include_equip = true,
          skill_name = skillName,
          cancelable = false,
        }
      )
    end
    room:setPlayerMark(player, "@os__zhouzu", 0)
    room:setPlayerMark(player, "_os__zhouzu", 0)
  end,

  can_refresh = function(self, event, player, data)
    return player:getMark("@os__zhouzu") ~= 0
  end,
  on_refresh = function(self, event, player, data)
    local room = player.room
    local nums = string.split(player:getMark("@os__zhouzu")[2], "-")
    room:setPlayerMark(
      player,
      "@os__zhouzu",
      { player:getMark("@os__zhouzu")[1], nums[1] .. "-" .. (tonumber(nums[2]) - 1) }
    )
  end,
})

return osZhouzu
