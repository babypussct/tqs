local quesong = fk.CreateSkill {
  name = "quesong",
}

Fk:loadTranslationTable{
  ["quesong"] = "雀颂",
  [":quesong"] = "一名角色结束阶段，若你本回合受到过伤害，你可以令一名角色选择一项：1.摸三张牌（若其装备区里的牌数大于2，则改为摸两张牌）"..
  "并复原武将牌；2.回复1点体力。",

  ["#quesong-choose"] = "雀颂：你可以令一名角色选择摸牌或回复体力",
  ["quesong_draw"] = "摸%arg张牌并复原",

  ["$quesong1"] = "承白雀之瑞，显周公之德。",
  ["$quesong2"] = "挽汉室于危亡，继光武之中兴。",
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
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = quesong.name,
      prompt = "#quesong-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local x = (#to:getCardIds("e") > 2) and 2 or 3
    local choices = {"quesong_draw:::"..x}
    if to:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = quesong.name,
    })
    if choice == "recover" then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = quesong.name
      })
    else
      to:drawCards(x, quesong.name)
      to:reset()
    end
  end,
})

return quesong
