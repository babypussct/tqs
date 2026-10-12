local fire_attack = fk.CreateSkill{
  name = "os__hantian__fire_attack_skill",
}

Fk:loadTranslationTable{
  ["os__hantian__fire_attack_skill"] = "火攻",
  ["#os__hantian_fire_attack-show"] = "%src 对你使用了火攻，请展示一张本回合获得的手牌",
}

fire_attack:addEffect("cardskill", {
  prompt = "#fire_attack_skill",
  can_use = Util.CanUse,
  target_num = 1,
  mod_target_filter = function(self, _, to_select, _, _, _)
    return not to_select:isKongcheng()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if to:isKongcheng() then return end

    effect.extra_data = effect.extra_data or {}

    -- hantian
    local record = to:getTableMark("_os__hantian_cards-turn")
    local inHand = table.filter(to:getCardIds("h"), function(id) return table.contains(record, id) end)
    local params = { ---@type AskToCardsParams
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = fire_attack.name,
      cancelable = false,
      pattern = #inHand > 0 and tostring(Exppattern{ id = inHand }) or ".|.|.|hand",
      prompt = #inHand > 0 and "#os__hantian_fire_attack-show:" .. from.id or "#fire_attack-show:" .. from.id
    }
    local showCard = room:askToCards(to, params)[1]
    to:showCards(showCard)

    effect.extra_data.fire_attack_show = { showCard }

    showCard = Fk:getCardById(showCard)
    params = { ---@type AskToDiscardParams
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = fire_attack.name,
      cancelable = true,
      pattern = ".|.|" .. showCard:getSuitString(),
      prompt = "#fire_attack-discard:" .. to.id .. "::" .. showCard:getSuitString()
    }

    --火攻特化的特殊效果
    if effect.extra_data and effect.extra_data.extra_effect then
      local extra_effects = effect.extra_data.extra_effect or {}
      for k, func in pairs(extra_effects) do
        if type(func) == "function" then
          params = func(room, effect, showCard, params)
        end
      end
      if not params.skill_name then
        params.skill_name = "os__hantian"
      end
    end

    local cards = room:askToDiscard(from, params)
    if #cards > 0 and not to.dead then

      effect.extra_data.fire_attack_discard = cards

      room:damage({
        from = from,
        to = to,
        card = effect.card,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = fire_attack.name,
      })
    end
  end,
})

return fire_attack
