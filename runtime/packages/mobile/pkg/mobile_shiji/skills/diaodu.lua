local diaodu = fk.CreateSkill {
  name = "mobile__diaodu",
}

Fk:loadTranslationTable{
  ["mobile__diaodu"] = "调度",
  [":mobile__diaodu"] = "准备阶段，你可以移动场上的一张装备牌，然后以此法失去牌的角色摸一张牌。",

  ["#mobile__diaodu-move"] = "调度：你可以移动场上一张装备牌，失去牌的角色摸一张牌",

  ["$mobile__diaodu1"] = "三军器用，攻守之具，皆有法也！",
  ["$mobile__diaodu2"] = "士各执其器，乃陷坚陈，败强敌！",
}

diaodu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(diaodu.name) and player.phase == Player.Start and
      #player.room:canMoveCardInBoard("e") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChooseToMoveCardInBoard(player, {
      prompt = "#mobile__diaodu-move",
      skill_name = diaodu.name,
      cancelable = true,
      flag = "e",
    })
    if #tos == 2 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos or {}
    local result = room:askToMoveCardInBoard(player, {
      target_one = targets[1],
      target_two = targets[2],
      skill_name = diaodu.name,
      flag = "e",
    })
    if result and not result.from.dead then
      result.from:drawCards(1, diaodu.name)
    end
  end,
})

return diaodu
