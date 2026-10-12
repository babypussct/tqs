local mobileNiluan = fk.CreateSkill {
  name = "mobile__niluan",
}

Fk:loadTranslationTable{
  ["mobile__niluan"] = "逆乱",
  [":mobile__niluan"] = "其他角色的结束阶段，若其本回合对除其以外的角色使用过牌，你可以对其使用一张【杀】（无距离限制），" ..
  "然后此【杀】结算结束后，若此【杀】对其造成了伤害，你弃置其一张牌。",

  ["#mobile__niluan-slash"] = "逆乱：你可以对 %src 使用一张【杀】",

  ["$mobile__niluan1"] = "不是你死，便是我亡！",
  ["$mobile__niluan2"] = "后无退路，只有一搏！",
}

mobileNiluan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(mobileNiluan.name) and target.phase == Player.Finish and target:isAlive() and target ~= player then
      return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == target then
          for _, p in ipairs(use.tos) do
            if p ~= target then
              return true
            end
          end
        end
      end, Player.HistoryTurn) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askToUseCard(
      player,
      {
        pattern = "slash",
        prompt = "#mobile__niluan-slash:" .. target.id,
        skill_name = mobileNiluan.name,
        extra_data = { exclusive_targets = {target.id} , bypass_distances = true },
      }
    )
    if use then
      event:setCostData(self, use)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileNiluan.name
    local room = player.room
    local use = event:getCostData(self)
    use.extraUse = true
    room:useCard(use)
    if use.damageDealt and use.damageDealt[target] and player:isAlive() and not target:isNude() then
      local cid = room:askToChooseCard(player, { target = target, flag = "he", skill_name = skillName })
      room:throwCard({ cid }, skillName, target, player)
    end
  end,
})

return mobileNiluan
