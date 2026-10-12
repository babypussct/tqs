local pingcai = fk.CreateSkill {
  name = "pingcai",
}

Fk:loadTranslationTable{
  ["pingcai"] = "评才",
  [":pingcai"] = "出牌阶段限一次，你可以挑选一个宝物，擦拭掉上面的灰尘。如果擦拭成功，你可以根据宝物类型执行对应的效果：<br>"..
  "卧龙：对一名角色造成1点火焰伤害。若场上有存活的卧龙诸葛亮，则改为对至多两名角色各造成1点火焰伤害。<br>"..
  "凤雏：横置至多三名角色的武将牌。若场上有存活的庞统，则改为横置至多四名角色的武将牌。<br>"..
  "水镜：移动场上的一张防具牌。若场上有存活的司马徽，则改为移动场上的一张装备牌。<br>"..
  "玄剑：令一名角色摸一张牌并回复1点体力。若场上有存活的徐庶，则改为令一名角色摸一张牌并回复1点体力，然后你摸一张牌。",

  ["#pingcai"] = "评才：选择一个宝物擦拭灰尘！",
  ["pingcai_success"] = "擦拭成功！",
  ["pingcai_fail"] = "擦拭失败！",
  ["pingcai_wolong"] = "卧龙",
  ["pingcai_pangtong"] = "凤雏",
  ["pingcai_simahui"] = "水镜",
  ["pingcai_xushu"] = "玄剑",
  ["#pingcai_wolong"] = "卧龙：对至多%arg名角色造成1点火焰伤害",
  ["#pingcai_pangtong"] = "凤雏：横置至多%arg名角色的武将牌",
  ["#pingcai_simahui"] = "水镜：移动场上的一张%arg",
  ["#pingcai_xushu"] = "玄剑：令一名角色摸一张牌并回复1点体力",

  ["$pingcai1"] = "吾有众好友，分为卧龙、凤雏、水镜、元直。",
  ["$pingcai2"] = "孔明能借天火之势。",
  ["$pingcai3"] = "士元虑事环环相扣。",
  ["$pingcai4"] = "德操深谙处世之道。",
  ["$pingcai5"] = "元直侠客惩恶扬善。",
}

pingcai:addEffect("active", {
  mute = true,
  card_num = 0,
  target_num = 0,
  prompt = "#pingcai",
  interaction = UI.ComboBox {choices = {"pingcai_wolong", "pingcai_pangtong", "pingcai_simahui", "pingcai_xushu"}},
  can_use = function(self, player)
    return player:usedSkillTimes(pingcai.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:notifySkillInvoked(player, pingcai.name, "control")
    player:broadcastSkillInvoke(pingcai.name, 1)
    if math.random() < 0.03 then  --看看哪个倒霉蛋失败
      room:doBroadcastNotify("ShowToast", Fk:translate("pingcai_fail"))
      return
    end
    room:doBroadcastNotify("ShowToast", Fk:translate("pingcai_success"))
    if self.interaction.data == "pingcai_wolong" then
      local n = table.find(room.alive_players, function(p)
        return string.find(p.general, "wolong") ~= nil or string.find(p.deputyGeneral, "wolong") ~= nil
      end) and 2 or 1
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = n,
        targets = room.alive_players,
        skill_name = pingcai.name,
        prompt = "#pingcai_wolong:::"..n,
        cancelable = false,
      })
      room:sortByAction(tos)
      player:broadcastSkillInvoke(pingcai.name, 2)
      for _, p in ipairs(tos) do
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = pingcai.name,
          }
        end
      end
    elseif self.interaction.data == "pingcai_pangtong" then
      local n = table.find(room.alive_players, function(p)
        return p.general:endsWith("pangtong") or p.deputyGeneral:endsWith("pangtong") or
          p.general == "wolongfengchu" or p.deputyGeneral == "wolongfengchu"
      end) and 4 or 3
      local targets = table.filter(room.alive_players, function(p)
        return not p.chained
      end)
      if #targets == 0 then return end
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = n,
        targets = targets,
        skill_name = pingcai.name,
        prompt = "#pingcai_pangtong:::"..n,
        cancelable = false,
      })
      room:sortByAction(tos)
      player:broadcastSkillInvoke(pingcai.name, 3)
      for _, p in ipairs(tos) do
        if not p.dead and not p.chained then
          p:setChainState(true)
        end
      end
    elseif self.interaction.data == "pingcai_simahui" then
      local pattern = "armor"
      if table.find(room.alive_players, function(p)
        return p.general:endsWith("simahui") or p.deputyGeneral:endsWith("simahui")
      end) then
        pattern = "equip"
      end
      local excludeIds = {}
      if pattern == "armor" then
        for _, p in ipairs(room.alive_players) do
          for _, id in ipairs(p:getCardIds("e")) do
            if Fk:getCardById(id).sub_type ~= Card.SubtypeArmor then
              table.insert(excludeIds, id)
            end
          end
        end
      end
      local targets = room:askToChooseToMoveCardInBoard(player, {
        prompt = "#pingcai_simahui:::"..pattern,
        skill_name = pingcai.name,
        no_indicate = true,
        flag = "e",
        cancelable = false,
        exclude_ids = excludeIds,
      })
      if #targets == 0 then return end
      player:broadcastSkillInvoke(pingcai.name, 4)
      room:askToMoveCardInBoard(player, {
        target_one = targets[1],
        target_two = targets[2],
        skill_name = pingcai.name,
        exclude_ids = excludeIds,
      })
    elseif self.interaction.data == "pingcai_xushu" then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room.alive_players,
        skill_name = pingcai.name,
        prompt = "#pingcai_xushu",
        cancelable = false,
      })
      player:broadcastSkillInvoke(pingcai.name, 5)
      to = to[1]
      to:drawCards(1, pingcai.name)
      if not to.dead and to:isWounded() then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = pingcai.name,
        }
      end
      if not player.dead and
        table.find(room.alive_players, function(p)
          return p.general:endsWith("xushu") or p.deputyGeneral:endsWith("xushu")
        end) then
        player:drawCards(1, pingcai.name)
      end
    end
  end,
})

return pingcai
