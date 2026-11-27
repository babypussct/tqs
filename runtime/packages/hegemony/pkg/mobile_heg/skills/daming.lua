
local daming = fk.CreateSkill{
  name = "m_heg__daming",
}

Fk:loadTranslationTable{
  ["m_heg__daming"] = "达命",
  [":m_heg__daming"] = "与你势力相同的角色出牌阶段开始时，你可以弃置一张锦囊牌，横置一名角色并摸X张牌（X为有处于连环状态角色的势力数），"..
  "然后选择一项：1.视为对当前回合角色使用一张【桃】；2.令当前回合角色视为对你选择的另一名角色使用一张雷【杀】。",

  ["#m_heg__daming-invoke"] = "达命：你可以弃置一张锦囊牌，横置一名角色并摸牌，然后执行一项",
  ["#m_heg__daming-chain"] = "达命：横置一名角色，摸横置角色数张牌",
  ["#m_heg__daming-choice"] = "达命：对 %dest 执行一项",
  ["m_heg__daming_peach"] = "视为对其使用【桃】",
  ["m_heg__daming_slash"] = "令其视为对你指定的角色使用雷【杀】",
  ["#m_heg__daming-slash"] = "达命：选择 %dest 使用雷【杀】的目标",

  ["$m_heg__daming1"] = "幸蒙士元斟酌，诣公于葭萌，达命于蜀川。",
  ["$m_heg__daming2"] = "论治图王，助吾主成就大业。",
}

local H = require "packages.hegemony.util"

daming:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return H.compareExpectedKingdomWith(player, target) and player:hasSkill(daming.name) and target.phase == Player.Play and
      not player:isKongcheng() and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = daming.name,
      cancelable = true,
      pattern = ".|.|.|.|.|trick",
      prompt = "#m_heg__daming-invoke::" .. target.id,
      skip = true
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, daming.name, player, player)
    if player.dead then return end
    local targets = table.filter(room:getAlivePlayers(false), function(p)
      return not p.chained
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = daming.name,
      prompt = "#m_heg__daming-chain",
      cancelable = false,
    })[1]
    to:setChainState(true)
    if player.dead then return end
    local n = #table.filter(room:getAlivePlayers(false), function(p)
      return p.chained
    end)
    if n > 0 then
      player:drawCards(n, daming.name)
      if player.dead then return end
    end
    if target.dead then return end
    local choices = {}
    if not player:isProhibited(target, Fk:cloneCard("peach", nil, nil, daming.name)) then
      table.insert(choices, "m_heg__daming_peach")
    end
    targets = table.filter(room:getOtherPlayers(target, false), function(p)
      return not target:isProhibited(p, Fk:cloneCard("thunder__slash", nil, nil, daming.name))
    end)
    if #targets > 0 then
      table.insert(choices, "m_heg__daming_slash")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = daming.name,
      prompt = "#m_heg__daming-choice::"..target.id,
    })
    if choice == "m_heg__daming_peach" then
      room:useVirtualCard("peach", nil, player, target, daming.name)
    else
      to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = daming.name,
        prompt = "#m_heg__daming-slash::"..target.id,
        cancelable = false,
      })[1]
      room:useVirtualCard("thunder__slash", nil, target, to, daming.name, true)
    end
  end,
})

return daming
