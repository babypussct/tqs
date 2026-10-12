local zhengbi = fk.CreateSkill{
  name = "ld__zhengbi",
}
local H = require "packages.hegemony.util"
zhengbi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
      and (table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id).type == Card.TypeBasic end)
      or table.every(player.room:getOtherPlayers(player, false), function(p) return H.getGeneralsRevealedNum(p) == 0 end))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local basic_cards1 = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).type == Card.TypeBasic end)
    local targets1 = table.filter(room:getOtherPlayers(player, false), function(p)
      return H.getGeneralsRevealedNum(p) > 0 end)
    local targets2 = table.filter(room:getOtherPlayers(player, false), function(p)
      return H.getGeneralsRevealedNum(p) == 0 end)
    if #basic_cards1 > 0 and #targets1 > 0 then
      table.insert(choices, "zhengbi_giveCard")
    end
    if #targets2 > 0 then
      table.insert(choices, "zhengbi_useCard")
    end
    if #choices == 0 then return false end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zhengbi.name,
    })
    if choice:startsWith("zhengbi_giveCard") then
      local tos, card = room:askToChooseCardsAndPlayers(player, {
        targets = targets1, min_num = 1, max_num = 1,
        min_card_num = 1, max_card_num = 1, pattern = ".|.|.|.|.|basic",
        propmt = "#ld__zhengbi-give", skill_name = zhengbi.name, cancelable = false
      })
      local to = tos[1]
      room:obtainCard(to, card, false, fk.ReasonGive)
      if to.dead or to:isNude() then return end
      local cards2 = to:getCardIds("he")
      if #cards2 > 1 then
        local card_choices = {}
        local num = #table.filter(to:getCardIds("h"), function(id)
          return Fk:getCardById(id).type == Card.TypeBasic end)
        if num > 1 then
          table.insert(card_choices, "zhengbi_basic-back:"..player.id)
        end
        if #to:getCardIds("he") - num > 0 then
          table.insert(card_choices, "zhengbi_nobasic-back:"..player.id)
        end
        if #card_choices == 0 then return false end
        local card_choice = room:askToChoice(to, {
          choices = card_choices,
          skill_name = zhengbi.name
        })
        if card_choice:startsWith("zhengbi_basic-back") then
          cards2 = room:askToCards(to, {
            min_num = 2,
            max_num = 2,
            include_equip = false,
            skill_name = zhengbi.name,
            pattern = ".|.|.|.|.|basic",
            prompt = "#ld__zhengbi-give1:"..player.id,
            cancelable = false,
          })
        elseif card_choice:startsWith("zhengbi_nobasic-back") then
          cards2 = room:askToCards(to, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = zhengbi.name,
            pattern = ".|.|.|.|.|^basic",
            prompt = "#ld__zhengbi-give2:"..player.id,
            cancelable = false,
          })
        end
      end
      room:moveCardTo(cards2, Player.Hand, player, fk.ReasonGive, zhengbi.name, nil, false, player)
    elseif choice:startsWith("zhengbi_useCard") then
      local to = room:askToChoosePlayers(player, {
        targets = targets2,
        min_num = 1,
        max_num = 1,
        prompt = "#ld__zhengbi_choose",
        skill_name = zhengbi.name,
        cancelable = false,
      })[1]
      room:setPlayerMark(to, "@@ld__zhengbi_choose-turn", 1)
    end
  end,
})
zhengbi:addEffect(fk.GeneralRevealed, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target:getMark("@@ld__zhengbi_choose-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@ld__zhengbi_choose-turn", 0)
  end,
})

zhengbi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and player:hasSkill(self.name) and to:getMark("@@ld__zhengbi_choose-turn") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card and to and player:hasSkill(self.name) and to:getMark("@@ld__zhengbi_choose-turn") > 0
  end,
})

Fk:loadTranslationTable{
  ["ld__zhengbi"] = "征辟",
  [":ld__zhengbi"] = "出牌阶段开始时，你可选择一项：1.选择一名没有势力的角色，直至其确定势力或此回合结束，你对其使用牌无距离与次数限制；"..
  "2.将一张基本牌交给一名已确定势力的角色，然后其交给你一张非基本牌或两张基本牌。",

  ["zhengbi_giveCard"] = "交给有势力角色基本牌",
  ["zhengbi_useCard"] = "选择无势力角色用牌无限制",

  ["#ld__zhengbi-give"] = "请选择一张基本牌，交给一名有势力的角色",
  ["zhengbi_basic-back"] = "交给%src两张基本牌",
  ["zhengbi_nobasic-back"] = "交给%src一张非基本牌",

  ["#ld__zhengbi-give1"] = "征辟：请交给%src两张基本牌",
  ["#ld__zhengbi-give2"] = "征辟：请交给%src一张非基本牌",

  ["#ld__zhengbi_choose"] = "征辟：请选择一名未确定势力的角色，你对其使用牌无距离与次数限制",
  ["@@ld__zhengbi_choose-turn"] = "征辟",

  ["$ld__zhengbi1"] = "跅弛之士，在御之而已。",
  ["$ld__zhengbi2"] = "内不避亲，外不避仇。",
}

return zhengbi
