
local juzhanc = fk.CreateSkill {
  name = "juzhanc",
}

Fk:loadTranslationTable{
  ["juzhanc"] = "举战",
  [":juzhanc"] = "每回合限一次，你使用【杀】或普通锦囊牌指定目标后，若你的手牌数大于等于体力值，你可以弃置一张手牌令此牌额外结算一次。"..
  "其他角色对你使用的【杀】或普通锦囊牌结算完成后，若你的手牌数小于等于体力值，你可以将一张手牌当此【杀】或普通锦囊牌对其使用。",

  ["#juzhanc-invoke"] = "举战：你可以弃置一张手牌，令此%arg额外结算一次",
  ["#juzhanc-use"] = "举战：你可以将一张手牌当【%arg】对 %dest 使用",

  ["$juzhanc1"] = "",
  ["$juzhanc2"] = "",
}

juzhanc:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juzhanc.name) and
      data.firstTarget and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      player:getHandcardNum() >= player.hp and
      player:usedSkillTimes(juzhanc.name, Player.HistoryTurn) == 0 and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = juzhanc.name,
      cancelable = true,
      prompt = "#juzhanc-invoke:::" .. data.card:toLogString(),
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self).cards, juzhanc.name, player, player)
    data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
  end,
})

juzhanc:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(juzhanc.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and table.contains(data.tos, player) and
      player:getHandcardNum() <= player.hp and
      player:usedSkillTimes(juzhanc.name, Player.HistoryTurn) == 0 and #player:getHandlyIds() > 0 and
      not target.dead and player:canUseTo(data.card, target, { bypass_distances = true, bypass_times = true })
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = data.card.name,
      skill_name = juzhanc.name,
      prompt = "#juzhanc-use::"..target.id..":"..data.card.name,
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

return juzhanc
