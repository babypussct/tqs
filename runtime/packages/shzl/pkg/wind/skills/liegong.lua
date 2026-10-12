local liegong = fk.CreateSkill({
  name = "liegong",
})

Fk:loadTranslationTable{
  ["liegong"] = "烈弓",
  [":liegong"] = "当你于出牌阶段内使用【杀】指定一个目标后，若其手牌数不小于你的体力值或不大于你的攻击范围，则你可以令其不能使用【闪】响应此【杀】。",

  ["#liegong-invoke"] = "烈弓：是否令 %dest 不可响应此【杀】？",
  ["can_liegong"] = "可烈弓",

  ["$liegong1"] = "百步穿杨！",
  ["$liegong2"] = "中！",
}

liegong:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liegong.name) and
      data.card.trueName == "slash" and player.phase == Player.Play and
      (data.to:getHandcardNum() <= player:getAttackRange() or data.to:getHandcardNum() >= player.hp)
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = liegong.name,
      prompt = "#liegong-invoke::"..data.to.id,
    }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:setDisresponsive(data.to)
  end,
})

liegong:addEffect("targetmod",{
  target_tip_func = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if player:hasSkill(liegong.name) and card and card.trueName == "slash" and selectable then
      if to_select:getHandcardNum() <= player:getAttackRange() or to_select:getHandcardNum() >= player.hp then
        return {{ content = "can_liegong", type = "normal" }}
      end
    end
  end,
})

liegong:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    local target = ai.room:getPlayerById(tonumber(string.split(ai.data[2], ":")[3]))
    return target:isEnemy(ai.player)
  end,
})

return liegong
