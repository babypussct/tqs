local zigu = fk.CreateSkill {
  name = "zigu",
}

Fk:loadTranslationTable{
  ["zigu"] = "自固",
  [":zigu"] = "出牌阶段限一次，你可以弃置一张牌，然后获得场上一张装备牌。若你没有因此获得其他角色的牌，你摸一张牌。",

  ["#zigu"] = "自固：你可以弃置一张牌，然后获得场上一张装备牌",
  ["#zigu-choose"] = "自固：选择一名角色，获得其场上一张装备牌",
  ["#zigu-prey"] = "自固：获得 %dest 场上一张装备牌",

  ["$zigu1"] = "卿有成材良木，可妆吾家江山。",
  ["$zigu2"] = "吾好锦衣玉食，卿家可愿割爱否？"
}

zigu:addEffect("active", {
  anim_type = "control",
  prompt = "#zigu",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zigu.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, zigu.name, player, player)
    if player.dead then return end
    local targets = table.filter(room.alive_players, function(p)
      return #p:getCardIds("e") > 0
    end)
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#zigu-choose",
        skill_name = zigu.name,
        cancelable = false,
      })[1]
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "e",
        skill_name = zigu.name,
        prompt = "#zigu-prey::"..to.id,
      })
      room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, zigu.name, nil, true, player)
    end
    if not player.dead then
      -- 十周年有防止移动的效果，须检测真实移动
      local current = room.logic:getCurrentEvent()
      if #room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        if e.parent == current then
          for _, move in ipairs(e.data) do
            if move.to == player and move.toArea == Player.Hand and move.skillName == zigu.name and move.from and move.from ~= player then
              if #move.moveInfo > 0 then
                return true
              end
            end
          end
        end
      end, current.id) == 0 then
        player:drawCards(1, zigu.name)
      end
    end
  end,
})

return zigu
