local taoluan = fk.CreateSkill {
  name = "taoluanh",
}

Fk:loadTranslationTable{
  ["taoluanh"] = "讨乱",
  [":taoluanh"] = "每回合限一次，当一名角色判定牌生效前，若判定结果为♠，你可以终止此次判定并选择一项：1.你获得此判定牌；"..
  "2.若进行判定的角色不是你，你视为对其使用一张无距离次数限制的火【杀】。",

  ["#taoluanh-invoke"] = "讨乱：%dest 的判定即将生效，你可以终止此判定并执行一项！",
  ["taoluanh_prey"] = "获得判定牌",
  ["taoluanh_slash"] = "视为对%dest使用火【杀】",

  ["$taoluanh1"] = "乱民桀逆，非威不服！",
  ["$taoluanh2"] = "欲定黄巾，必赖兵革之利！",
}

taoluan:addEffect(fk.FinishJudge, {
  anim_type = "control",
  priority = 1.1,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(taoluan.name) and data.card.suit == Card.Spade and
      player:usedSkillTimes(taoluan.name, Player.HistoryTurn) == 0 and
      (player.room:getCardArea(data.card) == Card.Processing or
        (target ~= player and not target.dead and
        player:canUseTo(Fk:cloneCard("fire__slash"), target, {bypass_distances = true, bypass_times = true})))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    if room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, "taoluanh_prey")
    end
    if target ~= player and not target.dead and
      player:canUseTo(Fk:cloneCard("fire__slash"), target, {bypass_distances = true, bypass_times = true}) then
      table.insert(choices, "taoluanh_slash::"..target.id)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = taoluan.name,
      prompt = "#taoluanh-invoke::"..target.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
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
    if event:getCostData(self).choice == "taoluanh_prey" then
      room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, taoluan.name)
    else
      room:useVirtualCard("fire__slash", nil, player, target, taoluan.name, true)
    end
  end,
})

return taoluan
