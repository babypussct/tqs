local fangong = fk.CreateSkill {
  name = "jiange__fangong",
}

Fk:loadTranslationTable{
  ["jiange__fangong"] = "反攻",
  [":jiange__fangong"] = "当敌方角色对你使用牌结算后，你可以对其使用一张【杀】。",

  ["#jiange__fangong-slash"] = "反攻：你可以对 %dest 使用一张【杀】",
}

fangong:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fangong.name) and target:isEnemy(player) and
      not target.dead and table.contains(data.tos, player)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseCard(player, {
    skill_name = "slash",
    pattern = "slash",
    prompt = "#jiange__fangong-slash::" .. target.id,
    cancelable = true,
    extra_data = {
      exclusive_targets = {target.id},
      bypass_distances = true,
      bypass_times = true,
    }
  })
    if use then
      use.extraUse = true
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

return fangong
