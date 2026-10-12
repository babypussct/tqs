local jiaoyu = fk.CreateSkill{
  name = "jiaoyu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiaoyu"] = "椒遇",
  [":jiaoyu"] = "锁定技，每轮开始时，你进行X次判定（X为你空置装备栏数），然后声明一种颜色并获得此颜色的判定牌。"..
    "你的下回合结束时，你执行一个额外出牌阶段（你不能使用与声明颜色不同的牌），"..
    "此阶段其他角色不能使用与你装备区牌颜色相同的牌直到有角色受到伤害时。",

  ["@jiaoyu-round"] = "椒遇",
  ["#jiaoyu-choice"] = "椒遇：选择获得一种颜色的判定牌",

  ["$jiaoyu1"] = "椒房熠辉，长寄心于君王。",
  ["$jiaoyu2"] = "妾本蒲柳，幸载皇恩，昭母仪于天下。",
}

jiaoyu:addEffect(fk.RoundStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiaoyu.name) and player:hasEmptyEquipSlot()
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "jiaoyu_extra_phase-round", 1)
    local n = #table.filter({3, 4, 5, 6, 7}, function (sub_type)
      return player:hasEmptyEquipSlot(sub_type)
    end)
    local cards = {}
    for _ = 1, n, 1 do
      local judge = {
        who = player,
        reason = jiaoyu.name,
        pattern = ".",
      }
      room:judge(judge)
      if judge.card then
        table.insert(cards, judge.card.id)
      end
    end
    if not player.dead then
      local color = room:askToChoice(player, {
        choices = {"red", "black"},
        skill_name = jiaoyu.name,
        prompt = "#jiaoyu-choice",
      })
      room:setPlayerMark(player, "@jiaoyu-round", color)
      room:setPlayerMark(player, "jiaoyu_color", color)
      local get = table.filter(cards, function (id)
        return Fk:getCardById(id):getColorString() == color and table.contains(room.discard_pile, id)
      end)
      if #get > 0 then
        room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonJustMove, jiaoyu.name, nil, true, player)
      end
    end
  end,
})
jiaoyu:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:getMark("jiaoyu_extra_phase-round") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "jiaoyu_extra_phase-round", 0)
    player:gainAnExtraPhase(Player.Play, jiaoyu.name)
  end,
})
jiaoyu:addEffect(fk.EventPhaseStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player.phase == Player.Play and data.reason == jiaoyu.name
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "jiaoyu_self_prohibit-phase", 1)
    room:setPlayerMark(player, "jiaoyu_prohibit-phase", 1)
  end,
})
jiaoyu:addEffect(fk.DamageInflicted, {
  can_refresh = function (self, event, target, player, data)
    return player:getMark("jiaoyu_prohibit-phase") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "jiaoyu_prohibit-phase", 0)
  end,
})
jiaoyu:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if card then
      if player:getMark("jiaoyu_self_prohibit-phase") > 0 then
        return not card:matchVSPattern(".|.|" .. player:getMark("@jiaoyu-round"))
      else
        local src = table.find(Fk:currentRoom().alive_players, function (p)
          return p:getMark("jiaoyu_prohibit-phase") > 0
        end)
        if src and src ~= player then
          local colors = {}
          for _, cid in ipairs(src:getCardIds("e")) do
            table.insertIfNeed(colors, Fk:getCardById(cid):getColorString())
          end
          if #colors > 0 then
            return not card:matchVSPattern(".|.|^(" .. table.concat(colors, ",") .. ")")
          end
        end
      end
    end
  end,
})

return jiaoyu
