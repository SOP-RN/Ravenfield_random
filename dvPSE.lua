behaviour("dvPSE")

function dvPSE:Start()
    self.dataContainer = self.gameObject.GetComponent(DataContainer)
    self.vehicle = self.gameObject.GetComponent(Vehicle)
    self.animator = self.gameObject.GetComponent(Animator)  -- Get Animator component

    self.ADMCurve = self.dataContainer.GetAnimationCurve("ADM")
    self.DMCurve = self.dataContainer.GetAnimationCurve("DM")
    self.PDCurve = self.dataContainer.GetAnimationCurve("PD")

    self.isHighGTurnActive = false  -- Initialize High G turn bool
    self.transitionSpeed = 4        -- Speed of transition for ease in/out
    self.currentFactor = 0          -- Transition factor (0 to 1)
end

function dvPSE:Update()
    -- Check if High G turn is active
    self.isHighGTurnActive = Input.GetKey(KeyCode.Space) and self.vehicle.playerIsInside
    
    -- Send the High G turn bool to the Animator
    self.animator:SetBool("isHighGTurnActive", self.isHighGTurnActive)
end

function dvPSE:FixedUpdate()
    local drag, angularDrag, perpendicularDrag = 0.2, 2, 2

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

