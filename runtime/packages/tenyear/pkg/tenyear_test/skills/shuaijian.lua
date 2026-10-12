
local shuaijian = fk.CreateSkill {
  name = "shuaijian",
}

Fk:loadTranslationTable{
  ["shuaijian"] = "率俭",
  [":shuaijian"] = "你的回合开始时和结束时，你可以选择一项执行："..
  "1.令手牌数最多的一名角色将手牌弃置至不为全场最多，然后你令一名角色摸弃牌数张牌；"..
  "2.令装备区牌数最多的一名角色将装备区牌弃置至不为全场最多，然后你令一名角色回复弃牌数点体力。",

  ["#shuaijian-invoke"] = "率俭：你可以选择一项执行",
  ["shuaijian_hand"] = "令手牌数最多的角色弃牌",
  ["shuaijian_equip"] = "令装备数最多的角色弃装备",
  ["#shuaijian-hand"] = "率俭：请弃置%arg张手牌",
  ["#shuaijian-equip"] = "率俭：请弃置%arg张装备",
  ["#shuaijian-draw"] = "率俭：令一名角色摸%arg张牌",
  ["#shuaijian-recover"] = "率俭：令一名角色回复%arg点体力",

  ["$shuaijian1"] = "",
  ["$shuaijian2"] = "",
}

shuaijian:addAuxActiveSkill("#shuaijian_active", {
  card_num = 0,
  target_num = 1,
  interaction = UI.ComboBox { choices = { "shuaijian_hand", "shuaijian_equip" } },
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected)
    if #selected == 0 then
      if self.interaction.data == "shuaijian_hand" then
        return not to_select:isKongcheng() and
          table.every(Fk:currentRoom().alive_players, function (p)
            return to_select:getHandcardNum() >= p:getHandcardNum()
          end)
      else
        return #to_select:getCardIds("e") > 0 and
          table.every(Fk:currentRoom().alive_players, function (p)
            return #to_select:getCardIds("e") >= #p:getCardIds("e")
          end)
      end
    end
  end,
})

local spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shuaijian.name) and
      table.find(player.room.alive_players, function (p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#shuaijian_active",
      prompt = "#shuaijian-invoke",
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets, choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    if choice == "shuaijian_hand" then
      local n = 0
      for _, p in ipairs(room:getOtherPlayers(to)) do
        n = math.max(n, p:getHandcardNum())
      end
      if n == to:getHandcardNum() then
        n = 1
      else
        n = to:getHandcardNum() - n
      end
      local cards = room:askToDiscard(to, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = shuaijian.name,
        prompt = "#shuaijian-hand:::"..n,
        cancelable = false,
      })
      if #cards > 0 and not player.dead then
        to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = room.alive_players,
          skill_name = shuaijian.name,
          prompt = "#shuaijian-draw:::"..n,
          cancelable = false,
        })[1]
        to:drawCards(#cards, shuaijian.name)
      end
    else
      local n = 0
      for _, p in ipairs(room:getOtherPlayers(to)) do
        n = math.max(n, #p:getCardIds("e"))
      end
      if n == #to:getCardIds("e") then
        n = 1
      else
        n = #to:getCardIds("e") - n
      end
      local cards = room:askToDiscard(to, {
        min_num = n,
        max_num = n,
        include_equip = true,
        pattern = tostring(Exppattern{ id = to:getCardIds("e") }),
        skill_name = shuaijian.name,
        prompt = "#shuaijian-equip:::" .. n,
        cancelable = false,
      })
      if #cards > 0 and not player.dead then
        local targets = table.filter(room:getOtherPlayers(player, false), function(p)
          return p:isWounded()
        end)
        to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = shuaijian.name,
          prompt = "#shuaijian-recover:::"..n,
          cancelable = false,
        })[1]
        room:recover{
          who = to,
          num = n,
          recoverBy = player,
          skillName = shuaijian.name,
        }
      end
    end
  end,
}
shuaijian:addEffect(fk.TurnStart, spec)
shuaijian:addEffect(fk.TurnEnd, spec)

return shuaijian
