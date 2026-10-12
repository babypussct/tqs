local lunzhan = fk.CreateSkill{
  name = "lunzhan",
}

Fk:loadTranslationTable{
  ["lunzhan"] = "轮战",
  [":lunzhan"] = "出牌阶段，你可将任意张牌当一张【决斗】使用（至多为5，且本回合不可重复）。若你以此法对唯一目标造成了伤害，"..
  "你可摸X张牌，然后你本回合不能再对目标角色发动此技能（X为本回合你使用牌指定其为目标的次数）。",

  ["#lunzhan"] = "轮战：将任意张牌当【决斗】使用（至多5张，本回合张数不能重复）",
  ["#lunzhan-draw"] = "轮战：是否摸%arg张牌，本回合不能再对 %dest 发动“轮战”？",

  ["$lunzhan1"] = "杀！尽歼贼败军之众。",
  ["$lunzhan2"] = "白马公孙？哼！不过吾一合之敌！",
}

lunzhan:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#lunzhan",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 5,
    pattern = ".",
  },
  view_as = function (self, player, cards)
    if #cards == 0 or #cards > 5 or table.contains(player:getTableMark("lunzhan-turn"), #cards) then return end
    local card = Fk:cloneCard("duel")
    card:addSubcards(cards)
    card.skillName = lunzhan.name
    return card
  end,
  before_use = function (self, player, use)
    player.room:addTableMark(player, "lunzhan-turn", #use.card.subcards)
  end,
  enabled_at_play = function (self, player)
    return #player:getTableMark("lunzhan-turn") < 5
  end,
})

lunzhan:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player ~= target or not player:hasSkill(lunzhan.name) then return false end
    if not (data.card and table.contains(data.card.skillNames, lunzhan.name)) then return false end
    local room = player.room
    local useEvent = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if useEvent == nil then return false end
    local use = useEvent.data
    return #use.tos == 1 and use.tos[1] == data.to
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = data.to
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
      local use = e.data
      return use.from == player and table.contains(use.tos, to)
    end, Player.HistoryTurn)
    if player.room:askToSkillInvoke(player, {
      skill_name = lunzhan.name,
      prompt = "#lunzhan-draw::"..to.id..":"..n,
    }) then
      event:setCostData(self, {tos = {data.to}, number = n})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:addTableMark(player, "lunzhan_prohibit-turn", data.to.id)
    player:drawCards(event:getCostData(self).number, lunzhan.name)
  end,
})

lunzhan:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return card and table.contains(card.skillNames, lunzhan.name) and from and
      table.contains(from:getTableMark("lunzhan_prohibit-turn"), to.id)
  end,
})

return lunzhan
