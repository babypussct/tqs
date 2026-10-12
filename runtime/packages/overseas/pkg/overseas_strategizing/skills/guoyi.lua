local guoyi = fk.CreateSkill {
  name = "os__guoyi",
}

Fk:loadTranslationTable{
  ["os__guoyi"] = "果毅",
  [":os__guoyi"] = "当你使用【杀】或普通锦囊牌指定仅一名其他角色为目标后，若其体力值或手牌数为全场最高，" ..
  "或你的手牌数不大于X（X为你已损失体力值+1），你可以令其选择一项：1.本回合不能使用或打出手牌；2.弃置X张牌。" ..
  "若条件均满足，或其本回合两个选项均已选择，则此牌结算两次。",

  ["#os__guoyi-ask"] = "果毅：是否对 %dest 发动“果毅”？",
  ["os__guoyi_prohibit"] = "本回合不能使用或打出手牌",
  ["os__guoyi_discard"] = "弃置%arg张牌",
  ["os__guoyi-ask"] = "果毅：%src 对你发动“果毅”，请选择一项",
  ["@@os__guoyi_prohibit-turn"] = "禁用手牌",

  ["$os__guoyi1"] = "心怀远志，何愁声名不彰！",
  ["$os__guoyi2"] = "从今始学，成为有用之才！",
}

local function isHandOrHpBiggest(player, room)
  local num = player.hp
  if table.every(room.alive_players, function(p) return p.hp <= num end) then
    return true
  end
  num = player:getHandcardNum()
  if table.every(room.alive_players, function(p) return p:getHandcardNum() <= num end) then
    return true
  end
  return false
end

guoyi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(guoyi.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      data.to ~= player and data:isOnlyTarget(data.to) then
      return (player:getHandcardNum() <= player:getLostHp() + 1) or isHandOrHpBiggest(data.to, player.room)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = guoyi.name,
      prompt = "#os__guoyi-ask::" .. data.to.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = player:getLostHp() + 1
    local ret = isHandOrHpBiggest(data.to, room) and player:getHandcardNum() <= player:getLostHp() + 1
    local all_choices = {"os__guoyi_prohibit", "os__guoyi_discard:::" .. num}
    local choices = table.clone(all_choices)
    if data.to:isNude() then
      table.remove(choices)
    end
    local mark = data.to:getTableMark("_os__guoyi-turn")
    if table.contains(mark, 1) then
      table.remove(choices, 1)
    end
    if #choices > 0 then
      local choice = table.indexOf(all_choices, room:askToChoice(data.to, {
        choices = choices,
        skill_name = guoyi.name,
        prompt = "os__guoyi-ask:" .. player.id,
        all_choices = all_choices
      }))
      table.insertIfNeed(mark, choice)
      room:setPlayerMark(data.to, "_os__guoyi-turn", mark)
      if choice == 1 then
        room:addPlayerMark(data.to, "@@os__guoyi_prohibit-turn")
      else
        room:askToDiscard(data.to, {
          min_num = num,
          max_num = num,
          include_equip = true,
          skill_name = guoyi.name,
          cancelable = false,
        })
      end
    end
    if ret or #mark == 2 then
      data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
    end
  end,
})

guoyi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("@@os__guoyi_prohibit-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@os__guoyi_prohibit-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
})

return guoyi
