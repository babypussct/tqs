
local zhangwu = fk.CreateSkill {
  name = "m_heg__zhangwu",
}

Fk:loadTranslationTable{
  ["m_heg__zhangwu"] = "章武",
  [":m_heg__zhangwu"] = "每回合的结束阶段，你可以视为使用一个本回合同势力角色使用过的国战标记。",

  ["#m_heg__zhangwu-invoke"] = "章武：你可以视为使用一个国战标记",
  ["#m_heg__zhangwu-vanguard"] = "章武：视为使用“先驱”，将手牌摸至四张并观看一张暗置武将牌",
  ["#m_heg__zhangwu-yinyangfish"] = "章武：视为使用“阴阳鱼”，摸一张牌或本回合手牌上限+2",
  ["#m_heg__zhangwu-companion"] = "章武：视为使用“珠联璧合”，摸两张牌或视为使用【桃】",
  ["#m_heg__zhangwu-wild"] = "章武：视为使用“野心家”，执行“先驱”、“阴阳鱼”或“珠联璧合”的效果",

  ["$m_heg__zhangwu1"] = "伐吴雪仇，兄与弟同往。",
  ["$m_heg__zhangwu2"] = "桃园之誓犹在，备当与二弟共死。",
  ["$m_heg__zhangwu3"] = "手足兄弟俱亡，万乘之躯又何惜哉。",
  ["$m_heg__zhangwu4"] = "结拜当同患难，共死亦非虚言。",
}

local H = require "packages.hegemony.util"

zhangwu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhangwu.name) and target.phase == Player.Finish then
      local marks = {}
      player.room.logic:getEventsOfScope(GameEvent.SkillEffect, 1, function (e)
        if e.data.who and H.compareKingdomWith(player, e.data.who) and
          table.contains({
            "vanguard_skill&",
            "yinyangfish_skill&",
            "companion_skill&",
            "wild_skill&",
          }, e.data.skill:getSkeleton().name) then
          table.insertIfNeed(marks, string.split(e.data.skill:getSkeleton().name, "_")[1])
        end
      end, Player.HistoryTurn)
      if #marks > 0 then
        event:setCostData(self, { choices = marks })
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      skill_name = zhangwu.name,
      prompt = "#m_heg__zhangwu-invoke",
      choices = event:getCostData(self).choices,
      cancelable = true,
    })
    if choice ~= "Cancel" then
      if choice == "wild" then
        choice = room:askToChoice(player, {
          skill_name = zhangwu.name,
          prompt = "#m_heg__zhangwu-wild",
          choices = { "vanguard", "yinyangfish", "companion" },
        })
      end
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "vanguard" then
      if 4 > player:getHandcardNum() then
        player:drawCards(4 - player:getHandcardNum(), "vanguard_skill&")
        if player.dead then return end
      end
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return p.general == "anjiang" or p.deputyGeneral == "anjiang"
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#m_heg__zhangwu-vanguard",
          skill_name = zhangwu.name,
          cancelable = false,
        })[1]
        local choices = { "known_both_main", "known_both_deputy" }
        if to.general ~= "anjiang" then
          table.remove(choices, 1)
        end
        if to.deputyGeneral ~= "anjiang" then
          table.remove(choices)
        end
        if #choices == 0 then return end
        choice = room:askToChoice(player, {
          choices = choices,
          skill_name = "vanguard_skill&",
          prompt = "#known_both-choice::"..target.id,
        })
        H.viewGeneral(player, to, "vanguard_skill&", choice == "known_both_main", choice == "known_both_deputy")
      end
    elseif choice == "yinyangfish" then
      choice = room:askToChoice(player, {
        choices = { "draw1", "MaxCards" },
        skill_name = zhangwu.name,
        prompt = "#m_heg__zhangwu-yinyangfish",
      })
      if choice == "draw1" then
        player:drawCards(1, "yinyangfish_skill&")
      else
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 2)
      end
    elseif choice == "companion" then
      local choices = { "draw2" }
      local card = Fk:cloneCard("peach")
      card.skillName = "companion_skill&"
      if player:canUse(card) then
        table.insert(choices, "peach")
      end
      choice = room:askToChoice(player, {
        choices = choices,
        skill_name = zhangwu.name,
        prompt = "#m_heg__zhangwu-companion",
      })
      if choice == "draw2" then
        player:drawCards(2, "companion_skill&")
      else
        room:useVirtualCard("peach", {}, player, player, "companion_skill&")
      end
    end
  end,
})

return zhangwu
