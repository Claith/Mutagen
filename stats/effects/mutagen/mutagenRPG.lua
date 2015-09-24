-- Mutagen RPG for Starbound
-- Christopher "Claith" Smith
--
-- Versioning --
-- 1.0 (v1) - Initial release - General Skills (no Weapon Skills)
---- + Run Skill									-- Movement Speed Increase
---- + Walk Skill									-- Walk Speed Increase
---- + Swim Skill									-- Ease of Swiming
---- + Jump Skill									-- Jump Height / Fall Distance
---- + Endurance Skill						-- HP Regen
---- + Energy Skill								-- Energy Regen
---- + Breath Skill								-- Adds a Delay Before Breath Decreases
---- + Dark Walker Skill					-- Slow Passive Heal After Cooldown in Unlit Areas
---- + Light Walker Skill					-- Applies "Glow" Status Effect to Nearby Entities
---- + Tempurature Skill					-- No skill currently
---- + Evasion (Run / Jump)				-- Chance to Heal Damage and Random Teleport on Hit

function init()
	--world.logInfo( "mutagenRPG.lua : Init call" )
	--script.setUpdateDelta(1) -- slow down updating a bit
	
	mutagenSetup( )
	
	self.lastYVelocity								= 0
	self.fallDistance									= 0
	self.lastHealth										= status.resource( "health" )
	self.lastEnergy										= status.resource( "energy" )
	self.lastBreath										= status.resource( "breath" )
	
	-- General Variables
	self.skillLevelUpThreshold				= status.statusProperty( "mutagenSkillLevelUpThreshold" )
	self.skillLevelUpDelta						= status.statusProperty( "mutagenSkillLevelUpDelta" )
	self.minSkillDelta								= status.statusProperty( "mutagenMinSkillDelta" )
	self.maxSkillLevel								= status.statusProperty( "mutagenSkillLevelCap" )
	
	-- Run Skill
	self.runSkill											= status.statusProperty( "mutagenRunSkill" )
	self.runSkillLevel								= status.statusProperty( "mutagenRunSkillLevel" )
	self.runSkillModifierBase					= effect.configParameter( "runSkillModifier", 0.25 )
	self.runSpeed											= effect.configParameter( "runSpeed", 14.0 )
	self.runSkillModifier							= self.runSpeed * ( 1 + self.runSkillModifierBase * math.log10( self.runSkillLevel ) )
	
	-- Walk Skill
	self.walkSkill										= status.statusProperty( "mutagenWalkSkill" )
	self.walkSkillLevel								= status.statusProperty( "mutagenWalkSkillLevel" )
	self.walkSkillModifierBase				= effect.configParameter( "walkSkillModifier", 0.55 )
	self.walkSpeed										= effect.configParameter( "walkSpeed", 8.0 )
	self.walkSkillModifier						= self.walkSpeed * ( 1 + self.walkSkillModifierBase * math.log10( self.walkSkillLevel ) )
	
	-- Jump Skill
	self.jumpSkill										= status.statusProperty( "mutagenJumpSkill" )
	self.jumpSkillLevel								= status.statusProperty( "mutagenJumpSkillLevel" )
	self.jumpSkillModifierBase				= effect.configParameter( "jumpSkillModifier", 0.25 )
	self.jumpSkillFallModifierBase		= effect.configParameter( "fallDamageModifier", -0.001 )
	self.jumpSkillModifier						= self.jumpSkillModifierBase * math.log10( self.jumpSkillLevel )
	self.jumpSkillFallModifier				= self.jumpSkillFallModifierBase * self.jumpSkillLevel
	
	-- Swim Skill
	self.swimSkill										= status.statusProperty( "mutagenSwimSkill" )
	self.swimSkillLevel								= status.statusProperty( "mutagenSwimSkillLevel" )
	self.swimSkillModifierBase				= effect.configParameter( "swimSkillModifier", 0.5 )
	self.liquidFriction								= effect.configParameter( "liquidFriction", 5 )
	self.swimSkillModifier						= self.liquidFriction - ( self.swimSkillModifierBase * math.log10( self.swimSkillLevel ) )
	
	-- Endurance Skill
	self.enduranceSkill								= status.statusProperty( "mutagenEnduranceSkill" )
	self.enduranceSkillLevel					= status.statusProperty( "mutagenEnduranceSkillLevel" )
	self.enduranceSkillModifierBase		= effect.configParameter( "enduranceSkillModifier", 0.25 )
	self.enduranceSkillModifier				=	self.enduranceSkillModifierBase * math.log10( self.enduranceSkillLevel )
	
	-- Energy Skill
	self.energySkill									= status.statusProperty( "mutagenEnergySkill" )
	self.energySkillLevel							= status.statusProperty( "mutagenEnergySkillLevel" )
	self.energySkillModifierBase			= effect.configParameter( "energySkillModifier", 0.2 )
	self.energySkillModifier					= self.energySkillModifierBase * self.energySkillLevel
	
	-- Breath Skill
	self.breathSkill									= status.statusProperty( "mutagenBreathSkill" )
	self.breathSkillLevel							= status.statusProperty( "mutagenBreathSkillLevel" )
	self.breathSkillModifierBase			= effect.configParameter( "breathSkillModifier", 0.6 )
	--self.breathSkillCooldownBase			= effect.configParameter( "breathSkillCooldownBase", 0.0 )
	self.breathSkillCooldownTimer			= 0.0
	self.breathSkillModifier					= self.breathSkillModifierBase * self.breathSkillLevel
	
	-- Dark Walker Skill
	self.darkWalkerSkill							= status.statusProperty( "mutagenDarkWalkerSkill" )
	self.darkWalkerSkillLevel					= status.statusProperty( "mutagenDarkWalkerSkillLevel" )
	self.darkWalkerSkillModifierBase	= effect.configParameter( "darkWalkerSkillModifier", 0.0001 )
	self.darkWalkerSkillCooldownBase	= effect.configParameter( "darkWalkerSkillCooldown", 10.0 )
	self.darkWalkerSkillCooldownMod 	= effect.configParameter( "darkWalkerSkillCooldownMod", -0.01 )
	self.darkWalkerSkillThreshold			= effect.configParameter( "darkWalkerSkillThreshold", 0.2 )
	self.darkWalkerSkillCooldownTimer	=	0.0
	self.darkWalkerSkillCooldown			= self.darkWalkerSkillCooldownBase + ( self.darkWalkerSkillCooldownMod * self.darkWalkerSkillLevel )
	self.darkWalkerSkillModifier			= self.darkWalkerSkillModifierBase * self.darkWalkerSkillLevel
	
	-- Light Walker Skill
	self.lightWalkerSkill							= status.statusProperty( "mutagenLightWalkerSkill" )
	self.lightWalkerSkillLevel				= status.statusProperty( "mutagenLightWalkerSkillLevel" )
	self.lightWalkerSkillModifierBase	= effect.configParameter( "lightWalkerSkillModifier", 0.4 )
	self.lightWalkerSkillRange				= effect.configParameter( "lightWalkerSkillRange", 100 )
	self.lightWalkerSkillCooldownBase	= effect.configParameter( "lightWalkerSkillCooldown", 10.0 )
	self.lightWalkerSkillCooldownMod	= effect.configParameter( "lightWalkerSkillCooldownMod", -0.005 )
	self.lightWalkerSkillThreshold		= effect.configParameter( "lightWalkerSkillThreshold", 0.7 )
	self.lightWalkerSkillCooldownTimer= 0.0
	self.lightWalkerSkillCooldown			= self.lightWalkerSkillCooldownBase + ( self.lightWalkerSkillCooldownMod * self.lightWalkerSkillLevel )
	self.lightWalkerSkillModifier			= self.lightWalkerSkillRange + ( self.lightWalkerSkillModifierBase * self.lightWalkerSkillLevel )
	
	-- Tempurature Skill
	self.tempuratureSkill							= status.statusProperty( "mutagenTempuratureSkill" )
	self.tempuratureSkillLevel				= status.statusProperty( "mutagenTempuratureSkillLevel" )
	
	-- Evasion Skill
	self.evasionSkill									= status.statusProperty( "mutagenEvasionSkill" )
	self.evasionSkillLevel						= status.statusProperty( "mutagenEvasionSkillLevel" )
	self.evasionSkillModifierBase			= effect.configParameter( "evasionSkillModifier", 0.25 )
	self.evasionSkillCooldown					= effect.configParameter( "evasionCooldown", 10.0 )
	self.evasionSkillCooldownModifier	= effect.configParameter( "evasionCooldownModifier", -0.01 )
	self.evasionSkillBlinkCollision		= effect.configParameter( "blinkCollisionCheckDiameter", 4 )
	self.evasionSkillBlinkVerticalCol	= effect.configParameter( "blinkVerticalGroundCheck", 10 )
	self.evasionSkillBlinkFootOffset	= effect.configParameter( "blinkFootOffset", -2.5 )
	self.evasionSkillBlinkOutTime			= effect.configParameter( "blinkOutTime", 0.15 )
	self.evasionSkillBlinkInTime			= effect.configParameter( "blinkInTime", 0.15 )
	self.evasionSkillBlinkMode				= effect.configParameter( "blinkMode", "random" )
	self.evasionSkillRandBlinkTries		= effect.configParameter( "randomBlinkTries", 60 )
	self.evasionSkillRandBlinkDiameter= effect.configParameter( "randomBlinkDiameter", 40 )
	self.evasionSkillAvoidCollision		= effect.configParameter( "randomBlinkAvoidCollision", true )
	self.evasionSkillAvoidLiquid			= effect.configParameter( "randomBlinkAvoidLiquid", true )
	self.evasionSkillAvoidMidair			= effect.configParameter( "randomBlinkAvoidMidair", true )
	self.evasionSkillCooldownTimer		= 0.0
	self.evasionSkillMode							= "none"
	self.evasionSkillTargetPosition		= nil
	self.evasionSkillAnimationTimer		= 0.0
	self.evasionSkillModifier					= self.evasionSkillModifierBase * math.log( self.evasionSkillLevel )
	
	local bounds 											= mcontroller.boundBox()
	self.centerOffset									= { ( bounds[1] + bounds[3] ) / 2, ( bounds[2] + bounds[4] ) / 2 }
	--animator.setParticleEmitterOffsetRegion("mutagenLevelUpParticles", {bounds[1], bounds[2] + 0.2, bounds[3], bounds[2] + 0.3})
	self.emit													= false
	--self.statModifierID = effect.addStatModifierGroup({{stat = "fallDamageMultiplier", amount = self.jumpSkillFallModifier}})
	--world.logInfo( "mutagenRPG.lua::init() : statModifierID = " .. self.statModifierID )
end

-- Handles Skill Gains
function update(dt)
	--world.logInfo( "mutagenRPG.lua::update(dt) : Start" )
	local skillGain 									= 0.0
	
	-- Jump Variables
	local minimumFallDistance 				= 14
  local fallDistanceDamageFactor 		= 3
  local minimumFallVel 							= 40
  local baseGravity 								= 80
  local gravityDiffFactor 					= 1 / 30.0
	local curPosition									= mcontroller.position()
  local curYVelocity 								= mcontroller.yVelocity()
  local yVelChange 									= curYVelocity - self.lastYVelocity
	local damage 											= 0.0
	
	-- Endurance Variables
	local curHealth										= status.resource( "health" )

	-- Energy Variables
	local curEnergy										= status.resource( "energy" )
	
	-- Breath Variables
	local curBreath										= status.resource( "breath" )
	
	-- Dark / Light Walker Variables
	local lightLevel									= world.lightLevel( vec2add( curPosition, self.centerOffset ) ) -- mouth position isn't any different
	local maxHealth										= status.resourceMax( "health" )
	
	if self.emit then
		self.emit = false
		--animator.setParticleEmitterActive( "mutagenLevelUpParticles", false )
	end
	
	-- Run Skill
	world.debugText( "mutagenRunSkill = %f / %f : %f of %f", self.runSkill, self.skillLevelUpThreshold, self.runSkillLevel, self.maxSkillLevel, vec2add( curPosition, {5, 9} ), "red" )
	
	if mcontroller.running() and mcontroller.onGround() then
		skillGain = math.abs( self.minSkillDelta * ( mcontroller.positionDelta()[1] / self.runSkillLevel ) )
		self.runSkill = self.runSkill + skillGain
	end
	
	-- Walk Skill
	world.debugText( "mutagenWalkSkill = %f / %f : %f of %f", self.walkSkill, self.skillLevelUpThreshold, self.walkSkillLevel, self.maxSkillLevel, vec2add( curPosition, {5, 8} ), "green" )
	
	if mcontroller.walking() and mcontroller.onGround() and mcontroller.movingDirection() ~= mcontroller.facingDirection() then
		skillGain = math.abs( self.minSkillDelta * ( mcontroller.positionDelta()[1] / self.walkSkillLevel ) )
		self.walkSkill = self.walkSkill + skillGain
	end
	
	-- Jump Skill	
	world.debugText( "mutagenJumpSkill = %f / %f : %f of %f", self.jumpSkill, self.skillLevelUpThreshold, self.jumpSkillLevel, self.maxSkillLevel, vec2add( curPosition, {5, 7} ), "white" )
	
	--world.debugText( "Fall Distance = %f, yVelChange = %f, minFallVel = %f", self.fallDistance, -yVelChange, minimumFallVel, vec2add( curPosition, {-5, 9}, "white" )
	
	if self.fallDistance > minimumFallDistance and yVelChange > minimumFallVel and mcontroller.onGround() then
    damage = (self.fallDistance - minimumFallDistance) * fallDistanceDamageFactor
    damage = damage * (1.0 + (world.gravity(curPosition) - baseGravity) * gravityDiffFactor)
		
		if damage > 0 then
			skillGain = self.minSkillDelta * ( damage / self.jumpSkillLevel )
			self.jumpSkill = self.jumpSkill + skillGain
		end
	end
	
	if curYVelocity < -minimumFallVel then
    self.fallDistance = self.fallDistance + -mcontroller.positionDelta()[2]
  else
    self.fallDistance = 0
  end
	
	-- Swim Skill
	world.debugText( "mutagenSwimSkill = %f / %f : %f of %f", self.swimSkill, self.skillLevelUpThreshold, self.swimSkillLevel, self.maxSkillLevel, vec2add( curPosition, {5, 6} ), "blue" )
	
	if mcontroller.inLiquid() and not mcontroller.onGround() then
		skillGain = self.minSkillDelta * ( world.magnitude( mcontroller.positionDelta() ) / self.swimSkillLevel )
		self.swimSkill = self.swimSkill + skillGain
	end
	
	updateMovement( dt )
	
	-- Endurance Skill
	world.debugText( "mutagenEnduranceSkill = %f / %f : %f of %f", self.enduranceSkill, self.skillLevelUpThreshold, self.enduranceSkillLevel, self.maxSkillLevel, vec2add( curPosition, {5, 5} ), "white" )
	
	damage = self.lastHealth - curHealth
	if damage > 0 and curHealth > 0 then
		skillGain = self.minSkillDelta * ( damage / self.enduranceSkillLevel )
		self.enduranceSkill = self.enduranceSkill + skillGain
		
		--world.logInfo( "mutagen :: Endurance : Modifier = %f Damage = %f", self.enduranceSkillModifier, damage )
		
		status.modifyResource( "health" , self.enduranceSkillModifier * damage ) -- Didn't want to apply the effect here, but need to break design
		
		world.logInfo( "cooldown timer = %f / %f", self.evasionSkillCooldownTimer, self.evasionSkillCooldown )
		
		-- evasion code
		if self.evasionSkillCooldownTimer >= self.evasionSkillCooldown then
			local chance = math.random()
			
			world.logInfo( "Evasion Start : Chance = %f / %f", chance, self.evasionSkillModifier )
			
			-- I feel like I should make a status effect that randomly teleports characters. Might be better than having this code as is.
			
			if chance < self.evasionSkillModifier then
				local blinkPosition = findRandomBlinkLocation(self.evasionSkillAvoidCollision, self.evasionSkillAvoidLiquid, self.evasionSkillAvoidMidair) or
        findRandomBlinkLocation(self.evasionSkillAvoidCollision, self.evasionSkillAvoidLiquid, false) or
        findRandomBlinkLocation(self.evasionSkillAvoidCollision, false, false)
				
				if blinkPosition then
					world.logInfo( "position found" )
					self.evasionSkillTargetPosition = blinkPosition
					self.evasionSkillMode = "start"
				else
					-- Make some kind of error noise
					world.logInfo( "position not found" )
				end
				
				if self.evasionSkillMode == "start" then
					world.logInfo( "blink start" )
					mcontroller.setVelocity({0, 0})
					self.evasionSkillMode = "out"
					self.evasionSkillAnimationTimer = 0

				elseif self.evasionSkillMode == "out" then
					effect.setParentDirectives("?multiply=00000000")
					--effect.setAnimationState("blinking", "out")
					mcontroller.setVelocity({0, 0})
					self.evasionSkillAnimationTimer = self.evasionSkillAnimationTimer + dt

					if self.evasionSkillAnimationTimer > self.evasionSkillBlinkOutTime then
						world.logInfo( "teleport" )
						mcontroller.setPosition(self.evasionSkillTargetPosition)
						self.evasionSkillMode = "in"
						self.evasionSkillAnimationTimer = 0
					end
				elseif self.evasionSkillMode == "in" then
					effect.setParentDirectives( "" )
					--effect.setAnimationState("blinking", "in")
					mcontroller.setVelocity({0, 0})
					self.evasionSkillAnimationTimer = self.evasionSkillAnimationTimer + dt

					if self.evasionSkillAnimationTimer > self.evasionSkillBlinkInTime then
						self.evasionSkillMode = "none"
						self.evasionSkillCooldownTimer = 0.0
						effect.setParentDirectives( "" )
					end
				end			
			end			
		end
	end
	
	self.evasionSkillCooldownTimer = self.evasionSkillCooldownTimer + dt
	
	-- Energy Skill
	world.debugText( "mutagenEnergySkill = %f / %f : %f of %f", self.energySkill, self.skillLevelUpThreshold, self.energySkillLevel, self.maxSkillLevel, vec2add( curPosition, {5, 4} ), "red" )
	
	damage = self.lastEnergy - curEnergy
	if damage > 0 then
		skillGain = self.minSkillDelta * ( damage / ( self.energySkillLevel + 1 ) )
		self.energySkill = self.energySkill + skillGain
	end
	
	-- Breath Skill
	world.debugText( "mutagenBreathSkill = %f / %f : %f of %f", self.breathSkill, self.skillLevelUpThreshold, self.breathSkillLevel, self.maxSkillLevel, vec2add( curPosition, {5, 3} ), "white" )
	
	damage = self.lastBreath - curBreath
	if damage > 0 then
		skillGain = self.minSkillDelta * ( damage / ( self.breathSkillLevel + 1 ) )
		self.breathSkill = self.breathSkill + skillGain
		
		if self.breathSkillCooldownTimer < self.breathSkillModifier then
			status.modifyResource( "breath", damage )
			self.breathSkillCooldownTimer = self.breathSkillCooldownTimer + dt
		end
	else
		self.breathSkillCooldownTimer = 0.0
	end
	
	-- Tempurature Skill -- NOT IMPLEMENTED
	--world.debugText( "mutagenTempuratureSkill = %f / %f : %f of %f", self.tempuratureSkill" ), self.skillLevelUpThreshold, self.TempuratureSkillLevel" ), self.maxSkillLevel, vec2add( curPosition, {5, 2} ), "red" )
	
	updateStatus( dt )
	
	-- Dark Walker Skill
	world.debugText( "mutagenDarkWalkerSkill = %f / %f : %f of %f", self.darkWalkerSkill, self.skillLevelUpThreshold, self.darkWalkerSkillLevel, self.maxSkillLevel, vec2add( curPosition, {5, 1} ), "green" )
	
	--world.debugText( "Light Level = %f", lightLevel, vec2add( curPosition, {-5, 1} ), "green" )
	
	if lightLevel < self.darkWalkerSkillThreshold then
		local darkModifier = 1.0 - lightLevel -- The darker, the stronger
		skillGain = self.minSkillDelta * darkModifier / ( self.darkWalkerSkillLevel + 1 )
		self.darkWalkerSkill = self.darkWalkerSkill + skillGain
		
		if self.darkWalkerSkillCooldownTimer >= self.darkWalkerSkillCooldown then
			status.modifyResource( "health", darkModifier * self.darkWalkerSkillModifier * maxHealth * dt )
		else
			self.darkWalkerSkillCooldownTimer = self.darkWalkerSkillCooldownTimer + dt
		end
	else
		self.darkWalkerSkillCooldownTimer = 0.0
	end
	
	-- Light Walker Skill
	world.debugText( "mutagenLightWalkerSkill = %f / %f : %f of %f", self.lightWalkerSkill, self.skillLevelUpThreshold, self.lightWalkerSkillLevel, self.maxSkillLevel, vec2add( curPosition, {5, 0} ), "blue" )
	
	if lightLevel > self.lightWalkerSkillThreshold then
		skillGain = self.minSkillDelta * lightLevel / ( self.lightWalkerSkillLevel + 1 )
		self.lightWalkerSkill = self.lightWalkerSkill + skillGain
		
		if self.lightWalkerSkillCooldownTimer >= self.lightWalkerSkillCooldown then
			local entityIds = world.entityQuery(curPosition, self.lightWalkerSkillModifier, { includedTypes = {"monster"} })--potentialTargets()
	
			for i, entityId in ipairs(entityIds) do
				if validTarget(entityId) then
					world.callScriptedEntity( entityId, "mutagenApplyLightWalkerEffect" )
				end
			end
			
			self.lightWalkerSkillCooldownTimer = 0.0
		else
			self.lightWalkerSkillCooldownTimer = self.lightWalkerSkillCooldownTimer + dt
		end
	else
		self.lightWalkerSkillCooldownTimer = 0.0
	end
	
	-- Evasion Skill
	-- Implemented the effect in the endurance code above
	
	updateMisc( dt )
	
	self.lastHealth = curHealth
	self.lastEnergy = curEnergy
	self.lastBreath = curBreath
	self.lastYVelocity = curYVelocity
	
	--world.logInfo("mutagenRPG.lua::Update exit : ")
end

-- Movement Skills
function updateMovement(dt)
	
	if ( self.runSkill >= self.skillLevelUpThreshold ) and ( self.runSkillLevel < self.maxSkillLevel ) then
		self.runSkillLevel = self.runSkillLevel + self.skillLevelUpDelta
		self.runSkill = self.runSkill - self.skillLevelUpThreshold

		self.runSkillModifier = self.runSpeed * ( 1 + self.runSkillModifierBase * math.log10( self.runSkillLevel ) )
		
		--self.emit = animator.setParticleEmitterActive( "mutagenRunSkillParticles", true )
	end	
	
	if ( self.walkSkill >= self.skillLevelUpThreshold ) and ( self.walkSkillLevel < self.maxSkillLevel ) then
		self.walkSkillLevel = self.walkSkillLevel + self.skillLevelUpDelta
		self.walkSkill = self.walkSkill - self.skillLevelUpThreshold
		
		self.walkSkillModifier = self.walkSpeed * ( 1 + self.walkSkillModifierBase * math.log10( self.walkSkillLevel ) )
	end
	
	if ( self.jumpSkill >= self.skillLevelUpThreshold ) and ( self.jumpSkillLevel < self.maxSkillLevel ) then
		self.jumpSkillLevel = self.jumpSkillLevel + self.skillLevelUpDelta
		self.jumpSkill = self.jumpSkill - self.skillLevelUpThreshold
		
		self.jumpSkillModifier = self.jumpSkillModifierBase * math.log( self.jumpSkillLevel ) -- Look into modifying the air jump profile
		self.jumpSkillFallModifier = self.jumpSkillFallModifierBase * self.jumpSkillLevel
		
		--if self.statModifierID ~= nil then
			--effect.removeStatModifierGroup( self.statModifierID )
		--end
		
		-- As a last ditch effort, I can implement this skill or rather any that use modifier groups, as their own status effect with a duration.
		
		--self.statModifierID = effect.addStatModifierGroup({{stat = "fallDamageMultiplier", amount = self.jumpSkillFallModifier}}) -- will have to move this later
	end
	
	if (self.swimSkill >= self.skillLevelUpThreshold ) and ( self.swimSkillLevel < self.maxSkillLevel ) then
		self.swimSkillLevel = self.swimSkillLevel + self.skillLevelUpDelta
		self.swimSkill = self.swimSkill - self.skillLevelUpThreshold
		
		self.swimSkillModifier = self.liquidFriction - ( self.swimSkillModifierBase * math.log10( self.swimSkillLevel ) )
	end
	
	-- Both need to be reapplied each loop
	mcontroller.controlParameters( { runSpeed = self.runSkillModifier, walkSpeed = self.walkSkillModifier, liquidFriction = self.swimSkillModifier } )
	mcontroller.controlModifiers( { jumpModifier = self.jumpSkillModifier } )
end

-- Status Skills
function updateStatus(dt)
	if ( self.enduranceSkill >= self.skillLevelUpThreshold ) and ( self.enduranceSkillLevel < self.maxSkillLevel ) then
		self.enduranceSkillLevel = self.enduranceSkillLevel + self.skillLevelUpDelta
		self.enduranceSkill = self.enduranceSkill - self.skillLevelUpThreshold
		
		self.enduranceSkillModifier = self.enduranceSkillModifierBase * math.log10( self.enduranceSkillLevel )
	end
	
	if ( self.energySkill >= self.skillLevelUpThreshold ) and ( self.energySkillLevel < self.maxSkillLevel ) then
		self.energySkillLevel = self.energySkillLevel + self.skillLevelUpDelta
		self.energySkill = self.energySkill - self.skillLevelUpThreshold
		
		self.energySkillModifier = self.energySkillModifierBase * self.energySkillLevel
	end
	
	if ( self.breathSkill >= self.skillLevelUpThreshold ) and ( self.breathSkillLevel < self.maxSkillLevel ) then
		self.breathSkillLevel = self.breathSkillLevel + self.skillLevelUpDelta
		self.breathSkill = self.breathSkill - self.skillLevelUpThreshold
		
		self.breathModifier = self.breathModifierBase * self.breathSkillLevel
	end
	
	status.modifyResource( "energy", self.energySkillModifier * dt )
end

function updateMisc(dt)
	if ( self.darkWalkerSkill >= self.skillLevelUpThreshold ) and ( self.darkWalkerSkillLevel < self.maxSkillLevel ) then
		self.darkWalkerSkillLevel = self.darkWalkerSkillLevel + self.skillLevelUpDelta
		self.darkWalkerSkill = self.darkWalkerSkill - self.skillLevelUpThreshold
		
		self.darkWalkerSkillModifier = self.darkWalkerSkillModifierBase * self.darkWalkerSkillLevel
		self.darkWalkerSkillCooldown = self.darkWalkerSkillCooldownBase + ( self.darkWalkerSkillCooldownMod * self.darkWalkerSkillLevel )
	end
	
	if ( self.lightWalkerSkill >= self.skillLevelUpThreshold ) and ( self.lightWalkerSkillLevel < self.maxSkillLevel ) then
		self.lightWalkerSkillLevel = self.lightWalkerSkillLevel + self.skillLevelUpDelta
		self.lightWalkerSkill = self.lightWalkerSkill - self.skillLevelUpThreshold
		
		self.lightWalkerSkillModifier = self.lightWalkerSkillRange + ( self.lightWalkerSkillModifierBase * self.lightWalkerSkillLevel )
		self.lightWalkerSkillCooldown = self.lightWalkerSkillCooldownBase + ( self.lightWalkerSkillCooldownMod * self.lightWalkerSkillLevel )
	end
	
	if math.floor( ( self.runSkillLevel + self.jumpSkillLevel ) / 2 ) > self.evasionSkillLevel then
		self.evasionSkillLevel = ( self.runSkillLevel + self.jumpSkillLevel ) / 2
		
		self.evasionSkillModifier = self.evasionSkillModifierBase * math.log( self.evasionSkillLevel )
	end
end

-- Setup Initial Skill Status Effects -- not sure this has a purpose anymore
function mutagenSetup()

	if status.statusProperty( "mutagenSetup" ) == 1 then
		if status.statusProperty( "mutagenVersion" ) == 0 then

			status.setStatusProperty( "mutagenVersion", 1 )
			
			--for key,value in pairs(mcontroller.baseParameters()) do world.logInfo( "%s = %f", key,value) end
			
		elseif status.statusProperty( "mutagenVersion" ) == 1 then
			-- Code for the next release update that adds skills, likely derivative skills
			-- This is so that a new character is not required for each major mod update. Be forward compatible.
		end
		status.setStatusProperty( "mutagenSetup", 2 ) -- Finished Step Two
	end
end

function validTarget(targetId)
  --Does it exist?
  if world.entityExists(targetId) == false then
    return false
  end
  
  --Is it dead yet
  local targetHealth = world.entityHealth(targetId)
  if targetHealth ~= nil and targetHealth[1] <= 0 then
    return false
  end
	
	return true
end

function potentialTargets( )
	local npcIds = world.entityQuery(mcontroller.position(), self.lightWalkerSkillModifier, { includedTypes = {"npc"} })
  local monsterIds = world.entityQuery(mcontroller.position(), self.lightWalkerSkillModifier, { includedTypes = {"monster"} })

  for i,npcId in ipairs(npcIds) do
    if entity.isValidTarget(npcId) then
      monsterIds[#monsterIds+1] = npcId
    end
  end
	
	return monsterIds
end

function checkCollision(position)
  local boundBox = mcontroller.boundBox()
  boundBox[1] = boundBox[1] - mcontroller.position()[1] + position[1]
  boundBox[2] = boundBox[2] - mcontroller.position()[2] + position[2]
  boundBox[3] = boundBox[3] - mcontroller.position()[1] + position[1]
  boundBox[4] = boundBox[4] - mcontroller.position()[2] + position[2]

  return not world.rectCollision(boundBox)
end

function blinkAdjust(position, doPathCheck, doCollisionCheck, doLiquidCheck, doStandCheck)
  if doPathCheck then
    local collisionBlocks = world.collisionBlocksAlongLine(mcontroller.position(), position, true, 1)
    if #collisionBlocks ~= 0 then
      local diff = world.distance(position, mcontroller.position())
      diff[1] = diff[1] / math.abs(diff[1])
      diff[2] = diff[2] / math.abs(diff[2])

      position = {collisionBlocks[1][1] - diff[1], collisionBlocks[1][2] - diff[2]}
    end
  end

  if doCollisionCheck and not checkCollision(position) then
    local spaceFound = false
    for i = 1, self.evasionSkillBlinkCollision * 2 do
      if checkCollision({position[1] + i / 2, position[2] + i / 2}) then
        position = {position[1] + i / 2, position[2] + i / 2}
        spaceFound = true
        break
      end

      if checkCollision({position[1] - i / 2, position[2] + i / 2}) then
        position = {position[1] - i / 2, position[2] + i / 2}
        spaceFound = true
        break
      end

      if checkCollision({position[1] + i / 2, position[2] - i / 2}) then
        position = {position[1] + i / 2, position[2] - i / 2}
        spaceFound = true
        break
      end

      if checkCollision({position[1] - i / 2, position[2] - i / 2}) then
        position = {position[1] - i / 2, position[2] - i / 2}
        spaceFound = true
        break
      end
    end

    if not spaceFound then
      return nil
    end
  end

  if doStandCheck then
    local groundFound = false 
    for i = 1, self.evasionSkillBlinkVerticalCol * 2 do
      local checkPosition = {position[1], position[2] - i / 2}

      if world.pointCollision(checkPosition, false) then
        groundFound = true
        position = {checkPosition[1], checkPosition[2] + 0.5 - self.evasionSkillBlinkFootOffset}
        break
      end
    end

    if not groundFound then
      return nil
    end
  end

  if doLiquidCheck and (world.liquidAt(position) or world.liquidAt({position[1], position[2] + self.evasionSkillBlinkFootOffset})) then
    return nil
  end

  if doCollisionCheck and not checkCollision(position) then
    return nil
  end

  return position
end

function findRandomBlinkLocation(doCollisionCheck, doLiquidCheck, doStandCheck)
  for i = 1, self.evasionSkillRandBlinkTries do
    local position = mcontroller.position()
    position[1] = position[1] + (math.random() * 2 - 1) * self.evasionSkillRandBlinkDiameter
    position[2] = position[2] + (math.random() * 2 - 1) * self.evasionSkillRandBlinkDiameter

    local position = blinkAdjust( position, false, doCollisionCheck, doLiquidCheck, doStandCheck )
    if position then
      return position
    end
  end

  return nil
end

-- Since I don't seem to have access to the global class
function vec2add(vector, scalar_or_vector)
  if type(scalar_or_vector) == "table" then
    return {
        vector[1] + scalar_or_vector[1],
        vector[2] + scalar_or_vector[2]
      }
  else
    return {
        vector[1] + scalar_or_vector,
        vector[2] + scalar_or_vector
      }
  end
end

function uninit()
  --world.logInfo( "mutagenRPG.lua : Uninit call" )
	
	status.setStatusProperty( "mutagenRunSkill", self.runSkill )
	status.setStatusProperty( "mutagenRunSkillLevel", self.runSkillLevel )
	status.setStatusProperty( "mutagenWalkSkill", self.walkSkill )
	status.setStatusProperty( "mutagenWalkSkillLevel", self.walkSkillLevel )
	status.setStatusProperty( "mutagenJumpSkill", self.jumpSkill )
	status.setStatusProperty( "mutagenJumpSkillLevel", self.jumpSkillLevel )
	status.setStatusProperty( "mutagenEnduranceSkill", self.enduranceSkill )
	status.setStatusProperty( "mutagenEnduranceSkillLevel", self.enduranceSkillLevel )
	status.setStatusProperty( "mutagenEnergySkill", self.energySkill )
	status.setStatusProperty( "mutagenEnergySkillLevel", self.energySkillLevel )
	status.setStatusProperty( "mutagenBreathSkill", self.breathSkill )
	status.setStatusProperty( "mutagenBreathSkillLevel", self.breathSkillLevel )
	status.setStatusProperty( "mutagenDarkWalkerSkill", self.darkWalkerSkill )
	status.setStatusProperty( "mutagenDarkWalkerSkillLevel", self.darkWalkerSkillLevel )
	status.setStatusProperty( "mutagenLightWalkerSkill", self.lightWalkerSkill )
	status.setStatusProperty( "mutagenLightWalkerSkillLevel", self.lightWalkerSkillLevel )
	status.setStatusProperty( "mutagenTempuratureSkill", self.tempuratureSkill )
	status.setStatusProperty( "mutagenTempuratureSkillLevel", self.tempuratureSkillLevel )
	status.setStatusProperty( "mutagenEvasionSkill", self.evasionSkill )
	status.setStatusProperty( "mutagenEvasionSkillLevel", self.evasionSkillLevel )
	
	--if self.statModifierID ~= nil then
	--	world.logInfo( "mutagenRPG.lua::uninit() : statModifierID = " .. self.statModifierID )
	--	effect.removeStatModifierGroup( self.statModifierID )
	--end
	
	effect.setParentDirectives( "" ) -- might as well
end
