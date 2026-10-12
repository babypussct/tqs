local chijie = fk.CreateSkill {
  name = "mobile__chijie",
}

Fk:loadTranslationTable{
  ["mobile__chijie"] = "持节",
  [":mobile__chijie"] = "每回合限一次，当你成为其他角色使用牌的唯一目标时，你可以进行判定，若点数大于6，则取消之。",

  ["#mobile__chijie-invoke"] = "持节：你可以判定，若点数大于6，则取消此%arg",

  ["$mobile__chijie1"] = "节度在此，诸将莫要轻进。",
  ["$mobile__chijie2"] = "吾奉天子明诏，整肃六军。",
}

chijie:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chijie.name) and data:isOnlyTarget(player) and not data.cancelled and
      data.from ~= player and player:usedSkillTimes(chijie.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chijie.name,
      prompt = "#mobile__chijie-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = chijie.name,
      pattern = ".|7~13",
    }
    room:judge(judge)
    if judge:matchPattern() then
      data:cancelCurrentTarget()
    end
  end,
})

return chijie
