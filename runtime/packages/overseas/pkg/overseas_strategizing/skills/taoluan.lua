local taoluan = fk.CreateSkill {
  name = "os__taoluanh",
}

Fk:loadTranslationTable{
  ["os__taoluanh"] = "讨乱",
  [":os__taoluanh"] = "每回合限一次，当判定牌生效前，你可以弃置一张与判定牌花色相同的牌，"..
  "然后终止此次判定。",

  ["#os__taoluanh-invoke"] = "讨乱：%dest 的判定即将生效，你可以弃置一张%arg牌，终止此判定",

  ["$os__taoluanh1"] = "乱民不可德化，臣愿出军讨之。",
  ["$os__taoluanh2"] = "今须以三军之势，昭陛下雷霆之威。",
}

taoluan:addEffect(fk.FinishJudge, {
  anim_type = "control",
  priority = 1.1,
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(taoluan.name) and
      data.card and
      data.card.suit ~= Card.NoSuit and
      not player:isNude() and
      player:usedSkillTimes(taoluan.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = taoluan.name,
      cancelable = true,
      pattern = ".|.|" .. data.card:getSuitString(),
      prompt = "#os__taoluanh-invoke::" .. target.id .. ":" .. data.card:getSuitString(),
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, taoluan.name, player, player)
    local e = room.logic:getCurrentEvent():findParent(GameEvent.SkillEffect)
    if e then
      room.logic:getCurrentEvent():addExitFunc(function()
        e:shutdown()
      end)
      -- 手杀幽默本意，被终止结算的延时锦囊牌要放回判定区
      local parent = e.parent
      if parent and parent.event == GameEvent.CardEffect then
        local effect = parent.data
        if effect.card.sub_type == Card.SubtypeDelayedTrick and room:getCardArea(effect.card:getEffectiveId()) == Card.Processing
          and not target.dead and not target:isProhibitedTarget(effect.card)
          then
          local card = effect.card
          local vcard
          if card:isVirtual() then
            vcard = Fk:cloneCard(card.name)
            vcard:addSubcards(effect.card.subcards)
            vcard.skillNames = effect.card.skillNames
          end
          room:moveCards{
            to = target,
            toArea = Player.Judge,
            ids = {card:getEffectiveId()},
            moveReason = fk.ReasonJustMove,
            skillName = taoluan.name,
            virtualEquip = vcard,
          }
        end
      end
    end
  end,
})

return taoluan
