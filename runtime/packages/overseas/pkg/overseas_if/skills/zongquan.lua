local zongquan = fk.CreateSkill{
  name = "os__zongquan"
}

Fk:loadTranslationTable{
  ["os__zongquan"] = "纵权",
  [":os__zongquan"] = "准备阶段或结束阶段，你可以选择一名角色，你进行判定，若结果为红色，其摸一张牌；" ..
  "若结果为黑色，其弃置一张牌；若你本次与上一次发动〖纵权〗所选择的目标角色相同但结果颜色不同，则改为摸/弃置三张牌。"..
  "然后你令一名角色获得判定牌。",

  ["#os__zongquan-invoke"] = "纵权：选择一名角色，你进行判定，根据颜色令其摸牌或弃牌",
  ["#os__zongquan-obtain"] = "纵权：令一名角色获得%arg",
  ["@[list]os__zongquan"] = "纵权",

  ["$os__zongquan1"] = "大权不可旁落，且由老夫暂领。",
  ["$os__zongquan2"] = "再立大魏新政，诏天下怀魏之人。",
}

zongquan:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zongquan.name) and target == player and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#os__zongquan-invoke",
      skill_name = zongquan.name,
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local judge = { ---@type JudgeDataSpec
      who = player,
      reason = zongquan.name,
      pattern = ".",
    }
    room:judge(judge)
    local card = judge.card
    if card == nil then return end
    if not to.dead then
      local record = player:getTableMark("@[list]os__zongquan")
      local num = (#record == 2 and record[1] == to and card:compareColorWith(record[2], true)) and 3 or 1
      record = {to, card}
      room:setPlayerMark(player, "@[list]os__zongquan", record)
      if card.color == Card.Red then
        to:drawCards(num)
      elseif card.color == Card.Black and not to:isNude() then
        room:askToDiscard(to, {
          min_num = num,
          max_num = num,
          include_equip = true,
          skill_name = zongquan.name,
          cancelable = false,
        })
      end
    end
    if room:getCardArea(card) == Card.DiscardPile and not player.dead then
      to = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#os__zongquan-obtain:::" .. card:toLogString(),
        skill_name = zongquan.name,
        cancelable = false,
      })[1]
      room:obtainCard(to, card, true, fk.ReasonJustMove, player, zongquan.name)
    end
  end,
})

return zongquan
