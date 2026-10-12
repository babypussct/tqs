local zhengong = fk.CreateSkill {
  name = "zhengong",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["zhengong"] = "震弓",
  [":zhengong"] = "限定技，出牌阶段，你可以弃置任意张同名牌，然后对任意名其他角色造成共计与弃牌数等量的伤害，"..
    "因此受到伤害的角色本回合非锁定技失效。",

  ["#zhengong-active"] = "震弓：弃置任意张同名牌，然后对任意名其他角色造成共计等量的伤害",
  ["#zhengong-target"] = "震弓：选择任意名其他角色，对这些角色分配%arg点伤害",
  ["#zhengong-number"] = "震弓：选择分配给%dest的伤害点数（至多为%arg）",
  ["@@zhengong-turn"] = "震弓",

  ["$zhengong1"] = "苍龙饮涧，孤鸿断翅！",
  ["$zhengong2"] = "弓满血月隐，放箭残阳裂！",
}

zhengong:addEffect("active", {
  anim_type = "offensive",
  prompt = "#zhengong-active",
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if player:prohibitDiscard(to_select) then return false end
    if #selected == 0 then
      return true
    else
      return Fk:getCardById(to_select).trueName == Fk:getCardById(selected[1]).trueName
    end
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local skillName = zhengong.name
    room:throwCard(effect.cards, skillName, player, player)
    if player.dead then return end
    local tos = room:getOtherPlayers(player, false)
    if #tos == 0 then return end
    local x = #effect.cards
    tos = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = x,
      prompt = "#zhengong-target:::" .. x,
      skill_name = skillName,
      cancelable = false
    })
    room:sortByAction(tos)
    local list = {}
    for _, p in ipairs(tos) do
      local y = room:askToNumber(player, {
        min = 1,
        max = x,
        skill_name = skillName,
        cancelable = false,
        prompt = "#zhengong-number::"..p.id..":"..x
      })
      x = x - y
      table.insert(list, y)
      if x < 1 then break end
    end
    for i = 1, #list, 1 do
      local to = tos[i]
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = list[i],
          skillName = skillName,
        }
      end
    end
  end
}, { check_skill_limit = true })

--免伤技能之后，伤势之前，机制不明
zhengong:addEffect(fk.HpChanged, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.damageEvent and data.damageEvent.skillName == zhengong.name
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@@zhengong-turn", 1)
    room:addPlayerMark(player, MarkEnum.UncompulsoryInvalidity .. "-turn")
  end,
})

return zhengong
