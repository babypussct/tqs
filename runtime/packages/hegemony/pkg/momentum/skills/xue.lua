
local xue = fk.CreateSkill {
  name = "ld__xue",
}

Fk:loadTranslationTable {
  ["ld__xue"] = "蓄锷",
  [":ld__xue"] = "准备阶段，你可以视为对一个队列或围攻关系的所有其他角色使用一张【调虎离山】，然后你将手牌摸至与这些角色数相同。",

  ["#ld__xue-choose"] = "蓄锷：对一组阵法关系中的所有其他角色视为使用【调虎离山】",

  ["$ld__xue1"] = "一箭穿心，哪里可逃？",
  ["$ld__xue2"] = "穿心之痛，细细品吧，哈哈哈哈！",
}

local H = require "packages.hegemony.util"

xue:addAuxActiveSkill("#ld__xue_active", {
  card_num = 0,
  min_target_num = 1,
  interaction = UI.OptionBox { options = { "heg_formation", "heg_siege" } },
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    if to_select ~= player then
      if #selected == 0 then
        if self.interaction.data == "heg_formation" then
          return #H.getFormationRelation(to_select) > 0
        elseif self.interaction.data == "heg_siege" then
          for _, q in ipairs(Fk:currentRoom().alive_players) do
            if H.inSiegeRelation(to_select, to_select, q) or H.inSiegeRelation(q, q, to_select) then
              return true
            end
          end
        end
      else
        if self.interaction.data == "heg_formation" then
          return H.inFormationRelation(to_select, selected[1])
        elseif self.interaction.data == "heg_siege" then
          if #selected == 1 then
            return H.inSiegeRelation(to_select, to_select, selected[1]) or H.inSiegeRelation(selected[1], selected[1], to_select)
          elseif #selected == 2 then
            return H.inSiegeRelation(to_select, selected[1], selected[2]) or
              H.inSiegeRelation(to_select, selected[2], selected[1]) or
              H.inSiegeRelation(selected[1], selected[2], to_select)
          end
        end
      end
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if #selected > 0 then
      if self.interaction.data == "heg_formation" then
        for _, p in ipairs(H.getFormationRelation(selected[1])) do
          if p ~= player and not table.contains(selected, p) then
            return false
          end
        end
        return true
      elseif self.interaction.data == "heg_siege" then
        if #selected == 1 then
          return
        elseif #selected == 2 then
          return H.inSiegeRelation(selected[1], selected[2], player) or
            H.inSiegeRelation(selected[2], player, selected[1]) or
            H.inSiegeRelation(selected[1], player, selected[2])
        elseif #selected == 3 then
          return true
        end
      end
    end
  end,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if #selected > 0 and to_select ~= player then
      local ret = {}
      if H.inFormationRelation(selected[1], to_select) then
        table.insert(ret, {
          content = "heg_formation",
          type = "normal",
        })
      end
      for _, q in ipairs(Fk:currentRoom().alive_players) do
        if H.inSiegeRelation(to_select, to_select, q) or H.inSiegeRelation(q, q, to_select) then
          table.insert(ret, {
            content = "heg_siege",
            type = "normal",
          })
          break
        end
      end
      return ret
    end
  end,
})

xue:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xue.name) and player.phase == Player.Start then
      local card = Fk:cloneCard("lure_tiger")
      card.skillName = xue.name
      for _, p in ipairs(player.room:getOtherPlayers(player, false)) do
        if player:canUseTo(card, p) then
          if #H.getFormationRelation(p) > 0 then
            return true
          end
          for _, q in ipairs(player.room:getOtherPlayers(player, false)) do
            if H.inSiegeRelation(p, p, q) or H.inSiegeRelation(q, q, p) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#ld__xue_active",
      prompt = "#ld__xue-choose",
      cancelable = true,
    })
    if success and dat then
      room:sortByAction(dat.targets)
      event:setCostData(self, { tos = dat.targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = room:useVirtualCard("lure_tiger", nil, player, event:getCostData(self).tos, xue.name)
    if use and not player.dead and player:getHandcardNum() < #use.tos then
      player:drawCards(#use.tos - player:getHandcardNum(), xue.name)
    end
  end,
})

return xue
