local wanggui = fk.CreateSkill{
  name = "ty_heg__wanggui",
}
local H = require "packages.hegemony.util"
---@type TrigSkelSpec<DamageTrigFunc>
local wanggui_spec = {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(wanggui.name) and player:usedSkillTimes(wanggui.name) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if H.allGeneralsRevealed(player) then
      if room:askToSkillInvoke(player, {skill_name = wanggui.name, prompt = "#ty_heg__wanggui_draw-invoke"}) then
        event:setCostData(self, {})
        return true
      end
    else
      local targets = table.filter(room.alive_players, function(p)
        return H.compareKingdomWith(p, player, true) end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {targets = targets, min_num = 1,
        max_num = 1, prompt = "#ty_heg__wanggui_damage-choose", skill_name = wanggui.name, cancelable = true})
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(wanggui.name)
    local tos = event:getCostData(self).tos
    if tos then
      room:notifySkillInvoked(player, wanggui.name, "offensive", tos)
      room:damage{
        from = player,
        to = tos[1],
        damage = 1,
        skillName = wanggui.name,
      }
    else
      local targets = table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end)
      room:sortByAction(targets)
      room:notifySkillInvoked(player, wanggui.name, "drawcard", targets)
      for _, p in ipairs(targets) do
        if not p.dead then
          p:drawCards(1, wanggui.name)
        end
      end
    end
  end,
}
wanggui:addEffect(fk.Damage, wanggui_spec)
wanggui:addEffect(fk.Damaged, wanggui_spec)

wanggui:addTest(function (room, me)
  FkTest.runInRoom(function ()
    room:handleAddLoseSkills(me, wanggui.name)
  end)
  FkTest.setNextReplies(me, {"1"})
  FkTest.runInRoom(function ()
    room:changeHero(me, "zhangliao", false, true)
    room:damage{
      to = me, damage = 1
    }
  end)
  lu.assertEquals(me:getHandcardNum(), 1)

  local comp2 = room.players[2]
  local chooseComp2 = json.encode {
    card = { skill = "choose_players_skill", subcards = {} },
    targets = { comp2.id }
  }
  FkTest.setNextReplies(me, { chooseComp2, chooseComp2 })
  FkTest.runInRoom(function ()
    comp2:gainAnExtraTurn()
    me:hideGeneral(true)
    room:damage{
      from = me, to = comp2, damage = 1
    }
  end)
  lu.assertEquals(comp2.hp, 2)
end)

Fk:loadTranslationTable{
  ["ty_heg__wanggui"] = "望归",
  [":ty_heg__wanggui"] = "每回合限一次，当你造成或受到伤害后，若你：仅明置此武将牌，你可对与你势力不同的一名角色造成1点伤害；武将牌均明置，"..
    "你可令所有与你势力相同的角色各摸一张牌。",

  ["#ty_heg__wanggui_damage-choose"] = "望归：你可对与你势力不同的一名角色造成1点伤害",
  ["#ty_heg__wanggui_draw-invoke"] = "望归：你可令所有与你势力相同的角色各摸一张牌",

  ["$ty_heg__wanggui1"] = "存志太虚，安心玄妙。",
  ["$ty_heg__wanggui2"] = "礼法有度，良德才略。",
}

return wanggui
