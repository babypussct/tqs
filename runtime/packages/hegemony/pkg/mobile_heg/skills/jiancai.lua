
local jiancai = fk.CreateSkill{
  name = "m_heg__jiancai",
  tags = { Skill.DeputyPlace },
}

Fk:loadTranslationTable{
  ["m_heg__jiancai"] = "荐才",
  [":m_heg__jiancai"] = "副将技，此武将牌上单独的阴阳鱼个数-1。"..
  "此武将明置时或每轮游戏开始时，你一共获知X名未登场的同势力武将（X为当前轮数×3，不足则补齐）。"..
  "与你势力相同的角色受到致命伤害时，你可以防止此伤害，若如此做，你须变更副将；"..
  "若你所属的势力为小势力或非唯一大势力，则此次变更副将你可优先从你获知的武将中选择。",

  ["#m_heg__jiancai-view"] = "荐才：观看未登场的蜀势力武将",
  ["@[private]&m_heg__jiancai"] = "荐才",
  ["#m_heg__jiancai-invoke"] = "荐才：你可以防止 %dest 受到的致命伤害，然后你变更副将",

  ["$m_heg__jiancai1"] = "得此贤士，如鱼得水。",
  ["$m_heg__jiancai2"] = "将军，在下可举荐一人。",
}

local H = require "packages.hegemony.util"
local U = require "packages.utility.utility"

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getPrivateMark(player, "&m_heg__jiancai") or {}
    for i = #mark, 1, -1 do
      if not table.contains(room.general_pile, mark[i]) then
        table.remove(mark, i)
      end
    end
    local generals = table.filter(room.general_pile, function (g)
      return not table.contains(mark, g) and Fk.generals[g]:hasKingdom("shu")
    end)
    if #generals > 0 then
      local n = 3 * room:getBanner("RoundCount") - #mark
      generals = room:tableRandomPick(generals, n)
      table.insertTable(mark, generals)
    end
    U.setPrivateMark(player, "&m_heg__jiancai", mark)
    U.askToChooseGeneralsAndChoice(player, {
      generals = mark,
      skill_name = jiancai.name,
      min_num = 0,
      prompt = "#m_heg__jiancai-view",
    })
  end,
}

jiancai:addEffect(fk.RoundStart, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jiancai.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = spec.on_use,
})

jiancai:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jiancai.name) then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), jiancai.name) then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = spec.on_use,
})

jiancai:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiancai.name) and
      H.compareKingdomWith(player, target) and data.damage >= target.hp + target.shield
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = jiancai.name,
      prompt = "#m_heg__jiancai-invoke::"..target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    local yes = false
    if H.isSmallKingdomPlayer(player) then
      yes = true
    elseif H.isBigKingdomPlayer(player) then
      yes = table.find(room:getAlivePlayers(false), function (p)
        return not H.compareKingdomWith(player, p) and H.isBigKingdomPlayer(p)
      end) ~= nil
    end
    if yes then
      local generals = U.getPrivateMark(player, "&m_heg__jiancai") or {}
      for i = #generals, 1, -1 do
        if not table.contains(room.general_pile, generals[i]) then
          table.remove(generals, i)
        end
      end
      U.setPrivateMark(player, "&m_heg__jiancai", generals)
      if #generals > 0 then
        if #generals < 3 then
          local pool = table.filter(room.general_pile, function (g)
            return not table.contains(generals, g) and Fk.generals[g]:hasKingdom("shu")
          end)
          local n = 3 - #generals
          table.insertTable(generals, room:tableRandomPick(pool, n))
        else
          generals = room:tableRandomPick(generals, 3)
        end
        H.transformGeneral(room, player, false, false, 3, generals)
      else
        H.transformGeneral(room, player, false, false)
      end
    else
      H.transformGeneral(room, player, false, false)
    end
  end,
})

jiancai:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@[private]&m_heg__jiancai", 0)
end)

return jiancai
