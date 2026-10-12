
local quesong = fk.CreateSkill {
  name = "os__quesong",
}

Fk:loadTranslationTable{
  ["os__quesong"] = "雀颂",
  [":os__quesong"] = "一名角色结束阶段，若你于此回合内受到过伤害，你可以令至多三名角色各选择一项执行："..
  "1.摸4-X张牌并复原武将牌；2.弃置X-1张牌，然后回复1点体力（X为你此次选择的角色数）。"..
  "若你本回合受到过伤害的次数大于X，被选择的角色可以依次执行两项。",

  ["#os__quesong-choose"] = "雀颂：你可以令至多三名角色依次选择执行选项",
  ["os__quesong_draw"] = "摸%arg张牌并复原",
  ["os__quesong_recover"] = "弃置%arg张牌，回复1点体力",
  ["os__quesong_beishui"] = "依次执行两项",
  ["#os__quesong-discard"] = "雀颂：弃置%arg张牌，然后回复1点体力",

  ["$os__quesong1"] = "丞相将兴，自有瑞应。",
  ["$os__quesong2"] = "素羽明鲜身姿小，且飞且鸣试比高。",
}

quesong:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(quesong.name) and target.phase == Player.Finish and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == player
      end) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 3,
      targets = room.alive_players,
      skill_name = quesong.name,
      prompt = "#quesong-choose",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos or {}
    local choices = { "os__quesong_draw:::"..(4 - #tos), "os__quesong_recover:::"..(#tos - 1) }
    if #room.logic:getActualDamageEvents(#tos + 1, function(e)
      return e.data.to == player
    end) > #tos then
      table.insert(choices, "os__quesong_beishui")
    end
    for _, p in ipairs(tos) do
      if not p.dead then
        local choice = room:askToChoice(p, {
          choices = choices,
          skill_name = quesong.name,
        })
        if not choice:startsWith("os__quesong_recover") then
          p:drawCards(4 - #tos, quesong.name)
          p:reset()
        end
        if not choice:startsWith("os__quesong_draw") and not p.dead then
          if room:askToDiscard(p, {
            min_num = 1,
            max_num = #tos - 1,
            include_equip = true,
            skill_name = quesong.name,
            cancelable = true,
            prompt = "#os__quesong-discard:::"..(#tos - 1),
          }) and not p.dead then
            room:recover{
              who = p,
              num = 1,
              recoverBy = player,
              skillName = quesong.name,
            }
          end
        end
      end
    end
  end,
})

return quesong
