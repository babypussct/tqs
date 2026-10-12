local baguan = fk.CreateSkill {
  name = "baguan",
  tags = { Skill.Combo },
}

Fk:loadTranslationTable{
  ["baguan"] = "霸关",
  [":baguan"] = "连招技（单目标牌+武器牌），你可以将至多X张手牌当一张【杀】使用（X为此武器牌的牌名字数），伤害基数等于你用于转化的牌数。",

  ["#baguan-use"] = "霸关：你可以将至多%arg张手牌当【杀】使用（伤害基数为你选择的牌数）",
  ["@@baguan"] = "霸关 +武器牌",

  ["$baguan1"] = "颅献白骨观，血祭黄沙场！",
  ["$baguan2"] = "拥酒炙胡马，北虏复唱匈奴歌！",
}

baguan:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(baguan.name) and
      data.card.sub_type == Card.SubtypeWeapon and
      data.extra_data and data.extra_data.combo_skill and data.extra_data.combo_skill[baguan.name] and
      table.contains(player:getEquipments(Card.SubtypeWeapon), data.card.id) and
      #player:getHandlyIds() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = data.card:getNameLength()
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = baguan.name,
      prompt = "#baguan-use:::"..n,
      cancelable = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
      card_filter = {
        n = { 1, n },
        cards = player:getHandlyIds(),
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@baguan", 0)
    local use = event:getCostData(self).extra_data
    use.additionalDamage = #Card:getIdList(use.card) - 1
    room:useCard(use)
  end,
})

baguan:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(baguan.name, true) and
      not table.contains(data.card.skillNames, baguan.name)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("@@baguan") > 0 and data.card.sub_type == Card.SubtypeWeapon then
      data.extra_data = data.extra_data or {}
      data.extra_data.combo_skill = data.extra_data.combo_skill or {}
      data.extra_data.combo_skill[baguan.name] = true
    end
    --此技能的单目标牌为使用时的目标数为1，非牌面属性
    if data.tos and #data.tos == 1 then
      room:setPlayerMark(player, "@@baguan", 1)
    else
      room:setPlayerMark(player, "@@baguan", 0)
    end
  end,
})

return baguan
