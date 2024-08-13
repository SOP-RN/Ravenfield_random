behaviour("dvPSE")

function dvPSE:Start()
    self.dataContainer = self.gameObject.GetComponent(DataContainer)
    self.vehicle = self.gameObject.GetComponent(Vehicle)
    self.animator = self.gameObject.GetComponent(Animator)  -- Get Animator component

    -- Retrieve Animation Curves
    self.ADMCurve = self.dataContainer.GetAnimationCurve("ADM")
    self.DMCurve = self.dataContainer.GetAnimationCurve("DM")
    self.PDCurve = self.dataContainer.GetAnimationCurve("PD")
    
    -- Find Critical Parts
    self.engine1 = self.targets.engine1      -- First engine
    self.engine2 = self.targets.engine2      -- Second engine
    self.wing1 = self.targets.wing1          -- First wing
    self.wing2 = self.targets.wing2          -- Second wing
    self.hStab1 = self.targets.hStab1        -- First horizontal stabilizer
    self.hStab2 = self.targets.hStab2        -- Second horizontal stabilizer
    self.vStab1 = self.targets.vStab1        -- First vertical stabilizer
    self.vStab2 = self.targets.vStab2        -- Second vertical stabilizer

    -- Initialize Destruction Values
    self.rollDestruction = 0
    self.pitchDestruction = 0
    self.yawDestruction = 0
    self.engineDestruction = 0
    
    -- Initialize High G Mode Status
    self.isHighGTurnActive = false
    self.transitionSpeed = 4
    self.currentFactor = 0
end

function dvPSE:Update()
    -- Update Destruction Values
    self:UpdateDestructionValues()

    -- Send the destruction values to the animator
    self.animator:SetFloat("RollDestruction", self.rollDestruction)
    self.animator:SetFloat("PitchDestruction", self.pitchDestruction)
    self.animator:SetFloat("YawDestruction", self.yawDestruction)
    self.animator:SetFloat("EngineDestruction", self.engineDestruction)

    -- Handle High G Mode based on wing status
    if not self.wing1.activeSelf or not self.wing2.activeSelf or not self.hStab1.activeSelf or not self.hStab2.activeSelf then
        self.isHighGTurnActive = false
    end
end

function dvPSE:FixedUpdate()
    local drag, angularDrag, perpendicularDrag = 0.2, 2, 2
    self:CheckAndResetCriticalParts()

    -- Smooth transition (ease in/out) based on High G turn state
    if self.isHighGTurnActive then
        self.currentFactor = math.min(self.currentFactor + Time.deltaTime * self.transitionSpeed, 1)
    else
        self.currentFactor = math.max(self.currentFactor - Time.deltaTime * self.transitionSpeed, 0)
    end

    if self.currentFactor > 0 then
        local velMagnitude = self.vehicle.rigidbody.velocity.magnitude
        local curveDrag, curveAngularDrag, curvePerpendicularDrag = self:GetCurve(velMagnitude)

        -- Interpolate between default and curve-based values
        drag = Mathf.Lerp(0.2, curveDrag, self.currentFactor)
        angularDrag = Mathf.Lerp(2, curveAngularDrag, self.currentFactor)
        perpendicularDrag = Mathf.Lerp(2, curvePerpendicularDrag, self.currentFactor)
    end

    self:SetVehicleDrag(drag, angularDrag, perpendicularDrag)
    
    -- Apply angular velocity adjustment for engine imbalance
    self:ApplyEngineImbalance()
end

function dvPSE:CheckAndResetCriticalParts()
    if self.vehicle.health > 1600 then
        -- Activate all critical parts
        self.engine1:SetActive(true)
        self.engine2:SetActive(true)
        self.wing1:SetActive(true)
        self.wing2:SetActive(true)
        self.hStab1:SetActive(true)
        self.hStab2:SetActive(true)
        self.vStab1:SetActive(true)
        self.vStab2:SetActive(true)

        -- Reset Destruction Values
        self.rollDestruction = 0
        self.pitchDestruction = 0
        self.engineDestruction = 0
        self.vStabDestruction = 0
    end
end


function dvPSE:GetCurve(velMagnitude)
    local DM = self.DMCurve.Evaluate(velMagnitude)
    local ADM = self.ADMCurve.Evaluate(velMagnitude)
    local PD = self.PDCurve.Evaluate(velMagnitude)
    return 0.2 * DM, 2 * ADM, PD
end

function dvPSE:SetVehicleDrag(drag, angularDrag, perpendicularDrag)
    self.vehicle.rigidbody.drag = drag
    self.vehicle.rigidbody.angularDrag = angularDrag
    self.vehicle.perpendicularDrag = perpendicularDrag
end

function dvPSE:UpdateDestructionValues()
    -- Update Roll Destruction
    local wingCount = (self.wing1.activeSelf and 1 or 0) + (self.wing2.activeSelf and 1 or 0)
    self.rollDestruction = 1 - (wingCount / 2)
    
    -- Update Pitch Destruction
    local hStabCount = (self.hStab1.activeSelf and 1 or 0) + (self.hStab2.activeSelf and 1 or 0)
    self.pitchDestruction = 1 - (hStabCount / 2)

    -- Update Yaw Destruction (Vertical Stabilizers)
    local vStabCount = (self.vStab1.activeSelf and 1 or 0) + (self.vStab2.activeSelf and 1 or 0)
    self.yawDestruction = 1 - (vStabCount / 2)
    
    -- Update Engine Destruction
    local engineCount = (self.engine1.activeSelf and 1 or 0) + (self.engine2.activeSelf and 1 or 0)
    self.engineDestruction = 1 - (engineCount / 2)
end

function dvPSE:ApplyEngineImbalance()
    -- Check if the vehicle has a driver
    if self.vehicle.hasDriver then
        local velocityMagnitude = self.vehicle.rigidbody.velocity.magnitude

        -- Check if the driver is a bot
        if self.vehicle.driver.isBot then
            -- Use velocity-based angular velocity adjustment for bots
            local angularVelocityAdjustment = math.min(velocityMagnitude * 0.01, 0.1)

            if not self.engine1.activeSelf and self.engine2.activeSelf then
                -- Only engine 2 is active
                local localAngularVelocity = Vector3(0, -self.engineDestruction * angularVelocityAdjustment, 0)
                self.vehicle.rigidbody.angularVelocity = self.vehicle.transform:TransformDirection(localAngularVelocity) * 0.1 + self.vehicle.rigidbody.angularVelocity
            elseif not self.engine2.activeSelf and self.engine1.activeSelf then
                -- Only engine 1 is active
                local localAngularVelocity = Vector3(0, self.engineDestruction * angularVelocityAdjustment, 0)
                self.vehicle.rigidbody.angularVelocity = self.vehicle.transform:TransformDirection(localAngularVelocity) * 0.1 + self.vehicle.rigidbody.angularVelocity
            end
        else
            -- Use throttle and velocity-based angular velocity adjustment for human players
            local throttleInput = Input.GetKeyBindAxis(KeyBinds.PlaneThrottle)

            if throttleInput > 0 then
                -- Calculate velocity-based multiplier (0.1 at 300m/s, linearly decreasing to 1 at 0m/s)
                local velocityMultiplier = Mathf.Clamp(1 - (velocityMagnitude / 600), 1,5 , 9)

                if not self.engine1.activeSelf and self.engine2.activeSelf then
                    -- Only engine 2 is active
                    local localAngularVelocity = Vector3(0, -self.engineDestruction * throttleInput * velocityMultiplier, 0)
                    self.vehicle.rigidbody.angularVelocity = self.vehicle.transform:TransformDirection(localAngularVelocity) * 0.01 + self.vehicle.rigidbody.angularVelocity
                elseif not self.engine2.activeSelf and self.engine1.activeSelf then
                    -- Only engine 1 is active
                    local localAngularVelocity = Vector3(0, self.engineDestruction * throttleInput * velocityMultiplier, 0)
                    self.vehicle.rigidbody.angularVelocity = self.vehicle.transform:TransformDirection(localAngularVelocity) * 0.01 + self.vehicle.rigidbody.angularVelocity
                end
            end
        end
    end
end

