local sheque = fk.CreateSkill {
  name = "sheque",
}

Fk:loadTranslationTable{
  ["sheque"] = "射却",
  [":sheque"] = "一名其他角色的准备阶段，若其装备区有牌，你可以对其使用一张无距离限制的【杀】，此【杀】无视防具。",

  ["#sheque-invoke"] = "射却：你可以对 %dest 使用一张无距离限制且无视防具的【杀】",

  ["$sheque1"] = "看我此箭，取那轻舟冒进之人性命！",
  ["$sheque2"] = "纵有劲甲良盾，也难挡我神射之威！",
}

sheque:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(sheque.name) and
      target.phase == Player.Start and #target:getCardIds("e") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askToUseCard(player, {
      skill_name = sheque.name,
      pattern = "slash",
      prompt = "#sheque-invoke::"..target.id,
      cancelable = true,
      extra_data = {
        exclusive_targets = {target.id},
        bypass_distances = true,
        bypass_times = true,
      }
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local use = event:getCostData(self).extra_data
    use.extra_data = use.extra_data or {}
    use.extra_data.shequeUser = player.id
    use.extraUse = true
    player.room:useCard(use)
  end,
})
sheque:addEffect(fk.TargetSpecified, {
  can_refresh = function (self, event, target, player, data)
    return not player.dead and (data.extra_data or {}).shequeUser == player.id and not data.to.dead
  end,
  on_refresh = function (self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})

return sheque
