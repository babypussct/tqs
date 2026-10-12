local osShouzhu = fk.CreateSkill {
  name = "os__shouzhu"
}

Fk:loadTranslationTable{
  ["os__shouzhu"] = "受嘱",
  [":os__shouzhu"] = "出牌阶段开始时，你的<a href=>同心角色</a>可至多交给你四张牌，若X不小于2，则其摸一张牌，" ..
  "然后执行<a href='os__coop'>同心效果</a>：观看牌堆顶X张牌，然后将其中任意张牌置于牌堆底，将其余牌置入弃牌堆（X为你本次以此法获得牌的数量）。",

  ["#os__shouzhu-ask"] = "你可选择一名其他角色成为你的 受嘱 同心角色",
  ["#os__shouzhu-give"] = "受嘱：你可交给 %src 至多四张牌，若不少于两张，你摸一张牌，然后与其一起执行同心",
  ["@os__shouzhu"] = "受嘱同心",
  ["#os__shouzhu"] = "受嘱：将任意张牌置于牌堆底，将其余牌置入弃牌堆",

  ["$os__shouzhu1"] = "临别教诲，均谨记在心。",
  ["$os__shouzhu2"] = "兄长此去，恰如龙入青天。",
}

osShouzhu:addEffect(fk.TurnStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osShouzhu.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askToChoosePlayers(
      player,
      {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#os__shouzhu-ask",
        skill_name = osShouzhu.name,
      }
    )
    if #targets > 0 then
      event:setCostData(self, {tos = targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(player, "@os__shouzhu", to.general)
    room:setPlayerMark(player, "_os__shouzhu", to.id)
  end,

  can_refresh = function(self, event, target, player)
    return target == player and player:getMark("_os__shouzhu") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    player.room:setPlayerMark(player, "_os__shouzhu", 0)
    player.room:setPlayerMark(player, "@os__shouzhu", 0)
  end,
})

osShouzhu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osShouzhu.name) and
      (player.phase == Player.Play and player:getMark("_os__shouzhu") ~= 0)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(
      room:getPlayerById(player:getMark("_os__shouzhu")),
      {
        min_num = 1,
        max_num = 4,
        include_equip = true,
        skill_name = osShouzhu.name,
        prompt = "#os__shouzhu-give:" .. player.id,
      }
    )
    if #cards > 0 then
      event:setCostData(self, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osShouzhu.name
    local room = player.room
    local cards = event:getCostData(self)
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, skillName, nil, false, player)
    local num = #cards
    if num > 1 then
      local companion = room:getPlayerById(player:getMark("_os__shouzhu"))
      if companion:isAlive() then
        companion:drawCards(1, skillName)
      end
      for _, p in ipairs { player, companion } do
        if not p.dead then
          local ret = room:askToArrangeCards(
            p,
            {
              card_map = {
                room:getNCards(num),
                "Bottom",
                "pile_discard",
              },
              skill_name = skillName,
              prompt = "#os__shouzhu",
              free_arrange = true,
              box_size = 0,
              max_limit = { num, num },
              min_limit = { 0, 0 },
            }
          )

          local discard, bottom = ret[2], ret[1]
          room:moveCardTo(discard, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skillName, nil, true, p)
          for i = 1, #bottom do
            table.removeOne(room.draw_pile, bottom[i])
            table.insert(room.draw_pile, bottom[i])
          end
          room:sendLog{
            type = "#GuanxingResult",
            from = p.id,
            arg = 0,
            arg2 = #bottom,
          }
        end
      end
    end
  end,
})

return osShouzhu
