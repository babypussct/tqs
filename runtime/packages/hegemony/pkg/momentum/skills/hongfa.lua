local hongfa = fk.CreateSkill{
  name = "hongfa",
  derived_piles = "heavenly_army",
  tags = {Skill.Compulsory},
}
local H = require "packages.hegemony.util"
hongfa:addEffect(fk.GeneralRevealed, {
  anim_type = "support",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(hongfa.name, true) then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), hongfa.name) then return true end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(hongfa.name, 1)
    player.room:notifySkillInvoked(player, hongfa.name, "support")
  end,
})

local hongfa_attach = function(_, player, _)
  local room = player.room
  local players = room.alive_players
  local godzhangjiaos = table.filter(players, function(p) return p:hasShownSkill(hongfa.name) end)
  local hongfa_map = {}
  for _, p in ipairs(players) do
    local will_attach = false
    for _, godzhangjiao in ipairs(godzhangjiaos) do
      if H.compareKingdomWith(godzhangjiao, p) then
        will_attach = true
        break
      end
    end
    hongfa_map[p] = will_attach
  end
  for p, v in pairs(hongfa_map) do
    if v ~= p:hasSkill("heavenly_army_skill&") then
      room:handleAddLoseSkills(p, v and "heavenly_army_skill&" or "-heavenly_army_skill&", nil, false, true)
    end
  end
end
hongfa:addAcquireEffect(hongfa_attach)
hongfa:addLoseEffect(hongfa_attach)
hongfa:addEffect(fk.GeneralRevealed, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    hongfa_attach(_, player, _)
  end,
})

Fk:loadTranslationTable{
  ["hongfa"] = "弘法",
  [":hongfa"] = "<b><font color='goldenrod'>君主技</font></b>，你拥有“黄巾天兵符”。<br>#<b>黄巾天兵符</b>：<br>" ..
          "①准备阶段，若没有“天兵”，你将牌堆顶的X张牌置于武将牌上（称为“天兵”）（X为群势力角色数）。<br>" ..
          "②每有一张“天兵”，你执行的效果中的“群势力角色数”便+1。<br>" ..
          "③当你的失去体力结算开始前，若有“天兵”，你可将一张“天兵”置入弃牌堆，终止此失去体力流程。<br>" ..
          "④与你势力相同的角色可将一张“天兵”当【杀】使用或打出。",

  ["$hongfa1"] = "苍天已死，黄天当立！", -- 亮将
  ["$hongfa2"] = "汝等安心，吾乃大贤良师矣。", -- 拿天兵
  ["$hongfa3"] = "此法可助汝等脱离苦海。", -- 拿天兵
  ["$hongfa4"] = "此乃天将天兵，尔等妖孽看着！", -- 杀
  ["$hongfa5"] = "且作一法，召唤神力！", -- 杀
  ["$hongfa6"] = "吾有天神护体！", -- 防止失去体力
}

return hongfa
