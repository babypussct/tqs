local fangyan = fk.CreateSkill {
  name = "os__fangyan",
  tags = { Skill.Compulsory },
  derived_piles = { "os__fangyan" },
}

Fk:loadTranslationTable {
  ["os__fangyan"] = "芳妍",
  [":os__fangyan"] = "锁定技，结束阶段或当你的体力值减少后，你可以获得武将牌上所有“芳妍”牌并摸等量张牌。" ..
      "除“芳妍”牌包含的花色外，你所有其他花色的牌和判定牌视为<font color='red'>♥</font>。",

  ["$os__fangyan1"] = "军士征战于外，我等当共协于内。",
  ["$os__fangyan2"] = "军民同心协力，共抗外来之敌！",
}

---@type TrigSkelSpec<HpChangedTrigFunc|PhaseFunc>
local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(fangyan.name) and #player:getPile("os__fangyan") > 0) then return end
    if event == fk.HpChanged then
      return data.num < 0
    else
      return player.phase == Player.Finish
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = fangyan.name,
    })
  end,
  on_use = function(self, event, target, player, data)
    local num = #player:getPile("os__fangyan")
    player.room:obtainCard(player, player:getPile("os__fangyan"), true, fk.ReasonPrey, player, fangyan.name)
    if player.dead then return end
    player:drawCards(num, fangyan.name)
  end,
}

fangyan:addEffect(fk.EventPhaseStart, spec)
fangyan:addEffect(fk.HpChanged, spec)

fangyan:addEffect("filter", {
  card_filter = function(self, to_select, player, isJudgeEvent)
    if player:hasSkill(fangyan.name) and (table.contains(player:getCardIds("he"), to_select.id) or isJudgeEvent) then
      local pile = player:getPile("os__fangyan")
      local suit = {}
      for _, id in ipairs(pile) do
        local card = Fk:getCardById(id)
        suit[card.suit] = true
      end
      if not suit[to_select.suit] and to_select.suit ~= Card.Heart and to_select.suit ~= Card.NoSuit then
        return true
      end
    end
  end,
  view_as = function(self, player, to_select)
    return Fk:cloneCard(to_select.name, Card.Heart, to_select.number)
  end,
})

return fangyan
