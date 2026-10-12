local kuangwu = fk.CreateSkill {
  name = "kuangwu",
}

Fk:loadTranslationTable{
  ["kuangwu"] = "诳武",
  [":kuangwu"] = "其他角色的出牌阶段开始时，你可以将手牌摸或弃至与其手牌数相同（至多摸至五张、弃至一张），然后视为对其使用一张【决斗】。"..
  "此【决斗】结算结束后，若其未因此牌受到伤害，则你失去1点体力且〖诳武〗失效直到本轮结束。",

  ["#kuangwu-draw"] = "诳武：你可以将手牌摸至%arg，视为对 %dest 使用【决斗】",
  ["#kuangwu-discard"] = "诳武：你可以弃置%arg张手牌，视为对 %dest 使用【决斗】",

  ["$kuangwu1"] = "呔！可听过我零陵上将的名号？",
  ["$kuangwu2"] = "还敢夸口，待吾取汝狗头！",
  ["$kuangwu3"] = "小的知错！求军师放我一条生路哇！",
  ["$kuangwu4"] = "哎哟！将军，可否解气？",
}

kuangwu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  audio_index = {1, 2},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kuangwu.name) and target ~= player and target.phase == Player.Play and
      not target.dead and (player:getHandcardNum() < math.min(target:getHandcardNum(), 5) or
      player:getHandcardNum() > math.max(target:getHandcardNum(), 1))
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local n = math.min(target:getHandcardNum(), 5)
    if player:getHandcardNum() > n then
      n = player:getHandcardNum() - math.max(target:getHandcardNum(), 1)
      local cards = room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = kuangwu.name,
        prompt = "#kuangwu-discard::"..target.id..":"..n,
        cancelable = true,
        skip = true,
      })
      if #cards > 0 then
        event:setCostData(self, {tos = {target}, cards = cards})
        return true
      end
    else
      if room:askToSkillInvoke(player, {
        skill_name = kuangwu.name,
        prompt = "#kuangwu-draw::"..target.id..":"..n,
      }) then
        event:setCostData(self, {tos = {target}})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards or {}
    if #cards > 0 then
      room:throwCard(cards, kuangwu.name, player, player)
    else
      player:drawCards(math.min(target:getHandcardNum(), 5) - player:getHandcardNum(), kuangwu.name)
    end
    if player.dead or target.dead then return end
    local use = room:useVirtualCard("duel", nil, player, target, kuangwu.name)
    if use and not (use.damageDealt and use.damageDealt[target]) and not player.dead then
      player:broadcastSkillInvoke(kuangwu.name, room:tableRandomPick({3, 4}))
      room:loseHp(player, 1, kuangwu.name)
      if not player.dead then
        room:invalidateSkill(player, kuangwu.name, "-round", kuangwu.name)
      end
    end
  end,
})

return kuangwu
