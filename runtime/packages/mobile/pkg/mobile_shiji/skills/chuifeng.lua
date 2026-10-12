local chuifeng = fk.CreateSkill {
  name = "chuifeng",
  tags = { Skill.AttachedKingdom },
  attached_kingdom = {"wei"},
}

Fk:loadTranslationTable{
  ["chuifeng"] = "椎锋",
  [":chuifeng"] = "魏势力技，出牌阶段限两次，你可以失去1点体力，视为使用一张【决斗】。当你受到以此法使用的【决斗】造成的伤害时，"..
  "防止此伤害，此技能于此阶段内无效。",

  ["#chuifeng"] = "椎锋：你可以失去1点体力，视为使用一张【决斗】",

  ["$chuifeng1"] = "率军冲锋，不惧刀枪所阻！",
  ["$chuifeng2"] = "登锋履刃，何妨马革裹尸！",
}

chuifeng:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#chuifeng",
  times = function(self, player)
    return player.phase == Player.Play and 2 - player:usedSkillTimes(chuifeng.name, Player.HistoryPhase) or -1
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("duel")
    card.skillName = chuifeng.name
    return card
  end,
  before_use = function(self, player, use)
    use.extra_data = use.extra_data or {}
    use.extra_data.chuifeng = player
    player.room:loseHp(player, 1, chuifeng.name)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(chuifeng.name, Player.HistoryPhase) < 2 and player.hp > 0
  end,
})
chuifeng:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and data.card and table.contains(data.card.skillNames, chuifeng.name) then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      return use_event and (use_event.data.extra_data or {}).chuifeng == player
    end
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
    player.room:invalidateSkill(player, "chuifeng", "-phase")
  end,
})

return chuifeng
