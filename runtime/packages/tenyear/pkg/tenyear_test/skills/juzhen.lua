
local juzhen = fk.CreateSkill {
  name = "juzhen",
}

Fk:loadTranslationTable{
  ["juzhen"] = "举阵",
  [":juzhen"] = "你的回合外，其他角色对你使用的基本牌或普通锦囊牌结算后，若你的手牌数大于等于体力值，你可以将一张手牌当此牌对该角色使用。",

  ["#juzhen-use"] = "举阵：你可以将一张手牌当【%arg】对 %dest 使用",

  ["$juzhen1"] = "",
  ["$juzhen2"] = "",
}

juzhen:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(juzhen.name) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and table.contains(data.tos, player) and
      player.room:getCurrent() ~= player and player:getHandcardNum() >= player.hp and #player:getHandlyIds() > 0 and
      not target.dead and player:canUseTo(data.card, target, { bypass_distances = true, bypass_times = true })
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = data.card.name,
      skill_name = juzhen.name,
      prompt = "#juzhen-use::"..target.id..":"..data.card.name,
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        exclusive_targets = { target.id },
      },
      card_filter = {
        n = 1,
        cards = player:getHandlyIds(),
      },
      skip = true,
    })
    if use then
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

return juzhen
