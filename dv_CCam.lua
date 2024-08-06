behaviour("dvCCam")

function dvCCam:Start()
    self.attractMode = false
    self.cameraStyle = 1 -- 1: Ravenfield Default, 2: Fly By, 3: Frontal View, 4: Frontal Fixed View

    self.attractModeTimer = 0
    self.attractModetimerDuration = 5

    self.attractModeOffset = Vector3.zero

    self.attractModePosition = Vector3.zero
    self.attractModeRotation = Quaternion.identity

    self.targetAttractPosition = Vector3.zero
    self.targetAttractRotation = Quaternion.identity

    self.attractModeTarget = nil
    self.flyByTimer = 0
    self.flyByPosition = Vector3.zero

    self.frontalOffset = Vector3(0, 2, 10)
    self.fovMultiplier = 1
    self.baseFov = 60

end

function dvCCam:Update()
    if Input.GetKey(KeyCode.LeftShift) then
        if Input.GetKeyDown(KeyCode.C) then
            self:StartAttractMode()
        elseif Input.GetKeyDown(KeyCode.X) then
            self:EndAttractMode()
        end
    end

    if Input.GetKeyDown(KeyCode.O) then
        self:SwitchCameraStyle(-1) -- Previous style
    elseif Input.GetKeyDown(KeyCode.P) then
        self:SwitchCameraStyle(1) -- Next style
    end

    if self.cameraStyle == 3 or self.cameraStyle == 4 then
        self:AdjustFrontalView()
    end
    if Input.GetKey(KeyCode.LeftControl) then
        self:AdjustFovMultiplier()
    end
end

function dvCCam:LateUpdate()
    if self.attractMode then
        if Input.GetKeyDown(KeyCode.L) then
            self:NewAttractModeShot()
        end
        self:UpdateAttractMode()
        self:ApplyCameraStyle()
    end

    if self.attractModeTarget ~= nil then
        local tpCamera = PlayerCamera.tpCamera
        self.distanceToTarget = Vector3.Distance(tpCamera.transform.position, self.attractModeTarget.position)
    end
end

function dvCCam:AdjustFovMultiplier()
    local scroll = Input.GetAxis("Mouse ScrollWheel")
    self.fovMultiplier = self.fovMultiplier + scroll * 0.1
    if self.fovMultiplier < 0.1 then
        self.fovMultiplier = 0.1
    end
    local tpCamera = PlayerCamera.tpCamera
    tpCamera.fieldOfView = self.baseFov * self.fovMultiplier
end

function dvCCam:CalculateDynamicFov()
    local distance = self.distanceToTarget
    local baseDistance = 10
    local baseFov = self.baseFov * self.fovMultiplier

    if distance <= 0 then
        return baseFov  -- Prevent division by zero or negative distances
    end

    return baseFov * (baseDistance / distance)
end

function dvCCam:StartAttractMode()
    self.attractMode = true
    PlayerCamera.ThirdPersonCamera()
    PlayerHud.hudPlayerEnabled = false
    PlayerHud.hudGameModeEnabled = false
    self:NewAttractModeShot()
end

function dvCCam:EndAttractMode()
    self.attractMode = false
    PlayerCamera.FirstPersonCamera()
    PlayerHud.hudPlayerEnabled = true
    PlayerHud.hudGameModeEnabled = true
end

function dvCCam:UpdateAttractMode()
    self.attractModeTimer = self.attractModeTimer + Time.deltaTime
    if self.attractModeTimer > self.attractModetimerDuration then
        self.attractModeTimer = 0
    end
    if self.attractModeTarget ~= nil and self.attractModeTarget.isDead then
        self.attractModeTarget = nil
        self.attractModetimerDuration = Random.Range(7, 15)
    end
    if self.attractModeTarget ~= nil then
        -- Update targetDirection to follow the body movement
        if self.attractModeTarget.velocity.magnitude > 0 then
            self.targetDirection = self.attractModeTarget.transform.forward
        end
        
        self.targetAttractRotation = Quaternion.LookRotation(self.attractModeTarget.position - self.attractModePosition + Vector3(0, 3, 0))
        self.targetAttractPosition = self.attractModeTarget.position + self.attractModeOffset
    end
    self.attractModePosition = Vector3.Lerp(self.attractModePosition, self.targetAttractPosition, Time.deltaTime * 2)
    self.attractModeRotation = Quaternion.Slerp(self.attractModeRotation, self.targetAttractRotation, Time.deltaTime * 2)
end


function dvCCam:ApplyCameraStyle()
    local tpCamera = PlayerCamera.tpCamera

    if self.cameraStyle == 1 then -- Ravenfield Default
        tpCamera.transform.position = self.attractModePosition
        tpCamera.transform.rotation = self.attractModeRotation

    elseif self.cameraStyle == 2 then -- Fly By
        self.flyByTimer = self.flyByTimer + Time.deltaTime
        if self.flyByTimer > self.attractModetimerDuration or self.flyByPosition == Vector3.zero then
            self.flyByTimer = 0
            self:NewFlyByPosition()
        end
        tpCamera.transform.position = self.flyByPosition
        tpCamera.transform.LookAt(self.attractModeTarget.position)

    elseif self.cameraStyle == 3 then -- Frontal View
        if self.attractModeTarget ~= nil then
            local movementDirection = self.attractModeTarget.velocity.magnitude > 0 and self.attractModeTarget.velocity.normalized or self.targetDirection
            local right = Vector3.Cross(Vector3.up, movementDirection).normalized
            local up = Vector3.Cross(movementDirection, right).normalized

            local cameraOffset = right * self.frontalOffset.x + up * self.frontalOffset.y + movementDirection * self.frontalOffset.z
            local cameraPosition = self.attractModeTarget.position + cameraOffset

            tpCamera.transform.position = cameraPosition
            tpCamera.transform.LookAt(self.attractModeTarget.position)
        end

    elseif self.cameraStyle == 4 then -- Frontal Fixed View
        if self.attractModeTarget ~= nil then
            local facingDirection = self.targetDirection  -- Use stored direction when stationary
            local right = Vector3.Cross(Vector3.up, facingDirection).normalized
            local up = Vector3.Cross(facingDirection, right).normalized

            local cameraOffset = right * self.frontalOffset.x + up * self.frontalOffset.y + facingDirection * self.frontalOffset.z
            local cameraPosition = self.attractModeTarget.position + cameraOffset

            tpCamera.transform.position = cameraPosition
            tpCamera.transform.LookAt(self.attractModeTarget.position)
        end
    end
end



function dvCCam:AdjustFrontalView()
    if Input.GetKey(KeyCode.UpArrow) then
        self.frontalOffset.y = self.frontalOffset.y + 0.1
    elseif Input.GetKey(KeyCode.DownArrow) then
        self.frontalOffset.y = self.frontalOffset.y - 0.1
    end
    
    if Input.GetKey(KeyCode.LeftArrow) then
        self.frontalOffset.x = self.frontalOffset.x + 0.1
    elseif Input.GetKey(KeyCode.RightArrow) then
        self.frontalOffset.x = self.frontalOffset.x - 0.1
    end
    
    local scroll = Input.GetAxis("Mouse ScrollWheel")
    self.frontalOffset.z = self.frontalOffset.z + scroll * 1
end

function dvCCam:NewFlyByPosition()
    if self.attractModeTarget ~= nil then
        local movementDirection = self.attractModeTarget.velocity.normalized
        local randomOffset = Vector3(Random.Range(-15, 15), Random.Range(-15, 15), Random.Range(-15, 15))
        
        -- Bias the position towards the movement direction
        local biasedPosition = self.attractModeTarget.position + movementDirection * 200 + randomOffset
        self.flyByPosition = biasedPosition
        self.attractModetimerDuration = Random.Range(5, 8)
    end
end

function dvCCam:NewAttractModeShot()
    local actors = ActorManager.GetAliveActorsOnTeam(self:GetRandomTeam())
    
    if #actors > 0 then
        local newTarget = nil
        
        while newTarget == nil do
            local num = math.floor(Random.Range(1, #actors))
            for i = #actors, 1, -1 do
                local index = (num + i - 1) % #actors + 1
                if actors[index].isBot and actors[index] ~= self.attractModeTarget then
                    newTarget = actors[index]
                    break
                end
            end
        end

        self.attractModeTarget = newTarget
        self.attractModeOffset = Vector3(Random.Range(-2, 2), 5, -8)
        self.attractModetimerDuration = Random.Range(7, 15)
        self.attractModeRotation = Quaternion.LookRotation(self.attractModeTarget.facingDirection)
        self.attractModePosition = Matrix4x4.TRS(self.attractModeTarget.centerPosition, self.attractModeRotation, Vector3.one).MultiplyPoint(self.attractModeOffset)

        print("New target acquired: " .. self.attractModeTarget.name)
    end
end

function dvCCam:SwitchCameraStyle(direction)
    self.cameraStyle = self.cameraStyle + direction
    if self.cameraStyle > 4 then
        self.cameraStyle = 1
    elseif self.cameraStyle < 1 then
        self.cameraStyle = 4
    end
    
    local styleNames = { "Ravenfield Default", "Fly By", "Frontal View", "Frontal Fixed View" }
    print("Camera style: " .. styleNames[self.cameraStyle])
    if self.cameraStyle == 2 then
        self:NewFlyByPosition() -- Generate a new position when switching to Fly By mode
    end
end

function dvCCam:GetRandomTeam()
    local num = math.random()
    if num > 0.5 then
        return Team.Blue
    end
    return Team.Red
end 
