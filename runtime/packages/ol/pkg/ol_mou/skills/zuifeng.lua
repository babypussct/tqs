local zuifeng = fk.CreateSkill {
  name = "zuifeng",
  max_phase_use_time = function (self, player)
    return player.maxHp
  end,
}

Fk:loadTranslationTable {
  ["zuifeng"] = "醉锋",
  [":zuifeng"] = "出牌阶段限X次（X为你的体力上限），你可以弃置一个花色的唯一手牌并选择一名角色，你观看其的手牌并展示其中一张。" ..
  "若弃置牌与展示牌花色相同，你对其造成1点火焰伤害。其可以将此牌当【酒】对你使用。",

  ["#zuifeng"] = "醉锋：弃置一个花色的唯一手牌，观看并展示一名角色一张手牌，若花色相同则对其造成1点火焰伤害",
  ["#zuifeng-show"] = "醉锋：展示 %dest 一张手牌，若为%arg则对其造成1点火焰伤害",
  ["#zuifeng-use"] = "醉锋：是否将%arg当【酒】对 %src 使用？",

  ["$zuifeng1"] = "",
  ["$zuifeng2"] = "",
}

local U = require "packages.utility.utility"

zuifeng:addEffect("active", {
  anim_type = "offensive",
  prompt = "#zuifeng",
  times = function (self, player)
    return player.maxHp - player:usedSkillTimes(zuifeng.name)
  end,
  card_num = 0,
  target_num = 1,
  interaction_helper = function(self, player)
    local count = { 0, 0, 0, 0 }
    for _, id in ipairs(player:getCardIds("h")) do
      local suit = Fk:getCardById(id).suit
      if suit < 5 then
        if player:prohibitDiscard(id) then
          count[suit] = 100
        end
        count[suit] = count[suit] + 1
      end
    end
    local choices = {}
    for i = 1, 4 do
      if count[i] == 1 then
        table.insert(choices, U.ConvertSuit(i, "int", "sym"))
      end
    end
    return UI.OptionBox { options = choices, all_options = { "log_spade", "log_heart", "log_club", "log_diamond" } }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getSuitString(true) == self.interaction.data
    end)
    room:throwCard(card, zuifeng.name, player, player)
    if player.dead or target:isKongcheng() then return end
    local id = room:askToChooseCard(player, {
      target = target,
      flag = { card_data = { { target.general, target:getCardIds("h") } } },
      skill_name = zuifeng.name,
      prompt = "#zuifeng-show::" .. target.id .. ":" .. self.interaction.data,
    })
    local yes = Fk:getCardById(id):getSuitString(true) == self.interaction.data
    target:showCards(id)
    if yes and not target.dead then
      room:damage {
        from = player,
        to = target,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = zuifeng.name,
      }
    end
    if table.contains(target:getCardIds("h"), id) and not player.dead then
      card = Fk:cloneCard("analeptic")
      card:addSubcard(id)
      card.skillName = zuifeng.name
      if ((target == player and target:canUseTo(card, player, { bypass_times = false })) or
            (target ~= player and target:canUseTo(card, player, { bypass_times = true }))) and
          room:askToSkillInvoke(target, {
            skill_name = zuifeng.name,
            prompt = "#zuifeng-use:" .. player.id .. "::" .. Fk:getCardById(id):toLogString(),
          }) then
        room:useVirtualCard("analeptic", { id }, target, player, zuifeng.name, false)
      end
    end
  end,
}, { check_skill_limit = true })

return zuifeng
