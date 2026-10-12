local osSuizheng = fk.CreateSkill {
  name = "os__suizheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__suizheng"] = "随征",
  [":os__suizheng"] = "锁定技，游戏开始时，你选择一名其他角色。当其造成伤害后，你摸一张牌；当其受到伤害后，你须选择一项：" ..
  "1.失去1点体力，令其从牌堆或弃牌堆中获得一张【杀】或【决斗】；2.弃置两张基本牌，令其回复1点体力。",

  ["#os__suizheng-ask"] = "随征：选择一名其他角色，作为“随征”角色",
  ["@os__suizheng"] = "随征",
  ["#os__suizheng-discard"] = "随征：弃置两张基本牌令 %dest 回复1点体力；或点“取消”失去1点体力，令其获得一张【杀】或【决斗】",

  ["$os__suizheng1"] = "续得将军器重，愿随将军出征！",
  ["$os__suizheng2"] = "吾与将军有亲，哼！尔等岂可与我相比！",
  ["$os__suizheng3"] = "将军莫慌，万事有吾！",
}

osSuizheng:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osSuizheng.name)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osSuizheng.name
    local room = player.room
    player:broadcastSkillInvoke(skillName, 1)
    room:notifySkillInvoked(player, skillName, "support")
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#os__suizheng-ask",
      skill_name = skillName,
      cancelable = false,
    })[1]
    if to then
      room:setPlayerMark(player, "_os__suizheng", to.id)
      room:setPlayerMark(player, "@os__suizheng", to.general)
    end
  end,
})

osSuizheng:addEffect(fk.Damage, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target and player:getMark("_os__suizheng") == target.id and player:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osSuizheng.name
    local room = player.room
    player:broadcastSkillInvoke(skillName, 2)
    room:notifySkillInvoked(player, skillName, "drawcard")
    player:drawCards(1, skillName)
  end,
})

osSuizheng:addEffect(fk.Damaged, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("_os__suizheng") == target.id and player:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osSuizheng.name
    local room = player.room
    player:broadcastSkillInvoke(skillName, 3)
    room:notifySkillInvoked(player, skillName, "support")
    local cards = room:askToDiscard(
      player,
      {
        min_num = 2,
        max_num = 2,
        skill_name = skillName,
        pattern = ".|.|.|.|.|basic",
        prompt = "#os__suizheng-discard::" .. target.id,
      }
    )
    if #cards == 2 then
      if target:isAlive() then
        room:recover{ who = target, num = 1, recoverBy = player, skillName = skillName }
      end
    else
      room:loseHp(player, 1, skillName)
      if target:isAlive() then
        local cids = room:getCardsFromPileByRule("slash,duel", 1, "allPiles")
        if #cids > 0 then
          room:obtainCard(target, cids[1], false, fk.ReasonPrey, target, skillName)
        end
      end
    end
  end,
})

return osSuizheng
