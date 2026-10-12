local H = require "packages.hegemony.util"

local liegong = fk.CreateSkill({
  name = "xuanhuo__hs__liegong",
  dynamic_desc = function(self, player)
    if H.hasHegLordSkill(Fk:currentRoom(), player, "shouyue") then
      return "hs__liegong_shouyue"
    else
      return "xuanhuo__hs__liegong"
    end
  end,
})

Fk:loadTranslationTable{
  ["xuanhuo__hs__liegong"] = "烈弓",
  [":xuanhuo__hs__liegong"] = "你对手牌数不大于你的角色使用【杀】无距离限制。"..
  "当你使用【杀】指定目标后，若目标角色的体力值不小于你，则你可以选择一项：1.令其不能使用【闪】响应此【杀】；2.令此【杀】造成的伤害+1。",
}

liegong:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liegong.name) and
      data.card.trueName == "slash" and data.to.hp >= player.hp
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "hs__liegong_disresponsive", "hs__liegong_damage" },
      skill_name = liegong.name,
      prompt = "#hs__liegong-invoke::"..data.to.id,
      cancelable = true,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local choice = event:getCostData(self).choice
    if choice == "hs__liegong_disresponsive" then
      data:setDisresponsive(data.to)
    else
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

liegong:addEffect("atkrange", {
  correct_func = function(self, from, to)
    if H.hasHegLordSkill(Fk:currentRoom(), from, "shouyue") then
      return 1
    end
  end,
})

liegong:addEffect("targetmod",{
  bypass_distances = function (self, player, skill, card, to)
    if player:hasSkill(liegong.name) and card and card.trueName == "slash" then
      return to:getHandcardNum() <= player:getHandcardNum()
    end
  end,
  target_tip_func = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if player:hasSkill(liegong.name) and card and card.trueName == "slash" and selectable then
      if to_select.hp >= player.hp then
        return {{ content = "hs__liegong_can", type = "normal" }}
      end
    end
  end,
})

return liegong
