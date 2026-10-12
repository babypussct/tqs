
local zunjian = fk.CreateSkill {
  name = "ty__zunjian",
}

Fk:loadTranslationTable{
  ["ty__zunjian"] = "尊谏",
  [":ty__zunjian"] = "出牌阶段每种花色限一次，你可以弃置一种花色的所有手牌并令一名角色摸X张牌 （X为你手牌中缺少的花色数），"..
  "然后若其手牌数为全场唯一最多，其可以交给你至多两张手牌；若其体力值全场唯一最少，你可以令其回复1点体力。",

  ["#ty__zunjian"] = "尊谏：弃置一种花色的所有手牌，令一名角色摸你手牌缺少花色数张牌",
  ["@ty__zunjian-phase"] = "尊谏",
  ["#ty__zunjian-give"] = "尊谏：你可以交给 %src 至多两张手牌",
  ["#ty__zunjian-recover"] = "尊谏：你可以令 %dest 回复1点体力",

  ["$ty__zunjian1"] = "",
  ["$ty__zunjian2"] = "",
}

local all_suits = { "log_spade", "log_heart", "log_club", "log_diamond" }

zunjian:addEffect("active", {
  anim_type = "support",
  prompt = "#ty__zunjian",
  interaction = function (self, player)
    local all_choices = table.simpleClone(all_suits)
    local choices = {}
    for _, suit in ipairs(all_suits) do
      if not table.contains(player:getTableMark("@ty__zunjian-phase"), suit) and
        table.find(player:getCardIds("h"), function (id)
          return Fk:getCardById(id):getSuitString(true) == suit and not player:prohibitDiscard(id)
        end) then
        table.insert(choices, suit)
      end
    end
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return #player:getTableMark("@ty__zunjian-phase") < 4 and
      table.find(player:getCardIds("h"), function (id)
        return not table.contains(player:getTableMark("@ty__zunjian-phase"), Fk:getCardById(id):getSuitString(true)) and
          not player:prohibitDiscard(id)
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "@ty__zunjian-phase", self.interaction.data)
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getSuitString(true) == self.interaction.data and not player:prohibitDiscard(id)
    end)
    room:throwCard(cards, zunjian.name, player, player)
    if target.dead then return end
    local suits = table.simpleClone(all_suits)
    for _, id in ipairs(player:getCardIds("h")) do
      table.removeOne(suits, Fk:getCardById(id):getSuitString(true))
    end
    if #suits > 0 then
      target:drawCards(#suits, zunjian.name)
    end
    if player.dead or target.dead then return end
    if target ~= player and
      table.every(room:getOtherPlayers(target, false), function (p)
        return target:getHandcardNum() > p:getHandcardNum()
      end) then
      cards = room:askToCards(target, {
        min_num = 1,
        max_num = 2,
        include_equip = false,
        skill_name = zunjian.name,
        prompt = "#ty__zunjian-give:"..player.id,
        cancelable = true,
      })
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, zunjian.name, nil, false, target)
        if player.dead or target.dead then return end
      end
    end
    if target:isWounded() and
      table.every(room:getOtherPlayers(target, false), function (p)
        return target.hp < p.hp
      end) and
      room:askToSkillInvoke(player, {
        skill_name = zunjian.name,
        prompt = "#ty__zunjian-recover::"..target.id,
      }) then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = zunjian.name,
      }
    end
  end
})

return zunjian
