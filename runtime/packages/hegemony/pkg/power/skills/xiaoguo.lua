local xiaoguo = fk.CreateSkill {
  name = "jianan__hs__xiaoguo",
}

Fk:loadTranslationTable {
  ["jianan__hs__xiaoguo"] = "骁果",
  [":jianan__hs__xiaoguo"] = "其他角色的结束阶段，你可以弃置一张基本牌，然后其选择一项：1.弃置一张装备牌，然后你摸一张牌；2.你对其造成1点伤害。",
  ["#jianan__hs__xiaoguo-invoke"] = "骁果：你可以弃置一张基本牌，%dest 需弃置一张装备牌，否则你对其造成1点伤害",
  ["#jianan__hs__xiaoguo-discard"] = "骁果：你需弃置一张装备牌，否则 %src 对你造成1点伤害",

  ["$jianan__hs__xiaoguo1"] = "使孤梦回辽东者，卿之雄风也！",
  ["$jianan__hs__xiaoguo2"] = "得贤人共治天下，得将军共定天下！",
}

xiaoguo:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xiaoguo.name) and target.phase == Player.Finish
        and not player:isKongcheng() and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = xiaoguo.name,
      cancelable = true,
      pattern = ".|.|.|.|.|basic",
      prompt = "#jianan__hs__xiaoguo-invoke::" .. target.id,
      skip = true
    })
    if #card > 0 then
      event:setCostData(self, { tos = { target }, cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, xiaoguo.name, player, player)
    if target.dead then return end
    if #room:askToDiscard(target, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = xiaoguo.name,
          cancelable = true,
          pattern = ".|.|.|.|.|equip",
          prompt = "#jianan__hs__xiaoguo-discard:" .. player.id,
        }) > 0 then
      if not player.dead then
        player:drawCards(1, xiaoguo.name)
      end
    else
      room:damage {
        from = player,
        to = target,
        damage = 1,
        skillName = xiaoguo.name,
      }
    end
  end,
})

return xiaoguo
