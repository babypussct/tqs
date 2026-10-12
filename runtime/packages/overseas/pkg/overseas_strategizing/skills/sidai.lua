local sidai = fk.CreateSkill {
  name = "os__sidai",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__sidai"] = "伺怠",
  [":os__sidai"] = "限定技，出牌阶段，你可以将所有基本牌当一张【杀】使用（无距离次数限制）。若这些牌中有："..
  "【酒】，此【杀】造成伤害时，伤害翻倍；"..
  "【桃】，此【杀】造成伤害后，受到伤害角色减1点体力上限；"..
  "【闪】，此【杀】的目标需弃置一张基本牌，否则不能响应。",

  ["#os__sidai_nojink"] = "伺怠：弃置一张基本牌，否则不能响应此【杀】",
  ["#os__sidai"] = "伺怠：将所有基本牌当【杀】使用（有酒、桃、闪则获得额外效果！）",

  ["$os__sidai1"] = "敌军疲乏，正是战机，随我杀！",
  ["$os__sidai2"] = "敌军无备，随我冲锋！",
}

sidai:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#os__sidai",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("slash")
    c:addSubcards(table.filter(player:getCardIds("h"), function(cid)
      return Fk:getCardById(cid).type == Card.TypeBasic
    end))
    c.skillName = sidai.name
    return c
  end,
  before_use = function(self, player, use)
    local basic_cards = {}
    for _, id in ipairs(use.card.subcards) do
      table.insertIfNeed(basic_cards, Fk:getCardById(id).name)
    end
    use.extraUse = true
    use.extra_data = use.extra_data or {}
    use.extra_data.os__sidaiBuff = basic_cards
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(sidai.name, Player.HistoryGame) == 0 and
      table.find(player:getCardIds("h"), function(cid)
        return Fk:getCardById(cid).type == Card.TypeBasic
      end)
  end,
})

sidai:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not data.card or not table.contains(data.card.skillNames, sidai.name) then
      return false
    end

    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if not parentUseData then
      return false
    end

    local buff = (parentUseData.data.extra_data or Util.DummyTable).os__sidaiBuff or Util.DummyTable
    return table.contains(buff, "analeptic")
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(data.damage)
  end,
})

sidai:addEffect(fk.Damage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not data.card or not table.contains(data.card.skillNames, sidai.name) then
      return false
    end

    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if not parentUseData then
      return false
    end

    local buff = (parentUseData.data.extra_data or Util.DummyTable).os__sidaiBuff or Util.DummyTable
    return table.contains(buff, "peach") and data.to:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    player.room:changeMaxHp(data.to, -1)
  end,
})

sidai:addEffect(fk.TargetConfirmed, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not data.card or not table.contains(data.card.skillNames, sidai.name) then
      return false
    end

    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if not parentUseData then
      return false
    end

    local buff = (parentUseData.data.extra_data or Util.DummyTable).os__sidaiBuff or Util.DummyTable
    return table.contains(buff, "jink")
  end,
  on_use = function(self, event, target, player, data)
    if player:isKongcheng() or
      #player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        skill_name = sidai.name,
        pattern = ".|.|.|.|.|basic",
        prompt = "#os__sidai_nojink"
      }) == 0
    then
      data.disresponsive = true
    end
  end,
})

sidai:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return (player:hasSkill(sidai.name) and card and table.contains(card.skillNames, sidai.name))
  end,
  bypass_distances = function (self, player, skill, card, to)
    return (player:hasSkill(sidai.name) and card and table.contains(card.skillNames, sidai.name))
  end
})

return sidai
