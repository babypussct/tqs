local yilie = fk.CreateSkill {
  name = "os__yilie",
}

Fk:loadTranslationTable{
  ["os__yilie"] = "毅烈",
  [":os__yilie"] = "出牌阶段开始时，你可以选择此阶段内：1.使用【杀】的次数上限+1；2.当你使用【杀】指定一名处于连环状态的角色为目标后，"..
  "或被【闪】抵消后，摸一张牌；背水：你失去1点体力。",

  ["os__yilie_times"] = "使用【杀】次数上限+1",
  ["os__yilie_draw"] = "使用【杀】指定连环状态角色后或被【闪】抵消后，摸一张牌",
  ["os__yilie_beishui"] = "背水：失去1点体力",
  ["@@os__yilie-phase"] = "毅烈",

  ["$os__yilie1"] = "区区绳索，就想挡住吾等去路？！",
  ["$os__yilie2"] = "以身索敌，何惧同伤！",
}

yilie:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(yilie.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"os__yilie_times", "os__yilie_draw", "os__yilie_beishui" ,"Cancel"}
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = yilie.name
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self)
    if choice == "os__yilie_beishui" then
      room:setPlayerMark(player, "@@os__yilie-phase", 1)
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", 1)
      room:loseHp(player, 1, yilie.name)
    elseif choice == "os__yilie_times" then
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", 1)
    elseif choice == "os__yilie_draw" then
      room:setPlayerMark(player, "@@os__yilie-phase", 1)
    end
  end,
})

yilie:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@os__yilie-phase") > 0 and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, yilie.name)
  end,
})

yilie:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and
      player:getMark("@@os__yilie-phase") > 0 and data.to.chained
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, yilie.name)
  end,
})

return yilie
