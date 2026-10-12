local pozhu = fk.CreateSkill {
  name = "heg__pozhu",
  tags = { Skill.MainPlace },
}

Fk:loadTranslationTable{
  ["heg__pozhu"] = "破竹",
  [":heg__pozhu"] = "主将技，你计算体力上限时减少1个单独的阴阳鱼。准备阶段，你可以将一张牌当【杀】使用，"..
    "结算后你展示唯一目标一张手牌，若两张牌花色不同，你可以重复此流程。",

  ["#heg__pozhu-invoke"] = "你可发动 破竹，将一张牌当【杀】使用，<br>" ..
    "结算后你展示唯一目标一张手牌，若两张牌花色不同，你可以重复此流程。",
  ["#heg__pozhu-show"] = "破竹：展示 %dest 的一张手牌",

  ["$heg__pozhu1"] = "攻其不备，摧枯拉朽！",
  ["$heg__pozhu2"] = "势如破竹，铁锁横江亦难挡！",
}

pozhu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
      and not player:isNude() and player:canUse(Fk:cloneCard("slash"), { bypass_times = true })
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = self.name,
      prompt = "#heg__pozhu-invoke",
      extra_data = {bypass_times = true, extraUse = true},
      cancelable = true,
      card_filter = {n = 1},
      skip = true,
    })
    if use then
      event:setCostData(self, {use = use})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local use = event:getCostData(self).use
    local room = player.room
    while true do
      if use == nil then break end
      use.extra_data = use.extra_data or {}
      use.extra_data.heg__pozhuUser = player.id
      room:useCard(use)
      use = nil
      local u = room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        return (e.data.extra_data or {}).heg__pozhuUser == player.id
      end, nil, Player.HistoryPhase)
      if #u == 0 then return end
      local useEvent = u[1].data
      if #useEvent.tos == 1 then
        target = useEvent.tos[1]
        if not target:isKongcheng() and target:isAlive() then
          local card = room:askToChooseCard(player, {
            target = target,
            flag = "h",
            skill_name = self.name,
            propmt = "#heg__pozhu-show",
          })
          target:showCards(card)
          if Fk:getCardById(card):compareSuitWith(useEvent.card, true) and player:isAlive() then
            use = room:askToUseVirtualCard(player, {
              name = "slash",
              skill_name = self.name,
              prompt = "#heg__pozhu-invoke",
              extra_data = {bypass_times = true, extraUse = true, heg__pozhuUser = player.id},
              cancelable = true,
              card_filter = {n = 1},
              skip = true,
            })
          end
        end
      end
    end
  end
})

return pozhu
