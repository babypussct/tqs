local skill = fk.CreateSkill {
  name = "floating_thunder_skill",
}

skill:addEffect("cardskill", {
  prompt = "#floating_thunder_skill",
  mod_target_filter = Util.TrueFunc,
  can_use = Util.CanUseToSelf,
  on_effect = function(self, room, effect)
    local to = effect.to
    local judge = {
      who = to,
      reason = "floating_thunder",
      pattern = ".|.|spade",
    }
    room:judge(judge)
    if judge:matchPattern() then
      local card = Fk:getCardById(effect.card:getEffectiveId())
      room:addCardMark(card, "_floating_thunder")
      room:damage{
        to = to,
        damage = card:getMark("_floating_thunder"),
        card = effect.card,
        damageType = Fk:getDamageNature(fk.ThunderDamage) and fk.ThunderDamage or fk.NormalDamage,
        skillName = skill.name,
      }
    end
    self:onNullified(room, effect)
  end,
  on_nullified = function(self, room, effect)
    local to = effect.to
    local nextp = to
    repeat
      nextp = nextp:getNextAlive(true)
      if nextp == to then
        if nextp:isProhibited(nextp, effect.card) then
          room:moveCards{
            ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPut,
          }
          return
        end
        break
      end
    until not nextp:hasDelayedTrick("floating_thunder") and not nextp:isProhibited(nextp, effect.card)


    if effect.card:isVirtual() then
      nextp:addVirtualEquip(effect.card)
    end

    room:moveCards{
      ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
      to = nextp,
      toArea = Card.PlayerJudge,
      moveReason = fk.ReasonPut,
    }
  end,
})

return skill
