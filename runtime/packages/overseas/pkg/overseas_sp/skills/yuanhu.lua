local osYuanhu = fk.CreateSkill {
  name = "os__yuanhu"
}

Fk:loadTranslationTable{
  ["os__yuanhu"] = "援护",
  [":os__yuanhu"] = "出牌阶段限一次，你可以将一张装备牌置入一名角色的装备区，若此牌是：武器牌，你弃置其距离不大于1的一名角色区域里的一张牌；" ..
  "防具牌，其摸一张牌；坐骑牌或宝物牌，其回复1点体力。若其体力值或手牌数不大于你且此时为你的出牌阶段，你摸一张牌，且可以于本回合结束阶段再发动此技能。",

  ["#os__yuanhu"] = "援护:将一张装备牌置入一名角色的装备区",
  ["#os__yuanhu-discard"] = "援护：你可以弃置 %src 距离不大于1的一名角色区域内一张牌",
  ["#os__yuanhu-trg"] = "援护：你可以将一张装备牌置入一名角色的装备区",

  ["$os__yuanhu1"] = "刀剑无眼，须得小心防护。",
  ["$os__yuanhu2"] = "宝马配英雄！哈哈哈哈……",
  ["$os__yuanhu3"] = "将军，这件兵器可还趁手？",
}

osYuanhu:addEffect("active", {
  anim_type = "support",
  prompt = "#os__yuanhu",
  times = function (self, player)
    return 1 - player:usedEffectTimes(self.name, Player.HistoryPhase)
  end,
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and #selected_cards == 1 and to_select:hasEmptyEquipSlot(Fk:getCardById(selected_cards[1]).sub_type)
  end,
  on_use = function(self, room, use)
    ---@type string
    local skillName = osYuanhu.name
    if #use.cards ~= 1 then return end
    local player = use.from
    local target = use.tos[1]
    room:moveCardTo(use.cards, Card.PlayerEquip, target, fk.ReasonPut, skillName, nil, true, player)
    if target:isAlive() then
      local cardType = Fk:getCardById(use.cards[1]).sub_type
      if cardType == Card.SubtypeWeapon then
        local targets = table.filter(room.alive_players, function(p)
          return target:distanceTo(p) <= 1 and not p:isAllNude()
        end)
        if #targets > 0 then
          local to = room:askToChoosePlayers(
            player,
            {
              targets = targets,
              min_num = 1,
              max_num = 1,
              prompt = "#os__yuanhu-discard:" .. target.id,
              skill_name = skillName,
              cancelable = false,
            }
          )[1]
          local cid = room:askToChooseCard(
            player,
            {
              target = to,
              flag = "hej",
              skill_name = skillName,
            }
          )
          room:throwCard(cid, skillName, to, player)
        end
      elseif cardType == Card.SubtypeArmor then
        target:drawCards(1, skillName)
      else
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = skillName,
        }
      end
      if
        player.phase == Player.Play and
        (target.hp <= player.hp or target:getHandcardNum() <= player:getHandcardNum()) and
        player:isAlive()
      then
        player:drawCards(1, skillName)
        room:setPlayerMark(player, "_os__yuanhu-turn", 1)
      end
    end
  end,
})

osYuanhu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osYuanhu.name) and
      player.phase == Player.Finish and
      player:getMark("_os__yuanhu-turn") > 0
  end,
  on_cost = function(self, event, target, player, data)
    player.room:askToUseActiveSkill(
      player,
      {
        skill_name = osYuanhu.name,
        prompt = "#os__yuanhu-trg",
      }
    )
  end,
  on_use = Util.FalseFunc,
})

return osYuanhu
