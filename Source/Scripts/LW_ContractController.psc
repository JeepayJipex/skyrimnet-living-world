Scriptname LW_ContractController extends Quest

; The quest instance is the sole authority for this save's contract.
Actor Property IssuerRef Auto
MiscObject Property Firewood Auto
Message Property OfferMessage Auto

Int _state = 0 ; 0 Available, 1 Offered, 2 Accepted, 3 Rejected
Int _attempt = 0
Int _activeAttempt = 0
Bool _initialized = False
MiscObject _savedItem
Int _savedQuantity = 0
Int _savedReward = 0

Event OnInit()
    EnsureInitialized()
EndEvent

Bool Function EnsureInitialized()
    If _initialized
        Return True
    EndIf
    If IssuerRef == None || Firewood == None || OfferMessage == None
        Debug.Trace("LW_ContractController: required quest properties are missing")
        Return False
    EndIf
    _savedItem = Firewood
    _savedQuantity = 10
    _savedReward = 50
    _state = 0
    _initialized = True
    Return True
EndFunction

; Called by the Player reference alias on its first initialization and each load.
Function Bootstrap(Bool abAfterLoad)
    If !EnsureInitialized()
        Return
    EndIf
    If abAfterLoad && _state == 1
        ; A message cannot safely be resumed as consent from a previous session.
        _activeAttempt += 1
        _state = 0
        Debug.Trace("LW_ContractController: interrupted offer returned to Available")
    EndIf
    Int offerRegistration = SkyrimNetApi.RegisterDecorator("lw_can_offer_contract", "LW_ContractDecorators", "CanOffer")
    Int contextRegistration = SkyrimNetApi.RegisterDecorator("lw_contract_context", "LW_ContractDecorators", "ContractContext")
    If offerRegistration != 0 || contextRegistration != 0
        Debug.Trace("LW_ContractController: decorator registration returned " + offerRegistration + ", " + contextRegistration)
    EndIf
EndFunction

Bool Function CanOffer(Actor akSpeaker)
    If !_initialized || !IsRunning() || _state != 0
        Return False
    EndIf
    If akSpeaker == None || akSpeaker != IssuerRef || _savedItem != Firewood
        Return False
    EndIf
    Actor playerRef = Game.GetPlayer()
    If playerRef == None || akSpeaker.IsDead() || akSpeaker.IsInCombat()
        Return False
    EndIf
    If akSpeaker.GetDistance(playerRef) > 350.0
        Return False
    EndIf
    Return True
EndFunction

; The only function exposed to the SkyrimNet action. All terms are saved here.
Function RequestOffer(Actor akSpeaker)
    If !CanOffer(akSpeaker) || OfferMessage == None
        Return
    EndIf

    ; No latent operation occurs between this transition and the attempt token.
    _state = 1
    _attempt += 1
    _activeAttempt = _attempt
    Int thisAttempt = _activeAttempt
    Int choice = OfferMessage.Show()

    If _state != 1 || _activeAttempt != thisAttempt
        Debug.Trace("LW_ContractController: stale offer response ignored")
        Return
    EndIf
    If choice == 0
        _state = 2
    ElseIf choice == 1
        _state = 3
    Else
        ; -1 or any unexpected result is no decision and can be retried.
        _activeAttempt += 1
        _state = 0
        Debug.Trace("LW_ContractController: confirmation failed with result " + choice)
    EndIf
EndFunction

String Function GetContractContext(Actor akActor)
    If !_initialized || akActor == None || akActor != IssuerRef
        Return ""
    EndIf
    If _savedItem != Firewood || _savedQuantity != 10 || _savedReward != 50
        Return "Living World contract terms are unavailable. Do not claim an offer or outcome."
    EndIf
    If _state == 0
        Return "Sigurd may offer the player a contract for 10 Firewood and 50 gold. No contract has been accepted."
    ElseIf _state == 1
        Return "Sigurd's offer for 10 Firewood and 50 gold awaits the player's native confirmation. Do not claim acceptance."
    ElseIf _state == 2
        Return "The player accepted Sigurd's contract for 10 Firewood and 50 gold. Delivery and payment have not occurred."
    ElseIf _state == 3
        Return "The player rejected Sigurd's contract for 10 Firewood and 50 gold. No delivery or payment occurred."
    EndIf
    Return "Living World contract state is unavailable. Do not claim an offer or outcome."
EndFunction
