local skill = fk.CreateSkill{
  name = "#sa__halberd_skill",
  attached_equip = "sa__halberd",
}

local H = require "packages.hegemony.util"

skill:addAuxActiveSkill("#sa__halberd_active", {
  can_use = Util.FalseFunc,
  min_target_num = 1,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local orig_tos = self.orig_tos
    local targets = self.targets
    local room = Fk:currentRoom()
    return table.contains(targets, to_select.id) and
      (to_select.kingdom == "unknown" or
      (table.every(orig_tos, function(id)
        return not H.compareKingdomWith(to_select, room:getPlayerById(id))
      end) and table.every(selected, function(p)
        return not H.compareKingdomWith(to_select, p)
      end)))
  end,
})

skill:addEffect(fk.AfterCardTargetDeclared, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card.trueName == "slash" and #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local _, ret = room:askToUseActiveSkill(player, {
      skill_name = "#sa__halberd_active",
      prompt = "#sa__halberd-ask",
      extra_data = {
        orig_tos = table.map(data.tos, Util.IdMapper),
        targets = table.map(data:getExtraTargets(), Util.IdMapper)
      }
    })
    if ret then
      event:setCostData(self, { tos = ret.targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/standard_cards/audio/card/halberd")
    room:setEmotion(player, "./packages/standard_cards/image/anim/halberd")
    data:addTarget(event:getCostData(self).tos)
    data.extra_data = data.extra_data or {}
    data.extra_data.saHalberd = true
  end
})

skill:addEffect(fk.CardEffectCancelledOut, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and
      (player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard).data.extra_data or {}).saHalberd
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    local use = e.data
    if #use.tos > 0 then
      use:setNullified(data.tos)
    end
  end,
})

Fk:loadTranslationTable{
  ["sa__halberd"] = "方天画戟",
  [":sa__halberd"] = "装备牌·武器<br/><b>攻击范围</b>：4<br /><b>武器技能</b>：当你使用【杀】选择目标后，"..
  "可以令任意名势力各不相同、且与已选择的目标势力均不相同的角色和任意名没有势力的角色也成为目标，当此【杀】被【闪】抵消后，此【杀】对所有目标均无效。",
  ["#sa__halberd_skill"] = "方天画戟",
  ["#sa__halberd-ask"] = "方天画戟：令任意名势力各不相同且与已选择的目标势力均不相同的角色和任意名没有势力的角色也成为目标",
}

return skill
