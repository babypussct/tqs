local chenxun = fk.CreateSkill {
  name = "os__chenxun",
}

Fk:loadTranslationTable{
  ["os__chenxun"] = "沉勋",
  [":os__chenxun"] = "每轮开始时，你可以视为对一名其他角色使用一张【决斗】。结算后，若此牌：对其造成伤害，你摸一张牌，然后可以对本轮"..
  "未以此法选择过的其他角色发动此技能；未对其造成伤害，你失去1点体力。",

  ["#os__chenxun-invoke"] = "沉勋：你可以视为对一名其他角色使用一张【决斗】",
  ["@[list]os__chenxun-round&"] = "沉勋",

  ["$os__chenxun1"] = "待我上马，拔得头筹！",
  ["$os__chenxun2"] = "阵斩敌将，名扬四海！"
}

chenxun:addEffect(fk.RoundStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenxun.name) and player:canUse(Fk:cloneCard("duel"))
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not table.contains(player:getTableMark("@[list]os__chenxun-round&"), p) and
        player:canUseTo(Fk:cloneCard("duel"), p)
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__chenxun-invoke",
      skill_name = chenxun.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMark(player, "@[list]os__chenxun-round&", to)
    local use = room:useVirtualCard("duel", nil, player, to, chenxun.name)
    if use == nil or player.dead then
      room:setPlayerMark(player, "@[list]os__chenxun-round", 0)
    return end
    if use.damageDealt and use.damageDealt[to] then
      player:drawCards(1, chenxun.name)
      if not player.dead then
        self:doCost(event, target, player, data)
      end
    else
      room:loseHp(player, 1, chenxun.name)
    end
    room:setPlayerMark(player, "@[list]os__chenxun-round", 0)
  end,
})

return chenxun
