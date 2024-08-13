behaviour("dvGsim")

function dvGsim:Start()
    self.vehicle = self.gameObject.GetComponent(Vehicle)
    self.gText = self.targets.gText.GetComponent(Text)
    self.aoaText = self.targets.aoaText.GetComponent(Text)
    self.machText = self.targets.machText.GetComponent(Text)
    self.altitudeText = self.targets.altitudeText.GetComponent(Text) -- Added Altitude text target
    self.animator = self.targets.animator.GetComponent(Animator)
    self.gValue = 0
    self.previousVelocity = Vector3.zero
    self.updateInterval = 0.1
    self.timeSinceLastUpdate = 0
    self.speedOfSound = 343 -- Speed of sound in m/s at sea level (can vary with altitude)
end

function dvGsim:FixedUpdate()
    if self.vehicle.hasDriver and self.vehicle.driver == Player.actor then
        local rb = self.vehicle.gameObject.GetComponent(Rigidbody)
        local currentVelocity = rb.velocity
        local speed = currentVelocity.magnitude
        local acceleration = (currentVelocity - self.previousVelocity) / Time.fixedDeltaTime

        -- Calculate Mach number
        local machNumber = speed / self.speedOfSound

        -- Get water level and calculate altitude
        local waterLevel = Water.GetWaterLevel(self.vehicle.transform.position)
        local altitude = Mathf.RoundToInt(self.vehicle.transform.position.y - waterLevel)

        -- Use vehicle's downward direction
        local gravityDirection = Vector3(0, 1, 0)
        local totalAcceleration = acceleration + gravityDirection * 9.8
        local gForce = totalAcceleration.magnitude / 9.8
        local sign = Vector3.Dot(totalAcceleration, self.vehicle.transform.up) >= 0 and 1 or -1
        gForce = gForce * sign
        self.gValue = gForce

        -- Calculate the angle of attack (AoA)
        local forwardDirection = self.vehicle.transform.forward
        local velocityDirection = currentVelocity.normalized
        local aoaRadians = Mathf.Asin(Vector3.Dot(Vector3.Cross(forwardDirection, velocityDirection), self.vehicle.transform.right))
        local aoaDegrees = Mathf.Rad2Deg * aoaRadians

        -- Update animator with AoA and G-value
        self.animator:SetFloat("AoA", aoaDegrees)
        self.animator:SetFloat("Gvalue", self.gValue)

        -- Update text every 0.1 second
        self.timeSinceLastUpdate = self.timeSinceLastUpdate + Time.fixedDeltaTime
        if self.timeSinceLastUpdate >= self.updateInterval then
            self.timeSinceLastUpdate = 0
            local gForceText = string.format("%.1f", self.gValue)
            local aoaText = string.format("%.1f", aoaDegrees)
            local machText = string.format("%.2f", machNumber)
            local altitudeText = string.format("%d", altitude) -- Altitude as integer

            if self.gText ~= nil then
                self.gText.text = gForceText
            end
            if self.aoaText ~= nil then
                self.aoaText.text = aoaText
            end
            if self.machText ~= nil then
                self.machText.text = machText
            end
            if self.altitudeText ~= nil then
                self.altitudeText.text = altitudeText
            end
        end

        -- Store current velocity for next frame
        self.previousVelocity = currentVelocity
    end
end
