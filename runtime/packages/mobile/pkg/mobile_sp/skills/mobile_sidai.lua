local mobileSidai = fk.CreateSkill {
  name = "mobile__sidai",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["mobile__sidai"] = "伺怠",
  [":mobile__sidai"] = "限定技，出牌阶段，你可将所有基本牌当【杀】使用（不计入次数）。若这些牌中有：【桃】，" ..
  "此【杀】造成伤害后，受到伤害角色减1点体力上限；【闪】，此【杀】的目标需弃置一张基本牌，否则不能响应。",

  ["#mobile__sidai_nojink"] = "伺怠：弃置一张基本牌，否则不能响应此【杀】",
  ["#mobile__sidai"] = "伺怠：你可将所有基本牌当【杀】使用（有桃、闪则获得额外效果）！",

  ["$mobile__sidai1"] = "敌已力竭，到吾主动出击之时！",
  ["$mobile__sidai2"] = "敌军疲惫，吾等可趁势击之！",
}

mobileSidai:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#mobile__sidai",
  card_filter = Util.FalseFunc,
  filter_pattern = function (self, player, card_name, selected)
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).type == Card.TypeBasic
    end)
    local n = #cards
    if n > 0 then
      return {
        min_num = n,
        max_num = n,
        pattern = ".|.|.|hand",
        subcards = cards
      }
    end
  end,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("slash")
    c:addSubcards(table.filter(player:getCardIds("h"), function(cid)
      return Fk:getCardById(cid).type == Card.TypeBasic
    end))
    c.skillName = mobileSidai.name
    return c
  end,
  before_use = function(self, player, use)
    local basic_cards = {}
    for _, id in ipairs(use.card.subcards) do
      table.insertIfNeed(basic_cards, Fk:getCardById(id).name)
    end
    use.extraUse = true
    use.extra_data = use.extra_data or {}
    use.extra_data.mobile__sidaiBuff = basic_cards
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(mobileSidai.name, Player.HistoryGame) == 0 and table.find(player:getCardIds("h"), function(cid)
      return Fk:getCardById(cid).type == Card.TypeBasic
    end)
  end,
  enabled_at_response = Util.FalseFunc,
})

mobileSidai:addEffect(fk.Damage, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not data.card or not table.contains(data.card.skillNames, mobileSidai.name) then
      return false
    end

    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if not parentUseData then
      return false
    end

    local buff = (parentUseData.data.extra_data or Util.DummyTable).mobile__sidaiBuff or Util.DummyTable
    return table.contains(buff, "peach") and data.to:isAlive()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:changeMaxHp(data.to, -1)
  end,
})

mobileSidai:addEffect(fk.TargetConfirmed, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not data.card or not table.contains(data.card.skillNames, mobileSidai.name) then
      return false
    end

    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if not parentUseData then
      return false
    end

    local buff = (parentUseData.data.extra_data or Util.DummyTable).mobile__sidaiBuff or Util.DummyTable
    return table.contains(buff, "jink")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if
      player:isKongcheng() or
      #player.room:askToDiscard(
        player,
        {
          min_num = 1,
          max_num = 1,
          skill_name = mobileSidai.name,
          pattern = ".|.|.|.|.|basic",
          prompt = "#mobile__sidai_nojink"
        }
      ) == 0
    then
      data.disresponsive = true
    end
  end,
})

return mobileSidai
