local mShiKuanggu = fk.CreateSkill {
  name = "m_shi__kuanggu",
  dynamic_desc = function(self, player)
    return player:getMark("m_shi__kuanggu_upgrade") > 0 and "m_shi__kuanggu2" or "m_shi__kuanggu1"
  end,
}

Fk:loadTranslationTable{
  ["m_shi__kuanggu"] = "狂骨",
  [":m_shi__kuanggu"] = "当你对距离1以内的角色造成伤害后，你可以选择一项：1.回复1点体力；2.摸一张牌。<br>" ..
  "⬤　二级：当你对距离1以内的角色造成伤害后，你可以选择一项：1.回复1点体力；2.摸一张牌。背水：弃置一张牌，然后你此阶段使用【杀】的次数+1。",

  [":m_shi__kuanggu1"] = "当你对距离1以内的角色造成伤害后，你可以选择一项：1.回复1点体力；2.摸一张牌。",
  [":m_shi__kuanggu2"] = "当你对距离1以内的角色造成伤害后，你可以选择一项：1.回复1点体力；2.摸一张牌。" ..
  "背水：弃置一张牌，然后你此阶段使用【杀】的次数+1。",

  ["$m_shi__kuanggu1"] = "曹贼吴犬，我有何惧哉？",
  ["$m_shi__kuanggu2"] = "我尚未全力一搏，又试问谁能阻挡？",
  ["$m_shi__kuanggu3"] = "饮罢贼血，看我再立功绩。",
  ["$m_shi__kuanggu4"] = "与我为敌，是汝等最大的不幸。",
  ["$m_shi__kuanggu5"] = "贼寇尚未尽戮，我岂会还营？",
  ["$m_shi__kuanggu6"] = "可还有强敌，能让我浅尝一败？",
}

mShiKuanggu:addEffect(fk.Damage, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(mShiKuanggu.name) and
      (data.extra_data or {}).kuangguCheck
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = mShiKuanggu.name
    local room = player.room
    local allChoices = { "draw1", "recover", "Cancel" }
    if player:getMark("m_shi__kuanggu_upgrade") > 0 then
      table.insert(allChoices, 3, "beishui")
    end

    local choices = table.simpleClone(allChoices)
    if not player:isWounded() then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = skillName,
        all_choices = allChoices,
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mShiKuanggu.name
    local room = player.room
    local choice = event:getCostData(self).choice

    local audioIndex = math.random(1, 2)
    if choice == "beishui" then
      audioIndex = math.random(5, 6)
    elseif player:getMark("m_shi__kuanggu_upgrade") > 0 then
      audioIndex = math.random(3, 4)
    end
    player:broadcastSkillInvoke(skillName, audioIndex)
    room:notifySkillInvoked(player, skillName, "drawcard")

    if choice ~= "draw1" then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skillName,
      }

      if not player:isAlive() then
        return false
      end
    end

    if choice ~= "recover" then
      player:drawCards(1, skillName)

      if not player:isAlive() then
        return false
      end
    end

    if choice == "beishui" then
      local cards = room:askToDiscard(
        player,
        {
          min_num = 1,
          max_num = 1,
          skill_name = skillName,
          include_equip = true,
          cancelable = false,
        }
      )

      if #cards > 0 then
        room:addPlayerMark(player, MarkEnum.SlashResidue .. "-phase", 1)
      end
    end
  end,
})

mShiKuanggu:addEffect(fk.BeforeHpChanged, {
  can_refresh = function(self, event, target, player, data)
    if data.damageEvent and player == data.damageEvent.from and player:compareDistance(target, 2, "<") then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.damageEvent.extra_data = data.damageEvent.extra_data or {}
    data.damageEvent.extra_data.kuangguCheck = true
  end,
})

return mShiKuanggu
