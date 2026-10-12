local renche = fk.CreateSkill {
  name = "renche",
  add_skills = {"#ThisTurnDiscardedRecorder"},
}

Fk:loadTranslationTable{
  ["renche"] = "刃掣",
  [":renche"] = "出牌阶段限X次，你可以弃置X张牌并令至多X名其他角色各弃置一张牌（X为本回合弃牌堆中【杀】的数量且至少为1）。"..
  "每有角色因此弃置牌不为【杀】，你便摸一张牌。",

  ["#renche"] = "刃掣：弃置%arg张牌，令至多%arg名其他角色各弃置一张牌",
  ["#renche-discard"] = "刃掣：弃置一张牌，若不为【杀】，%src 摸一张牌",

  ["@[olmou__zhurong_slash]"] = "杀",

  ["$renche1"] = "风驰电掣，例无虚发！",
  ["$renche2"] = "害怕了吗？我南中的战刃飞刀！",
}

---@return integer
local getSlashCount = function()
  local cards = Fk:currentRoom():getBanner(MarkEnum.ThisTurnDiscarded) or {}
  cards = table.filter(cards, function(id)
    return Fk:getCardById(id).trueName == "slash"
  end)
  return #cards
end

renche:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player)
    return "#renche:::"..math.max(getSlashCount(), 1)
  end,
  times = function(self, player)
    return player.phase == Player.Play and
      math.max(getSlashCount(), 1) - player:usedSkillTimes(renche.name, Player.HistoryPhase) or -1
  end,
  card_num = function (self, player)
    return math.max(getSlashCount(), 1)
  end,
  min_target_num = 1,
  max_target_num = function (self, player)
    return math.max(getSlashCount(), 1)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(renche.name, Player.HistoryPhase) < math.max(getSlashCount(), 1)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < math.max(getSlashCount(), 1) and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < math.max(getSlashCount(), 1) and to_select ~= player and not to_select:isNude()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local x = 0
    for _, id in ipairs(effect.cards) do
      if Fk:getCardById(id).trueName ~= "slash" then
        x = 1
        break
      end
    end
    room:throwCard(effect.cards, renche.name, player, player)

    local cardMap = room:askToJointCards(player, {
      players = effect.tos,
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = renche.name,
      cancelable = false,
      will_throw = true,
      prompt = "#renche-discard:" .. player.id,
    })

    --proposer各不相同的move
    local moveInfos = {}
    for p, cards in pairs(cardMap) do
      if #cards > 0 then
        if Fk:getCardById(cards[1]).trueName ~= "slash" then
          x = x + 1
        end
        table.insert(moveInfos, {
          ids = cards,
          from = p,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = p,
          skillName = renche.name
        })
      end
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    else
      --实测无角色可弃牌的情况下后续的摸牌不处理
      return
    end

    if not player.dead and x > 0 then
      player:drawCards(x, renche.name)
    end
  end,
})

renche:addAcquireEffect(function(self, player)
  player.room:setPlayerMark(player, "@[olmou__zhurong_slash]", 1)
end)

renche:addLoseEffect(function(self, player)
  if not player:hasSkill("yalian", true) then
    player.room:setPlayerMark(player, "@[olmou__zhurong_slash]", 0)
  end
end)

Fk:addQmlMark{
  name = "olmou__zhurong_slash",
  how_to_show = function(name, value, p)
    if Fk:currentRoom():getCurrent() == p then
      return tostring(getSlashCount())
    end
    return "#hidden"
  end,
}

return renche
