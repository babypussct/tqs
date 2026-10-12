local shouye = fk.CreateSkill{
  name = "shouye",
}

Fk:loadTranslationTable{
  ["shouye"] = "守邺",
  [":shouye"] = "每回合限一次，当你成为其他角色使用牌的唯一目标后，你可以与其对策，若你对策成功，此牌对你无效，且此牌结算结束后，你获得之。",

  ["#shouye-invoke"] = "守邺：你可以与 %dest 对策，若成功，%arg对你无效且你获得之",
  ["shouye_choice1"] = "开门诱敌",
  ["shouye_choice2"] = "奇袭粮道",
  ["shouye_choice3"] = "全力攻城",
  ["shouye_choice4"] = "分兵围城",
  [":shouye_choice1"] = "开门诱敌！",
  [":shouye_choice2"] = "奇袭粮道！",
  [":shouye_choice3"] = "全力攻城？",
  [":shouye_choice4"] = "分兵围城？",

  ["$shouye1"] = "敌军攻势渐怠，还望诸位依策坚守。",
  ["$shouye2"] = "袁幽州不日便至，当行策建功以报之。",
}

local U = require "packages.utility.utility"

shouye:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shouye.name) and
      player:usedSkillTimes(shouye.name, Player.HistoryTurn) == 0 and
      data.from ~= player and data:isOnlyTarget(player)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = shouye.name,
      prompt = "#shouye-invoke::"..data.from.id..":"..data.card.name,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = U.doStrategy(room, player, data.from, {"shouye_choice1", "shouye_choice2"},
    {"shouye_choice3","shouye_choice4"}, shouye.name, 2)
    if (choices[1] == "shouye_choice1" and choices[2] == "shouye_choice3") or
      (choices[1] == "shouye_choice2" and choices[2] == "shouye_choice4") then
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      table.insertIfNeed(data.use.nullifiedTargets, player)
      data.extra_data = data.extra_data or {}
      data.extra_data.shouye = player
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        data:cancelTarget(player)
      end
    end
  end,
})
shouye:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.shouye and data.extra_data.shouye == player and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, shouye.name)
  end,
})

return shouye
