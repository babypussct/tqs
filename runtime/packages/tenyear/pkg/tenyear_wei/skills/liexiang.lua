local liexiang = fk.CreateSkill{
  name = "liexiang",
  dynamic_desc = function (self, player, lang)
    if player:getMark("liexiang-turn") > 0 then
      return "liexiang_inner:"..player:getMark("liexiang-turn")
    end
  end
}

Fk:loadTranslationTable {
  ["liexiang"] = "烈骧",
  [":liexiang"] = "出牌阶段限一次，你可以摸至多5张牌并对一名其他角色造成1点伤害，若你的手牌：<br>"..
  "大于其，本回合你出【杀】次数+1且可交给一名其他角色至多X张牌；<br>"..
  "等于其，你获得其一张牌且其下回合使用的前X张牌无效；<br>"..
  "小于其，你失去X点体力，本回合此技能改为“出牌阶段限两次”且可选目标数+X。<br>"..
  "（X为你选择的摸牌数）",

  [":liexiang_inner"] = "出牌阶段限两次，你可以摸至多5张牌并对{1}名其他角色各造成1点伤害，若你的手牌：<br>"..
  "大于其，本回合你出【杀】次数+1且可交给一名其他角色至多X张牌；<br>"..
  "等于其，你获得其一张牌且其下回合使用的前X张牌无效；<br>"..
  "小于其，你失去X点体力，本回合此技能可选目标数+X。<br>"..
  "（X为你选择的摸牌数）",

  ["#liexiang"] = "烈骧：摸至多%arg张牌，选择角色，根据你与其手牌数大小关系执行效果",
  ["#liexiang-choose"] = "烈骧：选择至多%arg名角色，根据你与其手牌数大小关系执行效果",
  ["#liexiang-give"] = "烈骧：你可以交给一名其他角色至多 %arg 张牌",
  ["#liexiang-prey"] = "烈骧：获得 %dest 一张牌",
  ["@liexiang_buff-turn"] = "烈骧无效",
  ["liexiang_bigger"] = "你可多出杀",
  ["liexiang_equal"] = "你获得其牌",
  ["liexiang_smaller"] = "你失去体力",

  ["$liexiang1"] = "二十四世王业在背，朕岂与汉贼两立！",
  ["$liexiang2"] = "效光武，清河洛，为苍生开太平！",
}

Fk:addTargetTip{
  name = liexiang.name,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable)
    if not selectable then return end
    if player:getHandcardNum() > to_select:getHandcardNum() then
      return "liexiang_bigger"
    elseif player:getHandcardNum() == to_select:getHandcardNum() then
      return "liexiang_equal"
    else
      return { { content = "liexiang_smaller", type = "warning" } }
    end
  end,
}

liexiang:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#liexiang:::" .. 5
  end,
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    local max = player:getMark("rengou-tmp") > 0 and 2 or 5
    return UI.Spin {
      from = 1,
      to = max,
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(liexiang.name, Player.HistoryPhase) < 1 + (player:getMark("liexiang-turn") > 0 and 1 or 0)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local x = self.interaction.data
    player:drawCards(x, liexiang.name)
    if player.dead or #room:getOtherPlayers(player, false) == 0 then return end
    local n = (player:getMark("rengou-tmp") > 0 and 0 or player:getMark("liexiang-turn")) + 1
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = n,
      targets = room:getOtherPlayers(player, false),
      skill_name = liexiang.name,
      prompt = "#liexiang-choose:::"..n,
      cancelable = false,
      target_tip_name = liexiang.name,
    })
    for _, p in ipairs(tos) do
      if player.dead then return end
      room:damage {
        from = player,
        to = p,
        damage = 1,
        skillName = liexiang.name,
      }
      if p.dead then
        goto continue
      end

      if player:getHandcardNum() > p:getHandcardNum() then
        room:addPlayerMark(player, MarkEnum.SlashResidue .. "-turn", 1)
        local players, cards, ok = room:askToChooseCardsAndPlayers(player, {
          targets = room:getOtherPlayers(player),
          skill_name = liexiang.name,
          min_num = 1,
          max_num = 1,
          min_card_num = 1,
          max_card_num = x,
          cancelable = true,
          prompt = "#liexiang-give:::" .. x,
        })
        if ok then
          local to = players[1]
          room:obtainCard(to, cards, false, fk.ReasonGive, player, liexiang.name)
        end
      elseif player:getHandcardNum() == p:getHandcardNum() then
        if not p:isNude() then
          local card = room:askToChooseCard(player, {
            target = p,
            flag = "he",
            skill_name = liexiang.name,
            prompt = "#liexiang-prey::"..p.id,
          })
          room:obtainCard(player, card, false, fk.ReasonPrey, player, liexiang.name)
        end
        room:addPlayerMark(p, "liexiang_buff", x)
      else
        room:loseHp(player, x, liexiang.name, player)
        if player.dead then return end
        if player:getMark("rengou-tmp") == 0 then
          room:setPlayerMark(player, "liexiang-turn", x)
        end
      end
      ::continue::
    end
  end,
})

liexiang:addEffect(fk.TurnStart, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("liexiang_buff") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@liexiang_buff-turn", player:getMark("liexiang_buff"))
    room:setPlayerMark(player, "liexiang_buff", 0)
  end,
})


liexiang:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@liexiang_buff-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@liexiang_buff-turn", 1)
    --data.toCard = nil
    --data:removeAllTargets()
    data:setNullified()
  end,
})

return liexiang
